import React, { useState, useRef, useEffect, useMemo } from "react";
import {
	View,
	StyleSheet,
	Text,
	Platform,
	TouchableOpacity,
	SafeAreaView,
	Switch,
} from "react-native";
import MapView, {
	Polygon,
	PROVIDER_DEFAULT,
	Region,
	Marker,
} from "react-native-maps";
import useLocation from "../hooks/useLocation";
import { Ionicons } from "@expo/vector-icons";

interface Coordinate {
	latitude: number;
	longitude: number;
}

// 0.25 miles is approximately 0.004 degrees at equator
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
	// Automatically enable tracking and disable mocking
	const [isTracking, setIsTracking] = useState(true);
	const [isMocking, setIsMocking] = useState(false);
	const [location, locationError] = useLocation(isTracking, isMocking);
	const [lastErasedLocation, setLastErasedLocation] =
		useState<Coordinate | null>(null);
	const [exploredGridCells, setExploredGridCells] = useState<Set<string>>(
		new Set()
	);
	const mapRef = useRef<MapView>(null);

	// Grid cell size in degrees (approximately 0.25 miles at equator)
	const GRID_CELL_SIZE = BRUSH_RADIUS_DEGREES;

	// Threshold for when to switch to grid view
	const GRID_VIEW_THRESHOLD = 0.15;

	// Threshold for when to show completely green map
	const FULL_GREEN_THRESHOLD = 0.01;

	// Function to calculate distance in meters between two coordinates
	const calculateDistance = (
		coord1: Coordinate,
		coord2: Coordinate
	): number => {
		if (!coord1 || !coord2) return Infinity;

		const lat1 = coord1.latitude;
		const lon1 = coord1.longitude;
		const lat2 = coord2.latitude;
		const lon2 = coord2.longitude;

		const R = 6371e3; // Earth's radius in meters
		const φ1 = (lat1 * Math.PI) / 180;
		const φ2 = (lat2 * Math.PI) / 180;
		const Δφ = ((lat2 - lat1) * Math.PI) / 180;
		const Δλ = ((lon2 - lon1) * Math.PI) / 180;

		const a =
			Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
			Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
		const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
		const distance = R * c;

		return distance;
	};

	// Convert coordinates to grid cell key
	const getGridCellKey = (lat: number, lng: number): string => {
		const latCell = Math.floor(lat / GRID_CELL_SIZE);
		const lngCell = Math.floor(lng / GRID_CELL_SIZE);
		return `${latCell},${lngCell}`;
	};

	// Get grid cell coordinates from key
	const getGridCellFromKey = (key: string): { lat: number; lng: number } => {
		const [latCell, lngCell] = key.split(",").map(Number);
		return {
			lat: latCell * GRID_CELL_SIZE,
			lng: lngCell * GRID_CELL_SIZE,
		};
	};

	// Mark grid cells as explored within radius
	const markExploredGridCells = (
		lat: number,
		lng: number,
		radiusMeters: number
	) => {
		const radiusDegrees = radiusMeters / 111000; // Convert meters to approximate degrees
		const cellsToAdd = new Set([...exploredGridCells]);
		const cellsInRadius = Math.ceil(radiusDegrees / GRID_CELL_SIZE);

		for (let i = -cellsInRadius; i <= cellsInRadius; i++) {
			for (let j = -cellsInRadius; j <= cellsInRadius; j++) {
				const cellLat = Math.floor(lat / GRID_CELL_SIZE) + i;
				const cellLng = Math.floor(lng / GRID_CELL_SIZE) + j;

				// Cell center coordinates
				const centerLat = cellLat * GRID_CELL_SIZE + GRID_CELL_SIZE / 2;
				const centerLng = cellLng * GRID_CELL_SIZE + GRID_CELL_SIZE / 2;

				// Check if the cell center is within our radius
				const dist = Math.sqrt(
					Math.pow(lat - centerLat, 2) + Math.pow(lng - centerLng, 2)
				);

				if (dist <= radiusDegrees) {
					cellsToAdd.add(`${cellLat},${cellLng}`);
				}
			}
		}

		setExploredGridCells(cellsToAdd);
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
	const resetMapView = () => {
		// Don't clear explored areas, just reset the map view to current location
		if (location && location.coords) {
			mapRef.current?.animateToRegion(
				{
					latitude: location.coords.latitude,
					longitude: location.coords.longitude,
					latitudeDelta: 0.0922,
					longitudeDelta: 0.0421,
				},
				500
			);
		} else {
			mapRef.current?.animateToRegion(
				{
					latitude: 34.0522,
					longitude: -118.2437,
					latitudeDelta: 0.0922,
					longitudeDelta: 0.0421,
				},
				500
			);
		}
	};

	// Reset the erased area (keep as a separate function for potential future use)
	const resetErasedArea = () => {
		setErasedArea([]);
		setPercentExplored(0);
		setLastErasedLocation(null);
	};

	// Handle region change
	const handleRegionChangeComplete = (region: Region) => {
		// No longer enforcing zoom limits
		setCurrentRegion(region);
		updateExploredPercentage(region);
	};

	// Clear area around the current location
	const clearAreaAroundLocation = (userLocation: Coordinate) => {
		// Create a circle polygon around the user's location
		const circlePolygon = PolygonUtils.createCircle(
			userLocation,
			BRUSH_RADIUS_DEGREES
		);

		// If we already have an erased area, union it with the new circle
		if (erasedArea.length > 0) {
			const newErasedArea = PolygonUtils.unionPolygons(
				erasedArea,
				circlePolygon
			);
			setErasedArea(newErasedArea);
		} else {
			setErasedArea(circlePolygon);
		}

		// Also update the grid cells
		markExploredGridCells(
			userLocation.latitude,
			userLocation.longitude,
			0.25 * 1609 // 0.25 miles in meters
		);

		// Update last erased location
		setLastErasedLocation(userLocation);

		// Center map on the user location if tracking is enabled
		if (isTracking) {
			mapRef.current?.animateToRegion(
				{
					...currentRegion,
					latitude: userLocation.latitude,
					longitude: userLocation.longitude,
				},
				500
			);
		}
	};

	// Effect to clear area when user location changes
	useEffect(() => {
		if (!location || !location.coords) return;

		const userLocation = {
			latitude: location.coords.latitude,
			longitude: location.coords.longitude,
		};

		// If this is the first location update or if we've moved significantly
		// (more than half the brush radius) from the last erased location
		const MIN_DISTANCE_TO_ERASE = 0.4 * BRUSH_RADIUS_DEGREES * 111320; // approx 40% of brush radius in meters

		if (
			!lastErasedLocation ||
			calculateDistance(userLocation, lastErasedLocation) >
				MIN_DISTANCE_TO_ERASE
		) {
			clearAreaAroundLocation(userLocation);
		}
	}, [location]);

	// Determine which grid cells should be visible in the current viewport
	const visibleGridCells = useMemo(() => {
		// Only calculate grid cells if we're zoomed in enough
		if (currentRegion.latitudeDelta > GRID_VIEW_THRESHOLD) {
			return [];
		}

		// Calculate viewport bounds with padding
		const bounds = {
			north:
				currentRegion.latitude +
				currentRegion.latitudeDelta / 2 +
				GRID_CELL_SIZE,
			south:
				currentRegion.latitude -
				currentRegion.latitudeDelta / 2 -
				GRID_CELL_SIZE,
			east:
				currentRegion.longitude +
				currentRegion.longitudeDelta / 2 +
				GRID_CELL_SIZE,
			west:
				currentRegion.longitude -
				currentRegion.longitudeDelta / 2 -
				GRID_CELL_SIZE,
		};

		// Calculate grid cell ranges
		const minLatCell = Math.floor(bounds.south / GRID_CELL_SIZE);
		const maxLatCell = Math.floor(bounds.north / GRID_CELL_SIZE);
		const minLngCell = Math.floor(bounds.west / GRID_CELL_SIZE);
		const maxLngCell = Math.floor(bounds.east / GRID_CELL_SIZE);

		const cells: Array<{ key: string; coordinates: Coordinate[] }> = [];

		// Generate visible grid cells
		for (let latCell = minLatCell; latCell <= maxLatCell; latCell++) {
			for (let lngCell = minLngCell; lngCell <= maxLngCell; lngCell++) {
				const cellKey = `${latCell},${lngCell}`;

				// Only create polygon for explored cells
				if (exploredGridCells.has(cellKey)) {
					const cellLat = latCell * GRID_CELL_SIZE;
					const cellLng = lngCell * GRID_CELL_SIZE;

					cells.push({
						key: cellKey,
						coordinates: [
							{ latitude: cellLat, longitude: cellLng },
							{ latitude: cellLat, longitude: cellLng + GRID_CELL_SIZE },
							{
								latitude: cellLat + GRID_CELL_SIZE,
								longitude: cellLng + GRID_CELL_SIZE,
							},
							{ latitude: cellLat + GRID_CELL_SIZE, longitude: cellLng },
							{ latitude: cellLat, longitude: cellLng }, // Close the polygon
						],
					});
				}
			}
		}

		return cells;
	}, [currentRegion, exploredGridCells]);

	// Create the fog polygon with a hole for the erased area (only for higher zoom levels)
	const createFogPolygon = () => {
		const visibleRegion = currentRegion;
		// Use a smaller padding multiplier for better performance
		const padding =
			Math.max(visibleRegion.latitudeDelta, visibleRegion.longitudeDelta) * 0.5;

		// Calculate bounds with minimal padding
		const bounds = {
			north: visibleRegion.latitude + visibleRegion.latitudeDelta / 2 + padding,
			south: visibleRegion.latitude - visibleRegion.latitudeDelta / 2 - padding,
			east:
				visibleRegion.longitude + visibleRegion.longitudeDelta / 2 + padding,
			west:
				visibleRegion.longitude - visibleRegion.longitudeDelta / 2 - padding,
		};

		return {
			coordinates: [
				{ latitude: bounds.south, longitude: bounds.west },
				{ latitude: bounds.south, longitude: bounds.east },
				{ latitude: bounds.north, longitude: bounds.east },
				{ latitude: bounds.north, longitude: bounds.west },
				{ latitude: bounds.south, longitude: bounds.west }, // Close the polygon
			],
			holes: erasedArea.length >= 3 ? [erasedArea] : [],
		};
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
				pitchEnabled={false}
				moveOnMarkerPress={false}
				showsUserLocation={true}
				showsMyLocationButton={false}
				showsCompass={false}
				toolbarEnabled={false}
				loadingEnabled={true}
				zoomTapEnabled={true}
				zoomControlEnabled={true}
				followsUserLocation={true}
				maxZoomLevel={22} // Set a very high max zoom level
				minZoomLevel={0} // Allow full zoom out
			>
				{currentRegion.latitudeDelta <= FULL_GREEN_THRESHOLD ? (
					// When zoomed in really close, show the entire map as green
					<Polygon
						coordinates={[
							{
								latitude: currentRegion.latitude - currentRegion.latitudeDelta,
								longitude:
									currentRegion.longitude - currentRegion.longitudeDelta,
							},
							{
								latitude: currentRegion.latitude - currentRegion.latitudeDelta,
								longitude:
									currentRegion.longitude + currentRegion.longitudeDelta,
							},
							{
								latitude: currentRegion.latitude + currentRegion.latitudeDelta,
								longitude:
									currentRegion.longitude + currentRegion.longitudeDelta,
							},
							{
								latitude: currentRegion.latitude + currentRegion.latitudeDelta,
								longitude:
									currentRegion.longitude - currentRegion.longitudeDelta,
							},
							{
								latitude: currentRegion.latitude - currentRegion.latitudeDelta,
								longitude:
									currentRegion.longitude - currentRegion.longitudeDelta,
							},
						]}
						fillColor="rgba(76, 175, 80, 0.3)"
						strokeColor="rgba(76, 175, 80, 0.5)"
						strokeWidth={1}
						tappable={false}
					/>
				) : currentRegion.latitudeDelta <= GRID_VIEW_THRESHOLD ? (
					// When zoomed in enough, show the grid-based view
					visibleGridCells.map((cell) => (
						<Polygon
							key={cell.key}
							coordinates={cell.coordinates}
							fillColor="rgba(76, 175, 80, 0.3)"
							strokeColor="rgba(76, 175, 80, 0.5)"
							strokeWidth={1}
							tappable={false}
						/>
					))
				) : (
					// When zoomed out, show the fog of war with erased areas
					<Polygon
						{...createFogPolygon()}
						fillColor="rgba(76, 175, 80, 0.3)"
						strokeColor="rgba(76, 175, 80, 0.5)"
						strokeWidth={1}
						tappable={false}
						geodesic={true}
						onPress={() => {}}
						zIndex={1}
					/>
				)}

				{location && location.coords && (
					<Marker
						coordinate={{
							latitude: location.coords.latitude,
							longitude: location.coords.longitude,
						}}
						title="Current Location"
						pinColor="blue"
					/>
				)}
			</MapView>

			<SafeAreaView style={styles.overlayContainer}>
				{/* Top bar with percentage and compass */}
				<View style={styles.topBar}>
					<View style={styles.percentContainer}>
						<Text style={styles.percentText}>
							{`${percentExplored.toFixed(4)}%`}
						</Text>
					</View>

					<TouchableOpacity
						style={styles.compassContainer}
						onPress={resetMapView}
					>
						<Ionicons name="compass" size={24} color="white" />
					</TouchableOpacity>
				</View>

				{/* Bottom tabs */}
				<View style={styles.tabBar}>
					<TouchableOpacity style={styles.tabItem}>
						<Ionicons name="map" size={24} color="white" />
						<Text style={styles.tabText}>Map</Text>
					</TouchableOpacity>
					<TouchableOpacity style={styles.tabItem}>
						<Ionicons name="stats-chart" size={24} color="white" />
						<Text style={styles.tabText}>Stats</Text>
					</TouchableOpacity>
					<TouchableOpacity style={styles.tabItem}>
						<Ionicons name="settings" size={24} color="white" />
						<Text style={styles.tabText}>Settings</Text>
					</TouchableOpacity>
				</View>

				{locationError && (
					<View style={styles.errorContainer}>
						<Text style={styles.errorText}>
							Location Error: Please enable location permissions
						</Text>
					</View>
				)}
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
		zIndex: 0,
	},
	overlayContainer: {
		position: "absolute",
		top: 0,
		left: 0,
		right: 0,
		bottom: 0,
		zIndex: 2,
		pointerEvents: "box-none",
	},
	topBar: {
		position: "absolute",
		top: Platform.OS === "ios" ? 50 : 20,
		left: 0,
		right: 0,
		flexDirection: "row",
		justifyContent: "space-between",
		paddingHorizontal: 20,
	},
	percentContainer: {
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
	compassContainer: {
		backgroundColor: "rgba(0, 0, 0, 0.7)",
		padding: 10,
		borderRadius: 8,
		alignItems: "center",
		justifyContent: "center",
	},
	tabBar: {
		position: "absolute",
		bottom: 0,
		left: 0,
		right: 0,
		height: 70,
		backgroundColor: "#333333",
		flexDirection: "row",
		justifyContent: "space-around",
		alignItems: "center",
		paddingBottom: Platform.OS === "ios" ? 20 : 0,
	},
	tabItem: {
		alignItems: "center",
		justifyContent: "center",
		paddingVertical: 8,
	},
	tabText: {
		color: "white",
		fontSize: 12,
		marginTop: 2,
	},
	errorContainer: {
		position: "absolute",
		bottom: 90,
		left: 20,
		right: 20,
		backgroundColor: "rgba(255, 0, 0, 0.7)",
		padding: 10,
		borderRadius: 8,
		alignItems: "center",
	},
	errorText: {
		color: "white",
		fontSize: 14,
	},
});

export default DefaultMapComponent;
