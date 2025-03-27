import MapKit
import Foundation

/// Represents a circular region that has been erased/explored
public typealias WhereIBeenErasedRegion = ErasedRegion

public struct ErasedRegion: Equatable {
    public let center: CLLocationCoordinate2D
    public let radiusMiles: Double
    
    public init(center: CLLocationCoordinate2D, radiusMiles: Double) {
        self.center = center
        self.radiusMiles = radiusMiles
    }
    
    public static func == (lhs: ErasedRegion, rhs: ErasedRegion) -> Bool {
        return lhs.center.latitude == rhs.center.latitude &&
               lhs.center.longitude == rhs.center.longitude &&
               lhs.radiusMiles == rhs.radiusMiles
    }
} 