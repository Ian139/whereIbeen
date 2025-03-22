import React, { useState, useRef } from "react";
import { View, StyleSheet, Pressable, Platform } from "react-native";
import MapView, { Polyline, PROVIDER_DEFAULT } from "react-native-maps";
import { MaterialIcons } from "@expo/vector-icons";

interface Coordinate {
	latitude: number;
	longitude: number;
}

const DefaultMapComponent: React.FC = () => {
	const [path, setPath] = useState<Coordinate[]>([]);
	const [isDrawing, setIsDrawing] = useState(false);
	const mapRef = useRef<MapView>(null);

	const initialRegion = {
		latitude: 34.0522, // Los Angeles
		longitude: -118.2437,
		latitudeDelta: 0.0922,
		longitudeDelta: 0.0421,
	};

	const handleMapPress = (event: any) => {
		if (!isDrawing) return;
		const { coordinate } = event.nativeEvent;
		setPath((prevPath) => [...prevPath, coordinate]);
	};

	const toggleDrawing = () => {
		setIsDrawing(!isDrawing);
	};

	const clearPath = () => {
		setPath([]);
	};

	return (
		<View style={styles.container}>
			<MapView
				ref={mapRef}
				style={styles.map}
				provider={PROVIDER_DEFAULT}
				initialRegion={initialRegion}
				onPress={handleMapPress}
			>
				{path.length > 0 && (
					<Polyline coordinates={path} strokeColor="#F00" strokeWidth={3} />
				)}
			</MapView>
			<View style={styles.controls}>
				<Pressable
					style={[styles.button, isDrawing && styles.activeButton]}
					onPress={toggleDrawing}
				>
					<MaterialIcons
						name="edit"
						size={24}
						color={isDrawing ? "#FFF" : "#000"}
					/>
				</Pressable>
				<Pressable style={styles.button} onPress={clearPath}>
					<MaterialIcons name="clear" size={24} color="#000" />
				</Pressable>
			</View>
		</View>
	);
};

const styles = StyleSheet.create({
	container: {
		flex: 1,
		width: "100%",
	},
	map: {
		width: "100%",
		height: "100%",
	},
	controls: {
		position: "absolute",
		right: 16,
		top: 16,
		gap: 8,
	},
	button: {
		backgroundColor: "white",
		padding: 12,
		borderRadius: 8,
		shadowColor: "#000",
		shadowOffset: {
			width: 0,
			height: 2,
		},
		shadowOpacity: 0.25,
		shadowRadius: 3.84,
		elevation: 5,
	},
	activeButton: {
		backgroundColor: "#007AFF",
	},
});

export default DefaultMapComponent;
