import * as Location from "expo-location";

const tenMetersWithDegrees = 0.0001;

const getLocation = (increment) => {
	return {
		timestamp: 1000000,
		coords: {
			speed: 0,
			heading: 0,
			accuracy: 5,
			altitudeAccuracy: 5,
			altitude: 5,
			longitude: -122.0312186 + increment * tenMetersWithDegrees, // San Francisco area
			latitude: 37.33233141 + increment * tenMetersWithDegrees,
		},
	};
};

let counter = 0;

// Start location spoofing
const startMockLocation = () => {
	return setInterval(() => {
		Location.EventEmitter.emit("Expo.locationChanged", {
			watchId: Location._getCurrentWatchId(),
			location: getLocation(counter),
		});
		counter++;
	}, 1000);
};

// Stop location spoofing
const stopMockLocation = (intervalId) => {
	clearInterval(intervalId);
	counter = 0;
};

export { startMockLocation, stopMockLocation };
