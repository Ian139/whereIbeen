import MapKit
import Foundation
import SwiftUI
import WhereIBeenShared

/// Service for managing map overlays
class MapOverlayService {
    
    /// Creates a fog overlay for the unexplored areas of the map
    /// - Parameters:
    ///   - region: The current map region
    ///   - erasedRegions: Array of regions that have been explored/erased
    /// - Returns: A fog overlay to be displayed on the map
    func createFogOverlay(region: MKCoordinateRegion, erasedRegions: [WhereIBeenErasedRegion]) -> MKPolygon {
        // Create the outer bounds with some padding
        let padding = min(region.span.latitudeDelta, 1.0) * 0.5
        
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
        
        // Create interior polygons for erased regions
        let interiorPolygons = erasedRegions.map { region -> MKPolygon in
            let center = region.center
            let radiusInDegrees = region.radiusMiles / 69.0 // Rough conversion from miles to degrees
            
            // Create a circle approximation using multiple points
            let numberOfPoints = 32
            var circlePoints: [CLLocationCoordinate2D] = []
            
            for i in 0...numberOfPoints {
                let angle = (Double(i) * 2.0 * .pi) / Double(numberOfPoints)
                let point = CLLocationCoordinate2D(
                    latitude: center.latitude + radiusInDegrees * cos(angle),
                    longitude: center.longitude + radiusInDegrees * sin(angle)
                )
                circlePoints.append(point)
            }
            
            return MKPolygon(coordinates: circlePoints, count: circlePoints.count)
        }
        
        if !interiorPolygons.isEmpty {
            return MKPolygon(coordinates: bounds, count: bounds.count, interiorPolygons: interiorPolygons)
        } else {
            return MKPolygon(coordinates: bounds, count: bounds.count)
        }
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