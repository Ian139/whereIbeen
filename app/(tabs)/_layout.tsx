import { Tabs } from "expo-router";
import { FontAwesome } from "@expo/vector-icons";

export default function TabsLayout() {
	return (
		<Tabs
			screenOptions={{
				headerShown: false,
				tabBarStyle: {
					// Add any tab bar styling you want here
				},
			}}
		>
			<Tabs.Screen
				name="DefaultMap"
				options={{
					title: "Map",
					tabBarIcon: ({ color }) => (
						<FontAwesome
							name="map"
							size={28}
							style={{ marginBottom: -3 }}
							color={color}
						/>
					),
				}}
			/>
		</Tabs>
	);
}
