import React from "react";
import { View, StyleSheet } from "react-native";
import DefaultMapComponent from "./components/DefaultMapComponent";

export default function Index() {
	return (
		<View style={styles.container}>
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
