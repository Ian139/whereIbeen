import MapKit

/// Custom overlay for the unexplored "fog of war" regions
class FogOverlay: MKPolygon {
    var region: MKCoordinateRegion?
    var erasedRegions: [ErasedRegion]?
    
    /// Create a fog overlay from a map region and erased regions
    /// - Parameters:
    ///   - region: The current map region
    ///   - erasedRegions: Regions that have been explored
    convenience init(region: MKCoordinateRegion, erasedRegions: [ErasedRegion]) {
        // Create the outer bounds of the region with some padding
        let padding = min(region.span.latitudeDelta, 1.0) * 0.5
        
        let outerCoordinates = [
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
        
        // Simplify the erasedRegions to just create circles for each
        // This is an optimization for rendering performance
        var interiorPolygons: [MKPolygon] = []
        for erasedRegion in erasedRegions {
            let circlePoints = Self.createCirclePoints(
                center: erasedRegion.center,
                radiusMiles: erasedRegion.radiusMiles,
                segments: 16 // Fewer segments for better performance
            )
            
            interiorPolygons.append(MKPolygon(coordinates: circlePoints, count: circlePoints.count))
        }
        
        // Initialize with the outer region and holes for erased regions
        self.init(
            coordinates: outerCoordinates,
            count: outerCoordinates.count,
            interiorPolygons: interiorPolygons
        )
        
        self.region = region
        self.erasedRegions = erasedRegions
    }
    
    /// Create a circle of coordinates for a given center and radius
    /// - Parameters:
    ///   - center: The center coordinate
    ///   - radiusMiles: Radius in miles
    ///   - segments: Number of segments to use (higher = smoother circle)
    /// - Returns: Array of coordinates forming a circle
    static func createCirclePoints(
        center: CLLocationCoordinate2D,
        radiusMiles: Double,
        segments: Int
    ) -> [CLLocationCoordinate2D] {
        let radiusMeters = radiusMiles * 1609.34 // Convert miles to meters
        
        var coordinates = [CLLocationCoordinate2D]()
        
        for i in 0...segments {
            let angle = (Double(i) * 2.0 * .pi) / Double(segments)
            let dx = radiusMeters * cos(angle)
            let dy = radiusMeters * sin(angle)
            
            let coordinate = CLLocationCoordinate2D(
                latitude: center.latitude + (dy / 111320), // 111320 meters per degree latitude
                longitude: center.longitude + (dx / (111320 * cos(center.latitude * .pi / 180)))
            )
            
            coordinates.append(coordinate)
        }
        
        return coordinates
    }
} 