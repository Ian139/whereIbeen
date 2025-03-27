import Foundation
import MapKit

struct Trip: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let startDate: Date
    let endDate: Date?
    let totalMiles: Double
    let isPrivate: Bool
    
    // Non-Codable properties that need custom encoding/decoding
    var coordinates: [CLLocationCoordinate2D]
    var region: MKCoordinateRegion
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, startDate, endDate, totalMiles, isPrivate
        case coordinatesLatitude, coordinatesLongitude
        case centerLatitude, centerLongitude, latitudeDelta, longitudeDelta
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         startDate: Date,
         endDate: Date? = nil,
         coordinates: [CLLocationCoordinate2D],
         totalMiles: Double,
         isPrivate: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.coordinates = coordinates
        self.totalMiles = totalMiles
        self.isPrivate = isPrivate
        
        // Calculate region from coordinates
        self.region = Self.calculateRegion(for: coordinates)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        totalMiles = try container.decode(Double.self, forKey: .totalMiles)
        isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        
        // Decode coordinates
        let latitudes = try container.decode([Double].self, forKey: .coordinatesLatitude)
        let longitudes = try container.decode([Double].self, forKey: .coordinatesLongitude)
        
        coordinates = zip(latitudes, longitudes).map {
            CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1)
        }
        
        // Decode region
        let centerLatitude = try container.decode(Double.self, forKey: .centerLatitude)
        let centerLongitude = try container.decode(Double.self, forKey: .centerLongitude)
        let latitudeDelta = try container.decode(Double.self, forKey: .latitudeDelta)
        let longitudeDelta = try container.decode(Double.self, forKey: .longitudeDelta)
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(totalMiles, forKey: .totalMiles)
        try container.encode(isPrivate, forKey: .isPrivate)
        
        // Encode coordinates
        try container.encode(coordinates.map { $0.latitude }, forKey: .coordinatesLatitude)
        try container.encode(coordinates.map { $0.longitude }, forKey: .coordinatesLongitude)
        
        // Encode region
        try container.encode(region.center.latitude, forKey: .centerLatitude)
        try container.encode(region.center.longitude, forKey: .centerLongitude)
        try container.encode(region.span.latitudeDelta, forKey: .latitudeDelta)
        try container.encode(region.span.longitudeDelta, forKey: .longitudeDelta)
    }
    
    private static func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        // Calculate the bounding box
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        // Calculate center
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate span with some padding
        let latDelta = (maxLat - minLat) * 1.1 // 10% padding
        let lonDelta = (maxLon - minLon) * 1.1
        
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        )
    }
} 