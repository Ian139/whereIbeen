import React, { useState, useRef } from "react";
import {
	View,
	StyleSheet,
	Text,
	Platform,
	TouchableOpacity,
	SafeAreaView,
} from "react-native";
import MapView, { Polygon, PROVIDER_DEFAULT, Region } from "react-native-maps";

interface Coordinate {
	latitude: number;
	longitude: number;
}

// Fixed brush size of approximately 0.25 miles (about 0.004 degrees at equator)
const BRUSH_RADIUS_DEGREES = 0.004;
const EARTH_RADIUS_KM = 6371; // Earth's radius in kilometers
const EARTH_SURFACE_AREA = 510100000; // Earth's surface area in km²

// PolygonUtils: Helper functions for working with polygons
const PolygonUtils = {
	// Create a circle polygon at the given coordinate
	createCircle: (
		center: Coordinate,
		radius: number = BRUSH_RADIUS_DEGREES
	): Coordinate[] => {
		const points: Coordinate[] = [];
		const numPoints = 16; // Number of points to approximate circle

		for (let i = 0; i < numPoints; i++) {
			const angle = (i / numPoints) * 2 * Math.PI;
			points.push({
				latitude: center.latitude + radius * Math.cos(angle),
				longitude: center.longitude + radius * Math.sin(angle),
			});
		}

		// Close the polygon
		points.push(points[0]);
		return points;
	},

	// Calculate area of a polygon in km²
	calculateArea: (coordinates: Coordinate[]): number => {
		if (coordinates.length < 3) return 0;

		// Simple approximation using the shoelace formula and converting to km²
		let area = 0;
		for (let i = 0; i < coordinates.length - 1; i++) {
			const j = (i + 1) % (coordinates.length - 1);
			area += coordinates[i].longitude * coordinates[j].latitude;
			area -= coordinates[j].longitude * coordinates[i].latitude;
		}

		area = Math.abs(area) / 2;

		// Convert to approximate km²
		// Each degree is roughly 111.32 km at the equator
		// Adjust for latitude with cos(lat)
		const centerLat =
			coordinates.reduce((sum, coord) => sum + coord.latitude, 0) /
			coordinates.length;
		const correction = Math.cos((centerLat * Math.PI) / 180);
		return area * 111.32 * 111.32 * correction;
	},

	// Union of two polygons (simplified version that combines all points)
	unionPolygons: (
		polygon1: Coordinate[],
		polygon2: Coordinate[]
	): Coordinate[] => {
		// This is a simple approach that won't handle complex cases properly,
		// but works for our eraser tool where we just need a reasonable approximation
		const result = [...polygon1, ...polygon2];
		return PolygonUtils.convexHull(result);
	},

	// Compute convex hull of points (Graham scan algorithm)
	convexHull: (points: Coordinate[]): Coordinate[] => {
		if (points.length <= 3) return points;

		// Find the point with lowest latitude (or westmost if tied)
		let bottomPoint = points[0];
		for (let i = 1; i < points.length; i++) {
			if (
				points[i].latitude < bottomPoint.latitude ||
				(points[i].latitude === bottomPoint.latitude &&
					points[i].longitude < bottomPoint.longitude)
			) {
				bottomPoint = points[i];
			}
		}

		// Sort points by polar angle with respect to bottom point
		const sortedPoints = points
			.filter((p) => p !== bottomPoint)
			.sort((a, b) => {
				const angleA = Math.atan2(
					a.latitude - bottomPoint.latitude,
					a.longitude - bottomPoint.longitude
				);
				const angleB = Math.atan2(
					b.latitude - bottomPoint.latitude,
					b.longitude - bottomPoint.longitude
				);
				return angleA - angleB;
			});

		// Build convex hull
		const hull = [bottomPoint];
		for (const point of sortedPoints) {
			while (hull.length >= 2) {
				const top = hull[hull.length - 1];
				const nextToTop = hull[hull.length - 2];

				const cross =
					(top.longitude - nextToTop.longitude) *
						(point.latitude - nextToTop.latitude) -
					(top.latitude - nextToTop.latitude) *
						(point.longitude - nextToTop.longitude);

				if (cross <= 0) hull.pop();
				else break;
			}
			hull.push(point);
		}

		// Ensure the polygon is closed
		if (hull.length > 2) {
			hull.push(hull[0]);
		}

		return hull;
	},
};

