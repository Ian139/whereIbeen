import MapKit
import Foundation

struct MapArea {
    /// Maximum number of coordinates to store to prevent memory issues
    static let maxCoordinatesStored = 1000
    
    /// Maximum number of erased regions to track
    static let maxErasedRegionsStored = 500
    
    /// Coordinates that have been explored by the user
    private var _exploredCoordinates: [CLLocationCoordinate2D] = []
    var exploredCoordinates: [CLLocationCoordinate2D] {
        get { return _exploredCoordinates }
        set {
            // Limit the number of stored coordinates to prevent memory issues
            if newValue.count > MapArea.maxCoordinatesStored {
                _exploredCoordinates = Array(newValue.suffix(MapArea.maxCoordinatesStored))
            } else {
                _exploredCoordinates = newValue
            }
        }
    }
    
    /// Regions that have been erased/explored (stored as circles with center and radius)
    private var _erasedRegions: [ErasedRegion] = []
    var erasedRegions: [ErasedRegion] {
        get { return _erasedRegions }
        set {
            // Limit the number of regions to prevent memory issues
            if newValue.count > MapArea.maxErasedRegionsStored {
                // If too many regions, keep only the most recent ones
                _erasedRegions = Array(newValue.suffix(MapArea.maxErasedRegionsStored))
            } else {
                _erasedRegions = newValue
            }
        }
    }
    
    /// Current region being viewed
    var currentRegion: MKCoordinateRegion = defaultRegion
    
    /// User's current location
    var userLocation: CLLocationCoordinate2D? = nil
    
    /// Flag to determine if the map should follow the user
    var isFollowingUser: Bool = true
    
    /// Constants
    static let minZoomDelta: Double = 0.05 // Smaller zoom delta for closer exploration
    static let maxZoomDelta: Double = 100
    static let autoEraserRadiusMiles: Double = 0.25 // Radius for auto-clearing based on user location
    static let autoErasingInterval: TimeInterval = 5 // Seconds between location-based erasings
    
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.0922, longitudeDelta: 0.0421)
    )
    
    /// Calculate distance between two coordinates in meters
    private func calculateDistance(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let sourceLocation = CLLocation(latitude: source.latitude, longitude: source.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return sourceLocation.distance(from: destinationLocation)
    }
    
    /// Update the current region to center on the user's location
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