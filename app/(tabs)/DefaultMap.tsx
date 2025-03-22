import React from "react";
import { View, StyleSheet } from "react-native";
import DefaultMapComponent from "../components/DefaultMapComponent";

const DefaultMap: React.FC = () => {
	return (
		<View style={styles.container}>
			<DefaultMapComponent />
		</View>
	);
};

const styles = StyleSheet.create({
	container: {
		flex: 1,
		width: "100%",
	},
});

export default DefaultMap;
