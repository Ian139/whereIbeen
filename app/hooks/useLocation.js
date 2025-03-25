import { useState, useEffect } from "react";
import * as Location from "expo-location";
import { startMockLocation, stopMockLocation } from "../utils/_mockLocation";

const useLocation = (shouldTrack = false, isMockingEnabled = false) => {
	const [location, setLocation] = useState(null);
	const [error, setError] = useState(null);
	const [mockIntervalId, setMockIntervalId] = useState(null);

	useEffect(() => {
		let subscriber = null;

		const startWatching = async () => {
			try {
				const { status } = await Location.requestForegroundPermissionsAsync();
				if (status !== "granted") {
					setError("Permission to access location was denied");
					return;
				}

				// If mocking is enabled, start mock location updates
				if (isMockingEnabled) {
					const intervalId = startMockLocation();
					setMockIntervalId(intervalId);
				} else {
					// Start real location tracking
					subscriber = await Location.watchPositionAsync(
						{
							accuracy: Location.Accuracy.BestForNavigation,
							timeInterval: 1000,
							distanceInterval: 10,
						},
						(location) => {
							setLocation(location);
						}
					);
				}
			} catch (err) {
				setError(err);
			}
		};

		if (shouldTrack) {
			startWatching();
		} else {
			if (subscriber) {
				subscriber.remove();
			}
			if (mockIntervalId) {
				stopMockLocation(mockIntervalId);
				setMockIntervalId(null);
			}
		}

		return () => {
			if (subscriber) {
				subscriber.remove();
			}
			if (mockIntervalId) {
				stopMockLocation(mockIntervalId);
			}
		};
	}, [shouldTrack, isMockingEnabled]);

	return [location, error];
};

export default useLocation;
