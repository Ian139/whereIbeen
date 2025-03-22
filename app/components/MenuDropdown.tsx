import React, { useState } from "react";
import {
	View,
	TouchableOpacity,
	Text,
	Animated,
	StyleSheet,
	SafeAreaView,
	Dimensions,
	Platform,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";

const MENU_HEIGHT = Dimensions.get("window").height * 0.4;

const MenuDropdown: React.FC = () => {
	const [isOpen, setIsOpen] = useState(false);
	const slideAnim = useState(new Animated.Value(-MENU_HEIGHT))[0];

	const toggleMenu = () => {
		const toValue = isOpen ? -MENU_HEIGHT : 0;
		Animated.spring(slideAnim, {
			toValue,
			useNativeDriver: true,
			tension: 65,
			friction: 11,
		}).start();
		setIsOpen(!isOpen);
	};

	const handleNavigation = (route: string) => {
		toggleMenu();
		setTimeout(() => {
			router.push(route);
		}, 300);
	};

	return (
		<SafeAreaView style={styles.container}>
			<TouchableOpacity
				style={styles.menuButton}
				onPress={toggleMenu}
				activeOpacity={0.7}
			>
				<Ionicons name="menu" size={28} color="white" />
			</TouchableOpacity>

			<Animated.View
				style={[
					styles.menuContent,
					{
						transform: [{ translateY: slideAnim }],
					},
				]}
			>
				<View style={styles.menuItems}>
					<TouchableOpacity
						style={styles.menuItem}
						onPress={() => handleNavigation("/pages/ProfilePage")}
					>
						<Ionicons
							name="person-outline"
							size={24}
							color="white"
							style={styles.menuIcon}
						/>
						<Text style={styles.menuText}>Profile</Text>
					</TouchableOpacity>

					<TouchableOpacity
						style={styles.menuItem}
						onPress={() => handleNavigation("/pages/SettingsPage")}
					>
						<Ionicons
							name="settings-outline"
							size={24}
							color="white"
							style={styles.menuIcon}
						/>
						<Text style={styles.menuText}>Settings</Text>
					</TouchableOpacity>

					<TouchableOpacity
						style={styles.menuItem}
						onPress={() => handleNavigation("/pages/StatisticsPage")}
					>
						<Ionicons
							name="stats-chart-outline"
							size={24}
							color="white"
							style={styles.menuIcon}
						/>
						<Text style={styles.menuText}>Statistics</Text>
					</TouchableOpacity>

					<TouchableOpacity
						style={styles.menuItem}
						onPress={() => handleNavigation("/pages/AboutPage")}
					>
						<Ionicons
							name="information-circle-outline"
							size={24}
							color="white"
							style={styles.menuIcon}
						/>
						<Text style={styles.menuText}>About</Text>
					</TouchableOpacity>
				</View>
			</Animated.View>
		</SafeAreaView>
	);
};

const styles = StyleSheet.create({
	container: {
		position: "absolute",
		top: 0,
		right: 0,
		left: 0,
		zIndex: 1000,
	},
	menuButton: {
		position: "absolute",
		top: Platform.OS === "ios" ? 50 : 30,
		right: 20,
		backgroundColor: "#4CAF50",
		padding: 10,
		borderRadius: 12,
		zIndex: 1001,
		shadowColor: "#000",
		shadowOffset: {
			width: 0,
			height: 2,
		},
		shadowOpacity: 0.25,
		shadowRadius: 3.84,
		elevation: 5,
	},
	menuContent: {
		position: "absolute",
		top: 0,
		left: 0,
		right: 0,
		height: MENU_HEIGHT,
		backgroundColor: "#4CAF50",
		borderBottomLeftRadius: 30,
		borderBottomRightRadius: 30,
		padding: 20,
		paddingTop: Platform.OS === "ios" ? 90 : 70,
		shadowColor: "#000",
		shadowOffset: {
			width: 0,
			height: 8,
		},
		shadowOpacity: 0.44,
		shadowRadius: 10.32,
		elevation: 16,
	},
	menuItems: {
		marginTop: 20,
	},
	menuItem: {
		flexDirection: "row",
		alignItems: "center",
		paddingVertical: 15,
		borderBottomWidth: 1,
		borderBottomColor: "rgba(255, 255, 255, 0.2)",
		borderRadius: 12,
	},
	menuIcon: {
		marginRight: 15,
	},
	menuText: {
		color: "white",
		fontSize: 18,
		fontWeight: "500",
	},
});

export default MenuDropdown;
