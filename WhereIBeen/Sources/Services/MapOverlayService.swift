import MapKit

/// Service for managing map overlays
class MapOverlayService {
    
    /// Creates a fog overlay for the unexplored areas of the map
    /// - Parameters:
    ///   - region: The current map region
    ///   - erasedRegions: Array of regions that have been explored/erased
    /// - Returns: A fog overlay to be displayed on the map
    func createFogOverlay(region: MKCoordinateRegion, erasedRegions: [ErasedRegion]) -> MKPolygon {
        return FogOverlay(region: region, erasedRegions: erasedRegions)
    }
    
    /// Calculates the percentage of the world that has been explored
    /// - Parameters:
    ///   - erasedArea: Total area that has been erased/explored in square kilometers
    /// - Returns: Percentage of world explored (0-100)
    func calculateExploredPercentage(erasedArea: Double) -> Double {
        return min((erasedArea / MapArea.earthSurfaceArea) * 100, 100)
    }
    
    /// Calculates the percentage of the world that is visible in the current map view
    /// - Parameter region: The current map region
    /// - Returns: Percentage of world that is visible (0-100)
    func calculateVisiblePercentage(region: MKCoordinateRegion) -> Double {
        let latDegrees = region.span.latitudeDelta
        let lngDegrees = region.span.longitudeDelta
        let centerLat = region.center.latitude
        
        // Convert degrees to kilometers
        let degreesToKm = 111.32
        let correction = cos(centerLat * .pi / 180)
        let visibleAreaKm = latDegrees * lngDegrees * degreesToKm * degreesToKm * correction
        
        return min((visibleAreaKm / MapArea.earthSurfaceArea) * 100, 100)
    }
    
    /// Convert a screen point to a coordinate on the map
    /// - Parameters:
    ///   - point: The screen point (CGPoint)
    ///   - mapView: The MapView instance
    /// - Returns: The corresponding coordinate
    func convertPointToCoordinate(point: CGPoint, in mapView: MKMapView) -> CLLocationCoordinate2D {
        return mapView.convert(point, toCoordinateFrom: mapView)
    }
}

/// Custom Fog Overlay that shows unexplored areas
class FogOverlay: MKPolygon {
    convenience init(region: MKCoordinateRegion, erasedRegions: [ErasedRegion]) {
        // Create the outer bounds of the fog
        let padding = max(region.span.latitudeDelta, region.span.longitudeDelta) * 0.5
        
        let bounds = [
            CLLocationCoordinate2D(
                latitude: region.center.latitude - region.span.latitudeDelta/2 - padding,
                longitude: region.center.longitude - region.span.longitudeDelta/2 - padding
            ),
            CLLocationCoordinate2D(
                latitude: region.center.latitude - region.span.latitudeDelta/2 - padding,
                longitude: region.center.longitude + region.span.longitudeDelta/2 + padding
            ),
            CLLocationCoordinate2D(
                latitude: region.center.latitude + region.span.latitudeDelta/2 + padding,
                longitude: region.center.longitude + region.span.longitudeDelta/2 + padding
            ),
            CLLocationCoordinate2D(
                latitude: region.center.latitude + region.span.latitudeDelta/2 + padding,
                longitude: region.center.longitude - region.span.longitudeDelta/2 - padding
            )
        ]
        
        // Create interior polygons for each erased region (circle approximation)
        var interiorPolygons: [MKPolygon] = []
        
        for erasedRegion in erasedRegions {
            // Create a circular polygon by approximating with points
            let circlePoints = FogOverlay.createCirclePoints(
                center: erasedRegion.center,
                radiusMiles: erasedRegion.radiusMiles,
                numPoints: 36 // More points = smoother circle
            )
            
            if circlePoints.count >= 3 {
                interiorPolygons.append(MKPolygon(coordinates: circlePoints, count: circlePoints.count))
            }
        }
        
        if !interiorPolygons.isEmpty {
            self.init(coordinates: bounds, count: bounds.count, interiorPolygons: interiorPolygons)
        } else {
            self.init(coordinates: bounds, count: bounds.count)
        }
    }
    
    /// Create points that approximate a circle for the given center and radius
    private static func createCirclePoints(center: CLLocationCoordinate2D, radiusMiles: Double, numPoints: Int) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []
        
        // Convert miles to meters
        let radiusMeters = radiusMiles * 1609.34
        
        for i in 0..<numPoints {
            let angle = Double(i) * (2.0 * Double.pi / Double(numPoints))
            let pointCoordinate = calculateCoordinate(center: center, radiusMeters: radiusMeters, bearing: angle)
            points.append(pointCoordinate)
        }
        
        return points
    }
    
    /// Calculate a coordinate at a given distance and bearing from a center point
    private static func calculateCoordinate(center: CLLocationCoordinate2D, radiusMeters: Double, bearing: Double) -> CLLocationCoordinate2D {
        let earthRadiusMeters = 6371000.0
        
        let latRad = center.latitude * Double.pi / 180
        let lngRad = center.longitude * Double.pi / 180
        let angularDistance = radiusMeters / earthRadiusMeters
        let trueBearing = bearing
        
        let newLatRad = asin(sin(latRad) * cos(angularDistance) + cos(latRad) * sin(angularDistance) * cos(trueBearing))
        
        var newLngRad = lngRad + atan2(
            sin(trueBearing) * sin(angularDistance) * cos(latRad),
            cos(angularDistance) - sin(latRad) * sin(newLatRad)
        )
        
        // Normalize longitude to -180 to +180
        newLngRad = fmod((newLngRad + 3 * Double.pi), (2 * Double.pi)) - Double.pi
        
        let newLat = newLatRad * 180 / Double.pi
        let newLng = newLngRad * 180 / Double.pi
        
        return CLLocationCoordinate2D(latitude: newLat, longitude: newLng)
    }
} 