import MapKit
import Foundation

/// Custom fog overlay for the map
public class FogOverlay: MKPolygon {
    public convenience init(region: MKCoordinateRegion, erasedRegions: [ErasedRegion]) {
        // Create a rectangle that covers the visible map area
        let padding = min(region.span.latitudeDelta, 10.0) * 0.5
        
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
        
        // Create a simple overlay by default
        self.init(coordinates: bounds, count: bounds.count)
    }
} 