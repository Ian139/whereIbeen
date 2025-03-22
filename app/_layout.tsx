import { Stack } from "expo-router";

export default function RootLayout() {
	return (
		<Stack screenOptions={{ headerShown: false }}>
			<Stack.Screen name="index" />
			<Stack.Screen name="pages/ProfilePage" />
			<Stack.Screen name="pages/SettingsPage" />
			<Stack.Screen name="pages/StatisticsPage" />
			<Stack.Screen name="pages/AboutPage" />
		</Stack>
	);
}