const DefaultMapComponent: React.FC = () => {
	const [erasedArea, setErasedArea] = useState<Coordinate[]>([]);
	const [currentRegion, setCurrentRegion] = useState<Region>({
		latitude: 34.0522,
		longitude: -118.2437,
		latitudeDelta: 0.0922,
		longitudeDelta: 0.0421,
	});
	const [percentExplored, setPercentExplored] = useState(0);
	const [showInstructions, setShowInstructions] = useState(true);
	const mapRef = useRef<MapView>(null);

	// Create the fog polygon with a hole for the erased area
	const createFogPolygon = () => {
		// Create a polygon that covers the visible map area plus some padding
		const visibleRegion = currentRegion;
		const padding =
			Math.max(visibleRegion.latitudeDelta, visibleRegion.longitudeDelta) * 2;

		return {
			coordinates: [
				{
					latitude: visibleRegion.latitude - padding,
					longitude: visibleRegion.longitude - padding,
				},
				{
					latitude: visibleRegion.latitude - padding,
					longitude: visibleRegion.longitude + padding,
				},
				{
					latitude: visibleRegion.latitude + padding,
					longitude: visibleRegion.longitude + padding,
				},
				{
					latitude: visibleRegion.latitude + padding,
					longitude: visibleRegion.longitude - padding,
				},
			],
			holes: erasedArea.length >= 3 ? [erasedArea] : [],
		};
	};

	// Calculate the explored percentage based on the visible map area
	const updateExploredPercentage = (region: Region) => {
		// Calculate approximate visible area in km²
		const latDegrees = region.latitudeDelta;
		const lngDegrees = region.longitudeDelta;
		const centerLat = region.latitude;

		// Approximate area calculation
		const degreesToKm = 111.32; // Approximate km per degree at equator
		const correction = Math.cos((centerLat * Math.PI) / 180);
		const visibleAreaKm =
			latDegrees * lngDegrees * degreesToKm * degreesToKm * correction;

		// Calculate as percentage of Earth's surface (simplified)
		const newPercentage = (visibleAreaKm / EARTH_SURFACE_AREA) * 100;
		setPercentExplored(Math.min(newPercentage, 100));
	};

	// Reset the map and clear all erased areas
	const resetMap = () => {
		setErasedArea([]);
		setPercentExplored(0);

		// Reset to the initial region
		mapRef.current?.animateToRegion(
			{
				latitude: 34.0522,
				longitude: -118.2437,
				latitudeDelta: 0.0922,
				longitudeDelta: 0.0421,
			},
			500
		);
	};

	// Handle region change
	const handleRegionChangeComplete = (region: Region) => {
		setCurrentRegion(region);
		updateExploredPercentage(region);
	};

	return (
		<View style={styles.container}>
			<MapView
				ref={mapRef}
				style={styles.map}
				provider={PROVIDER_DEFAULT}
				initialRegion={currentRegion}
				onRegionChangeComplete={handleRegionChangeComplete}
				rotateEnabled={true}
				scrollEnabled={true}
				zoomEnabled={true}
				minZoomLevel={3}
				maxZoomLevel={18}
				pitchEnabled={false}
			>
				{/* Fog overlay - uses native map overlay component */}
				<Polygon
					{...createFogPolygon()}
					fillColor="rgba(0, 100, 255, 0.3)"
					strokeColor="rgba(0, 100, 255, 0.5)"
					strokeWidth={1}
					tappable={false}
				/>
			</MapView>

			<SafeAreaView style={styles.overlayContainer}>
				{showInstructions && (
					<TouchableOpacity
						style={styles.instructionsContainer}
						onPress={() => setShowInstructions(false)}
						activeOpacity={0.8}
					>
						<Text style={styles.instructionsText}>
							• Two fingers: Move & zoom map
						</Text>
					</TouchableOpacity>
				)}

				<View style={styles.percentContainer}>
					<Text style={styles.percentText}>
						{`${percentExplored.toFixed(4)}%`}
					</Text>
				</View>

				<View style={styles.resetContainer}>
					<Text style={styles.resetButton} onPress={resetMap}>
						Reset Map
					</Text>
				</View>
			</SafeAreaView>
		</View>
	);
};

const styles = StyleSheet.create({
	container: {
		flex: 1,
		width: "100%",
	},
	map: {
		flex: 1,
		width: "100%",
		height: "100%",
	},
	overlayContainer: {
		position: "absolute",
		top: 0,
		left: 0,
		right: 0,
		bottom: 0,
	},
	instructionsContainer: {
		backgroundColor: "rgba(0, 0, 0, 0.7)",
		paddingVertical: 8,
		paddingHorizontal: 16,
		borderRadius: 20,
		alignSelf: "center",
		marginTop: Platform.OS === "ios" ? 10 : 40,
	},
	instructionsText: {
		color: "white",
		fontSize: 16,
		textAlign: "center",
	},
	percentContainer: {
		position: "absolute",
		bottom: 40,
		left: 20,
		backgroundColor: "rgba(0, 0, 0, 0.7)",
		paddingVertical: 6,
		paddingHorizontal: 10,
		borderRadius: 8,
	},
	percentText: {
		color: "white",
		fontSize: 16,
		fontWeight: "bold",
	},
	resetContainer: {
		position: "absolute",
		bottom: 40,
		right: 20,
		backgroundColor: "rgba(0, 0, 0, 0.7)",
		padding: 10,
		borderRadius: 10,
	},
	resetButton: {
		color: "white",
		fontSize: 16,
	},
});

export default DefaultMapComponent;
