import React from "react";
import {
	View,
	Text,
	StyleSheet,
	SafeAreaView,
	TouchableOpacity,
	Image,
} from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

export default function AboutPage() {
	return (
		<SafeAreaView style={styles.container}>
			<View style={styles.header}>
				<TouchableOpacity
					onPress={() => router.back()}
					style={styles.backButton}
				>
					<Ionicons name="arrow-back" size={24} color="white" />
				</TouchableOpacity>
				<Text style={styles.title}>About</Text>
			</View>

			<View style={styles.content}>
				<View style={styles.logoContainer}>
					<Ionicons name="map" size={80} color="#4CAF50" />
					<Text style={styles.appName}>WhereIBeen</Text>
					<Text style={styles.version}>Version 1.0.0</Text>
				</View>

				<View style={styles.infoSection}>
					<Text style={styles.description}>
						Track and visualize your exploration journey across the world.
						Uncover new places and keep a record of your adventures.
					</Text>
				</View>

				<TouchableOpacity style={styles.linkButton}>
					<Text style={styles.linkText}>Privacy Policy</Text>
					<Ionicons name="arrow-forward" size={20} color="#4CAF50" />
				</TouchableOpacity>

				<TouchableOpacity style={styles.linkButton}>
					<Text style={styles.linkText}>Terms of Service</Text>
					<Ionicons name="arrow-forward" size={20} color="#4CAF50" />
				</TouchableOpacity>
			</View>
		</SafeAreaView>
	);
}

const styles = StyleSheet.create({
	container: {
		flex: 1,
		backgroundColor: "#fff",
	},
	header: {
		backgroundColor: "#4CAF50",
		padding: 20,
		flexDirection: "row",
		alignItems: "center",
	},
	backButton: {
		marginRight: 15,
	},
	title: {
		fontSize: 20,
		fontWeight: "bold",
		color: "white",
	},
	content: {
		padding: 20,
	},
	logoContainer: {
		alignItems: "center",
		marginVertical: 30,
	},
	appName: {
		fontSize: 24,
		fontWeight: "bold",
		color: "#333",
		marginTop: 10,
	},
	version: {
		fontSize: 16,
		color: "#666",
		marginTop: 5,
	},
	infoSection: {
		marginVertical: 20,
	},
	description: {
		fontSize: 16,
		color: "#666",
		lineHeight: 24,
		textAlign: "center",
	},
	linkButton: {
		flexDirection: "row",
		justifyContent: "space-between",
		alignItems: "center",
		paddingVertical: 15,
		borderBottomWidth: 1,
		borderBottomColor: "#eee",
	},
	linkText: {
		fontSize: 16,
		color: "#333",
	},
});
