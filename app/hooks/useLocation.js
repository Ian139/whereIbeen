import { useState, useEffect, useRef } from "react";
import * as Location from "expo-location";
import { startMockLocation, stopMockLocation } from "../utils/_mockLocation";

const useLocation = (shouldTrack = false, isMockingEnabled = false) => {
	const [location, setLocation] = useState(null);
	const [error, setError] = useState(null);
	const mockIntervalId = useRef(null);
	const locationSubscriber = useRef(null);

	// Clean up function to stop tracking and remove subscribers
	const cleanUp = () => {
		if (locationSubscriber.current) {
			locationSubscriber.current.remove();
			locationSubscriber.current = null;
		}

		if (mockIntervalId.current) {
			stopMockLocation(mockIntervalId.current);
			mockIntervalId.current = null;
		}
	};

	useEffect(() => {
		const startWatching = async () => {
			try {
				// Clean up any existing watchers
				cleanUp();

				// Request location permissions
				const { status } = await Location.requestForegroundPermissionsAsync();
				if (status !== "granted") {
					setError("Permission to access location was denied");
					return;
				}

				// If mocking is enabled, start mock location updates
				if (isMockingEnabled) {
					// Set up a listener for mock location changes
					const locationListener = (locationEvent) => {
						if (locationEvent && locationEvent.location) {
							setLocation(locationEvent.location);
						}
					};

					// Add the event listener
					Location.EventEmitter.addListener(
						"Expo.locationChanged",
						locationListener
					);

					// Start the mock location service
					const intervalId = startMockLocation();
					if (intervalId) {
						mockIntervalId.current = intervalId;
					} else {
						setError("Failed to start mock location service");
					}
				} else {
					// Use real location
					try {
						// Request high accuracy
						await Location.enableNetworkProviderAsync().catch(() =>
							console.log("Network provider could not be enabled")
						);

						// Start watching position
						locationSubscriber.current = await Location.watchPositionAsync(
							{
								accuracy: Location.Accuracy.BestForNavigation,
								timeInterval: 1000, // Update every second
								distanceInterval: 10, // Update every 10 meters
							},
							(newLocation) => {
								setLocation(newLocation);
							}
						);
					} catch (err) {
						console.error("Error watching location:", err);
						setError(`Error watching location: ${err.message}`);
					}
				}
			} catch (err) {
				console.error("Location error:", err);
				setError(`Location error: ${err.message}`);
			}
		};

		if (shouldTrack) {
			startWatching();
		} else {
			cleanUp();
		}

		// Cleanup on unmount or when tracking is disabled
		return cleanUp;
	}, [shouldTrack, isMockingEnabled]);

	return [location, error];
};

export default useLocation;
