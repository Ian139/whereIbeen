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

export default function SettingsPage() {
	return (
		<SafeAreaView style={styles.container}>
			<View style={styles.header}>
				<TouchableOpacity
					onPress={() => router.back()}
					style={styles.backButton}
				>
					<Ionicons name="arrow-back" size={24} color="white" />
				</TouchableOpacity>
				<Text style={styles.title}>Settings</Text>
			</View>

			<View style={styles.content}>
				<TouchableOpacity style={styles.settingItem}>
					<Text style={styles.settingText}>Notifications</Text>
					<Ionicons name="notifications-outline" size={24} color="#4CAF50" />
				</TouchableOpacity>

				<TouchableOpacity style={styles.settingItem}>
					<Text style={styles.settingText}>Theme</Text>
					<Ionicons name="color-palette-outline" size={24} color="#4CAF50" />
				</TouchableOpacity>

				<TouchableOpacity style={styles.settingItem}>
					<Text style={styles.settingText}>Privacy</Text>
					<Ionicons name="lock-closed-outline" size={24} color="#4CAF50" />
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
	settingItem: {
		flexDirection: "row",
		justifyContent: "space-between",
		alignItems: "center",
		paddingVertical: 15,
		borderBottomWidth: 1,
		borderBottomColor: "#eee",
	},
	settingText: {
		fontSize: 16,
		color: "#333",
	},
});
