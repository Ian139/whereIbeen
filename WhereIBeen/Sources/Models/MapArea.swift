import MapKit
import Foundation

struct MapArea {
    /// Coordinates that have been explored by the user
    var exploredCoordinates: [CLLocationCoordinate2D] = []
    
    /// Regions that have been erased/explored (stored as circles with center and radius)
    var erasedRegions: [ErasedRegion] = []
    
    /// Current region being viewed
    var currentRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.0922, longitudeDelta: 0.0421)
    )
    
    /// User's current location
    var userLocation: CLLocationCoordinate2D? = nil
    
    /// Percentage of the world explored (0-100)
    var percentExplored: Double = 0
    
    /// Flag to determine if the map should follow the user
    var isFollowingUser: Bool = true
    
    /// Constants
    static let earthSurfaceArea: Double = 510100000 // km²
    static let minZoomDelta: Double = 0.05 // Smaller zoom delta for closer exploration
    static let maxZoomDelta: Double = 100
    static let autoEraserRadiusMiles: Double = 0.25 // Radius for auto-clearing based on user location
    static let autoErasingInterval: TimeInterval = 5 // Seconds between location-based erasings
    
    /// Default starting region
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.0922, longitudeDelta: 0.0421)
    )
    
    /// Calculate the total area erased in square kilometers
    func calculateErasedArea() -> Double {
        let erasedRegionAreas = erasedRegions.map { region -> Double in
            // Convert miles to kilometers for the radius
            let radiusInKm = region.radiusMiles * 1.60934
            // Area of a circle = π × r²
            return Double.pi * pow(radiusInKm, 2)
        }
        
        // This is a simplification that doesn't account for overlapping regions
        // For a more accurate calculation, more complex geometry would be needed
        return erasedRegionAreas.reduce(0, +)
    }
    
    /// Update the current region to center on the user's location
    /// - Parameter userLocation: The user's current location
    /// - Returns: The updated region
    mutating func centerOnUserLocation() -> MKCoordinateRegion? {
        guard let userLocation = userLocation else { return nil }
        
        currentRegion = MKCoordinateRegion(
            center: userLocation,
            span: currentRegion.span
        )
        
        return currentRegion
    }
}

/// Represents a circular region that has been erased/explored
struct ErasedRegion: Equatable {
    let center: CLLocationCoordinate2D
    let radiusMiles: Double
    
    static func == (lhs: ErasedRegion, rhs: ErasedRegion) -> Bool {
        return lhs.center.latitude == rhs.center.latitude &&
               lhs.center.longitude == rhs.center.longitude &&
               lhs.radiusMiles == rhs.radiusMiles
    }
} 