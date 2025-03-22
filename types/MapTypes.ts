// Types and interfaces for the map
export interface MapRegion {
	id: string;
	name: string;
	color: string;
	coordinates: string; // SVG path data
}

// Sample data - you could expand this to include more regions or different maps
export const sampleRegions: MapRegion[] = [
	{
		id: "1",
		name: "Region 1",
		color: "#FFD700",
		coordinates: "M 100 100 L 300 100 L 300 200 L 100 200 Z",
	},
	{
		id: "2",
		name: "Region 2",
		color: "#98FB98",
		coordinates: "M 100 250 L 300 250 L 300 350 L 100 350 Z",
	},
];

// You could add more map-related constants or utility functions here
export const DEFAULT_MAP_CONFIG = {
	width: 800,
	height: 600,
	strokeWidth: 2,
	strokeColor: "#000",
};
