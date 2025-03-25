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
                // Merge nearby regions first before dropping old ones
                _erasedRegions = mergeNearbyRegions(newValue)
                
                // If still too many, keep only the most recent ones
                if _erasedRegions.count > MapArea.maxErasedRegionsStored {
                    _erasedRegions = Array(_erasedRegions.suffix(MapArea.maxErasedRegionsStored))
                }
            } else {
                _erasedRegions = newValue
            }
        }
    }
    
    /// Current region being viewed
    var currentRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.0922, longitudeDelta: 0.0421)
    )
    
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
    
    /// Merge nearby regions to optimize storage and calculations
    private func mergeNearbyRegions(_ regions: [ErasedRegion]) -> [ErasedRegion] {
        var processedRegions: [ErasedRegion] = []
        var remainingRegions = regions
        
        while !remainingRegions.isEmpty {
            let currentRegion = remainingRegions.removeFirst()
            var merged = false
            
            // Try to merge with an existing processed region
            for (index, existingRegion) in processedRegions.enumerated() {
                if shouldMergeRegions(currentRegion, existingRegion) {
                    let mergedRegion = mergeRegions(currentRegion, existingRegion)
                    processedRegions[index] = mergedRegion
                    merged = true
                    break
                }
            }
            
            // If not merged, add to processed regions
            if !merged {
                processedRegions.append(currentRegion)
            }
        }
        
        return processedRegions
    }
    
    /// Determine if two regions should be merged
    private func shouldMergeRegions(_ a: ErasedRegion, _ b: ErasedRegion) -> Bool {
        let distance = calculateDistance(from: a.center, to: b.center)
        let combinedRadius = (a.radiusMiles + b.radiusMiles) * 1609.34 * 0.7 // 70% of combined radius in meters
        return distance < combinedRadius
    }
    
    /// Merge two regions into one larger region
    private func mergeRegions(_ a: ErasedRegion, _ b: ErasedRegion) -> ErasedRegion {
        // Calculate weighted center point based on radius
        let totalWeight = a.radiusMiles + b.radiusMiles
        let ratio = a.radiusMiles / totalWeight
        
        let newLat = a.center.latitude * ratio + b.center.latitude * (1 - ratio)
        let newLng = a.center.longitude * ratio + b.center.longitude * (1 - ratio)
        
        // Calculate new radius that encompasses both regions
        let distance = calculateDistance(from: a.center, to: b.center) / 1609.34 // Convert meters to miles
        let newRadius = max(
            a.radiusMiles, 
            b.radiusMiles,
            (distance + min(a.radiusMiles, b.radiusMiles)) * 0.8 // 80% to avoid over-expansion
        )
        
        return ErasedRegion(
            center: CLLocationCoordinate2D(latitude: newLat, longitude: newLng),
            radiusMiles: newRadius
        )
    }
    
    /// Calculate distance between two coordinates in meters
    private func calculateDistance(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let sourceLocation = CLLocation(latitude: source.latitude, longitude: source.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return sourceLocation.distance(from: destinationLocation)
    }
    
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