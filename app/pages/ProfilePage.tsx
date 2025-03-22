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

export default function ProfilePage() {
	return (
		<SafeAreaView style={styles.container}>
			<View style={styles.header}>
				<TouchableOpacity
					onPress={() => router.back()}
					style={styles.backButton}
				>
					<Ionicons name="arrow-back" size={24} color="white" />
				</TouchableOpacity>
				<Text style={styles.title}>Profile</Text>
			</View>

			<View style={styles.content}>
				<View style={styles.profileHeader}>
					<View style={styles.avatarContainer}>
						<Ionicons name="person-circle" size={100} color="#4CAF50" />
					</View>
					<Text style={styles.name}>John Doe</Text>
					<Text style={styles.username}>@johndoe</Text>
				</View>

				<View style={styles.statsContainer}>
					<View style={styles.statItem}>
						<Text style={styles.statValue}>42</Text>
						<Text style={styles.statLabel}>Countries</Text>
					</View>
					<View style={styles.statItem}>
						<Text style={styles.statValue}>156</Text>
						<Text style={styles.statLabel}>Cities</Text>
					</View>
					<View style={styles.statItem}>
						<Text style={styles.statValue}>23%</Text>
						<Text style={styles.statLabel}>World</Text>
					</View>
				</View>

				<TouchableOpacity style={styles.menuItem}>
					<Ionicons name="person-outline" size={24} color="#4CAF50" />
					<Text style={styles.menuText}>Edit Profile</Text>
					<Ionicons name="chevron-forward" size={24} color="#ccc" />
				</TouchableOpacity>

				<TouchableOpacity style={styles.menuItem}>
					<Ionicons name="share-outline" size={24} color="#4CAF50" />
					<Text style={styles.menuText}>Share Profile</Text>
					<Ionicons name="chevron-forward" size={24} color="#ccc" />
				</TouchableOpacity>

				<TouchableOpacity style={styles.menuItem}>
					<Ionicons name="log-out-outline" size={24} color="#4CAF50" />
					<Text style={styles.menuText}>Logout</Text>
					<Ionicons name="chevron-forward" size={24} color="#ccc" />
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
		flex: 1,
	},
	profileHeader: {
		alignItems: "center",
		paddingVertical: 20,
		borderBottomWidth: 1,
		borderBottomColor: "#eee",
	},
	avatarContainer: {
		marginBottom: 10,
	},
	name: {
		fontSize: 24,
		fontWeight: "bold",
		color: "#333",
	},
	username: {
		fontSize: 16,
		color: "#666",
		marginTop: 5,
	},
	statsContainer: {
		flexDirection: "row",
		justifyContent: "space-around",
		paddingVertical: 20,
		borderBottomWidth: 1,
		borderBottomColor: "#eee",
	},
	statItem: {
		alignItems: "center",
	},
	statValue: {
		fontSize: 20,
		fontWeight: "bold",
		color: "#4CAF50",
	},
	statLabel: {
		fontSize: 14,
		color: "#666",
		marginTop: 5,
	},
	menuItem: {
		flexDirection: "row",
		alignItems: "center",
		padding: 15,
		borderBottomWidth: 1,
		borderBottomColor: "#eee",
	},
	menuText: {
		flex: 1,
		marginLeft: 15,
		fontSize: 16,
		color: "#333",
	},
});
