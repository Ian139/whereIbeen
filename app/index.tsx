import React from "react";
import { View, StyleSheet } from "react-native";
import DefaultMapComponent from "./components/DefaultMapComponent";
import MenuDropdown from "./components/MenuDropdown";

export default function Index() {
	return (
		<View style={styles.container}>
			<DefaultMapComponent />
			<MenuDropdown />
		</View>
	);
}

const styles = StyleSheet.create({
	container: {
		flex: 1,
		width: "100%",
	},
});
