import { Text, View, Pressable } from "react-native";
import { router } from "expo-router";

export default function Index() {
	return (
		<View
			style={{
				flex: 1,
				justifyContent: "center",
				alignItems: "center",
			}}
		>
			<Text>Welcome to the App</Text>
			<Pressable
				onPress={() => router.push("/(tabs)/DefaultMap")}
				style={{
					padding: 10,
					backgroundColor: "#007AFF",
					borderRadius: 5,
					marginTop: 20,
				}}
			>
				<Text style={{ color: "white" }}>View Map</Text>
			</Pressable>
		</View>
	);
}
