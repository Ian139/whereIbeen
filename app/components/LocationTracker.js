import React, { useState } from "react";
import { View, Text, Switch, StyleSheet } from "react-native";
import useLocation from "../hooks/useLocation";

const LocationTracker = () => {
	const [isTracking, setIsTracking] = useState(false);
	const [isMocking, setIsMocking] = useState(false);
	const [location, error] = useLocation(isTracking, isMocking);

	return (
		<View style={styles.container}>
			<View style={styles.row}>
				<Text>Track Location: </Text>
				<Switch value={isTracking} onValueChange={setIsTracking} />
			</View>

			<View style={styles.row}>
				<Text>Use Mock Location: </Text>
				<Switch
					value={isMocking}
					onValueChange={(value) => {
						setIsMocking(value);
						// Restart tracking when toggling mock mode
						if (isTracking) {
							setIsTracking(false);
							setTimeout(() => setIsTracking(true), 100);
						}
					}}
				/>
			</View>

			{error ? <Text style={styles.error}>Error: {error}</Text> : null}

			{location ? (
				<View style={styles.locationContainer}>
					<Text style={styles.locationText}>
						Latitude: {location.coords.latitude}
					</Text>
					<Text style={styles.locationText}>
						Longitude: {location.coords.longitude}
					</Text>
				</View>
			) : (
				<Text>Waiting for location...</Text>
			)}
		</View>
	);
};

const styles = StyleSheet.create({
	container: {
		padding: 20,
	},
	row: {
		flexDirection: "row",
		alignItems: "center",
		justifyContent: "space-between",
		marginBottom: 20,
	},
	locationContainer: {
		marginTop: 20,
		padding: 10,
		backgroundColor: "#f0f0f0",
		borderRadius: 5,
	},
	locationText: {
		fontSize: 16,
		marginBottom: 5,
	},
	error: {
		color: "red",
		marginTop: 10,
	},
});

export default LocationTracker;
