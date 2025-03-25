import * as Location from "expo-location";

// Configurable settings
// 0.0001 degrees is approximately 10 meters at the equator
const tenMetersWithDegrees = 0.0001;

// Default starting point (San Francisco), customize as needed
const DEFAULT_STARTING_LATITUDE = 37.33233141;
const DEFAULT_STARTING_LONGITUDE = -122.0312186;

// Customize this function to set a specific path for testing
const getLocation = (increment) => {
	// You can modify this to create different patterns (circle, square, etc.)
	return {
		timestamp: Date.now(),
		coords: {
			speed: 0,
			heading: 0,
			accuracy: 5,
			altitudeAccuracy: 5,
			altitude: 5,
			longitude: DEFAULT_STARTING_LONGITUDE + increment * tenMetersWithDegrees,
			latitude: DEFAULT_STARTING_LATITUDE + increment * tenMetersWithDegrees,
		},
	};
};

let counter = 0;
let watchId = null;

// Start location spoofing
const startMockLocation = () => {
	// Make sure we have the current watchId
	try {
		// Get the current watchId if it exists
		watchId =
			Location._getCurrentWatchId?.() || Math.floor(Math.random() * 1000000);

		// Reset counter to start from beginning
		counter = 0;

		return setInterval(() => {
			// Emit the location change event
			Location.EventEmitter.emit("Expo.locationChanged", {
				watchId: watchId,
				location: getLocation(counter),
			});

			// Increment counter to move to next position
			counter++;
		}, 1000);
	} catch (error) {
		console.error("Error starting mock location:", error);
		return null;
	}
};

// Stop location spoofing
const stopMockLocation = (intervalId) => {
	if (intervalId) {
		clearInterval(intervalId);
	}
	counter = 0;
};

export { startMockLocation, stopMockLocation };
