import React from "react";
import { View, StyleSheet, StatusBar, Platform } from "react-native";
import DefaultMapComponent from "./components/DefaultMapComponent";

export default function Index() {
	return (
		<View style={styles.container}>
			<StatusBar
				barStyle="dark-content"
				backgroundColor="transparent"
				translucent={Platform.OS === "android"}
			/>
			<DefaultMapComponent />
		</View>
	);
}

const styles = StyleSheet.create({
	container: {
		flex: 1,
		width: "100%",
	},
});
