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
    // Maximum number of erased regions to include at once - reduced from 50 to 25
    private static let maxRegionsToProcess = 25
    
    convenience init(region: MKCoordinateRegion, erasedRegions: [ErasedRegion]) {
        // Create the outer bounds of the fog - don't make it too large
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
        
        // Filter regions that are visible in the current viewport (with padding)
        let visibleRegions = erasedRegions.filter { regionItem in
            FogOverlay.isCoordinateInVisibleArea(
                coordinate: regionItem.center,
                visibleArea: bounds,
                buffer: regionItem.radiusMiles * 1609.34 // Convert miles to meters
            )
        }
        
        // Limit the number of regions to process
        let regionsToProcess = Array(visibleRegions.prefix(FogOverlay.maxRegionsToProcess))
        
        // Adjust point count based on zoom level to prevent performance issues
        let zoom = Double(region.span.latitudeDelta)
        
        // Create interior polygons for each erased region (circle approximation)
        var interiorPolygons: [MKPolygon] = []
        
        for erasedRegion in regionsToProcess {
            // Determine appropriate number of points based on zoom level
            let pointCount = FogOverlay.determinePointCount(for: zoom, radiusMiles: erasedRegion.radiusMiles)
            
            // Create a circular polygon by approximating with points
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
    
    /// Determine if a coordinate is within or near the visible area
    private static func isCoordinateInVisibleArea(coordinate: CLLocationCoordinate2D, visibleArea: [CLLocationCoordinate2D], buffer: Double) -> Bool {
        guard visibleArea.count >= 4 else { return true } // Safety check
        
        let minLat = min(visibleArea[0].latitude, visibleArea[1].latitude, visibleArea[2].latitude, visibleArea[3].latitude)
        let maxLat = max(visibleArea[0].latitude, visibleArea[1].latitude, visibleArea[2].latitude, visibleArea[3].latitude)
        let minLng = min(visibleArea[0].longitude, visibleArea[1].longitude, visibleArea[2].longitude, visibleArea[3].longitude)
        let maxLng = max(visibleArea[0].longitude, visibleArea[1].longitude, visibleArea[2].longitude, visibleArea[3].longitude)
        
        // Convert buffer from meters to approximate degrees (very rough approximation)
        let bufferDegrees = buffer / 111000.0 // ~111km per degree at the equator
        
        return coordinate.latitude >= minLat - bufferDegrees &&
               coordinate.latitude <= maxLat + bufferDegrees &&
               coordinate.longitude >= minLng - bufferDegrees &&
               coordinate.longitude <= maxLng + bufferDegrees
    }
    
    /// Determine appropriate number of points based on zoom level
    private static func determinePointCount(for zoomDelta: Double, radiusMiles: Double) -> Int {
        // For very zoomed out views, use minimal points
        if zoomDelta > 50 {
            return 4  // Reduced from 6
        }
        // For mid-level zoom
        else if zoomDelta > 10 {
            return 6  // Reduced from 8
        }
        // For zoomed in views
        else if zoomDelta > 1 {
            return 8  // Reduced from 12
        }
        // For very zoomed in views
        else if zoomDelta > 0.1 {
            return 12  // Reduced from 16
        }
        // For extremely zoomed in, still cap at a reasonable number
        else {
            return 16  // Reduced from 24
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