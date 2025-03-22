import React from "react";
import {
	View,
	Text,
	StyleSheet,
	SafeAreaView,
	TouchableOpacity,
} from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

export default function StatisticsPage() {
	return (
		<SafeAreaView style={styles.container}>
			<View style={styles.header}>
				<TouchableOpacity
					onPress={() => router.back()}
					style={styles.backButton}
				>
					<Ionicons name="arrow-back" size={24} color="white" />
				</TouchableOpacity>
				<Text style={styles.title}>Statistics</Text>
			</View>

			<View style={styles.content}>
				<View style={styles.statCard}>
					<Text style={styles.statTitle}>Total Area Explored</Text>
					<Text style={styles.statValue}>2,345 km²</Text>
				</View>

				<View style={styles.statCard}>
					<Text style={styles.statTitle}>Places Visited</Text>
					<Text style={styles.statValue}>127</Text>
				</View>

				<View style={styles.statCard}>
					<Text style={styles.statTitle}>Time Exploring</Text>
					<Text style={styles.statValue}>48h 23m</Text>
				</View>
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
	statCard: {
		backgroundColor: "#f5f5f5",
		borderRadius: 15,
		padding: 20,
		marginBottom: 15,
		shadowColor: "#000",
		shadowOffset: {
			width: 0,
			height: 2,
		},
		shadowOpacity: 0.1,
		shadowRadius: 3.84,
		elevation: 5,
	},
	statTitle: {
		fontSize: 16,
		color: "#666",
		marginBottom: 10,
	},
	statValue: {
		fontSize: 24,
		fontWeight: "bold",
		color: "#4CAF50",
	},
});
