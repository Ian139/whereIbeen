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
    // Maximum number of erased regions to include at once
    private static let maxRegionsToProcess = 25
    
    convenience init(region: MKCoordinateRegion, erasedRegions: [ErasedRegion]) {
        // Create the outer bounds of the fog
        let padding = min(max(region.span.latitudeDelta, region.span.longitudeDelta) * 0.5, 5.0)
        
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
        
        // Filter regions that are visible in the current viewport
        let visibleRegions = erasedRegions.filter { regionItem in
            let visibleBounds = FogOverlay.calculateBounds(from: bounds)
            let buffer = regionItem.radiusMiles * 1609.34 // Convert miles to meters
            
            return regionItem.center.latitude >= visibleBounds.minLat - buffer &&
                   regionItem.center.latitude <= visibleBounds.maxLat + buffer &&
                   regionItem.center.longitude >= visibleBounds.minLon - buffer &&
                   regionItem.center.longitude <= visibleBounds.maxLon + buffer
        }
        
        // Limit the number of regions to process
        let regionsToProcess = Array(visibleRegions.prefix(FogOverlay.maxRegionsToProcess))
        
        // Create interior polygons for each erased region
        var interiorPolygons: [MKPolygon] = []
        
        for erasedRegion in regionsToProcess {
            // Determine appropriate number of points based on zoom level
            let zoom = Double(region.span.latitudeDelta)
            let pointCount = FogOverlay.determinePointCount(for: zoom)
            
            // Create a circular polygon
            let circlePoints = FogOverlay.createCirclePoints(
                center: erasedRegion.center,
                radiusMiles: erasedRegion.radiusMiles,
                numPoints: pointCount
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
    
    /// Calculate the min and max bounds from a set of coordinates
    private static func calculateBounds(from coordinates: [CLLocationCoordinate2D]) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        
        return (
            minLat: lats.min() ?? -90,
            maxLat: lats.max() ?? 90,
            minLon: lons.min() ?? -180,
            maxLon: lons.max() ?? 180
        )
    }
    
    /// Determine appropriate number of points based on zoom level
    private static func determinePointCount(for zoomDelta: Double) -> Int {
        // Use appropriate level of detail based on zoom
        if zoomDelta > 50 {
            return 4  
        } else if zoomDelta > 10 {
            return 6  
        } else if zoomDelta > 1 {
            return 8  
        } else if zoomDelta > 0.1 {
            return 12
        } else {
            return 16
        }
    }
    
    /// Create points that approximate a circle for the given center and radius
    private static func createCirclePoints(center: CLLocationCoordinate2D, radiusMiles: Double, numPoints: Int) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []
        let radiusMeters = radiusMiles * 1609.34 // Convert miles to meters
        
        for i in 0..<numPoints {
            let angle = (Double(i) / Double(numPoints)) * 2.0 * .pi
            let dx = radiusMeters * cos(angle)
            let dy = radiusMeters * sin(angle)
            
            let point = calculateCoordinate(from: center, xMeters: dx, yMeters: dy)
            points.append(point)
        }
        
        return points
    }
    
    /// Calculate a new coordinate given a starting point and x/y offsets in meters
    private static func calculateCoordinate(from coordinate: CLLocationCoordinate2D, xMeters: Double, yMeters: Double) -> CLLocationCoordinate2D {
        // Earth's radius in meters
        let earthRadius = 6371000.0
        
        // Convert latitude and longitude to radians
        let lat = coordinate.latitude * .pi / 180
        let lon = coordinate.longitude * .pi / 180
        
        // Calculate new latitude
        let newLat = asin(sin(lat) * cos(yMeters/earthRadius) +
                         cos(lat) * sin(yMeters/earthRadius) * cos(0))
        
        // Calculate new longitude
        let newLon = lon + atan2(sin(xMeters/earthRadius) * cos(lat),
                                cos(yMeters/earthRadius) - sin(lat) * sin(newLat))
        
        // Convert back to degrees
        return CLLocationCoordinate2D(
            latitude: newLat * 180 / .pi,
            longitude: newLon * 180 / .pi
        )
    }
} 