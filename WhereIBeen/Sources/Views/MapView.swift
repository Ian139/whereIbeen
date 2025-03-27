import SwiftUI
import MapKit

/// A SwiftUI wrapper for MKMapView with custom overlay rendering
struct MapView: UIViewRepresentable {
    // Bindings
    @Binding var region: MKCoordinateRegion
    @Binding var exploredArea: [CLLocationCoordinate2D]
    
    // Callbacks
    var onRegionChange: (MKCoordinateRegion) -> Void
    var fogOverlayProvider: () -> MKPolygon
    var onMapTouch: (CGPoint) -> Void
    
    /// Create the UIKit view (MKMapView)
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Configure map settings
        mapView.showsCompass = false
        mapView.showsUserLocation = false
        mapView.isPitchEnabled = false
        
        // Add a gesture recognizer for drag gestures
        let panGestureRecognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePanGesture(_:)))
        panGestureRecognizer.delegate = context.coordinator
        mapView.addGestureRecognizer(panGestureRecognizer)
        
        // Add accessibility
        configureAccessibility(mapView)
        
        return mapView
    }
    
    /// Update the UIKit view when SwiftUI state changes
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update the region
        mapView.setRegion(region, animated: true)
        
        // Update fog overlay
        mapView.overlays.forEach { mapView.removeOverlay($0) }
        let fogOverlay = fogOverlayProvider()
        mapView.addOverlay(fogOverlay)
        
        // Update accessibility value to reflect current exploration percentage
        updateAccessibilityValue(mapView)
    }
    
    /// Configure accessibility for the map view
    private func configureAccessibility(_ mapView: MKMapView) {
        mapView.isAccessibilityElement = true
        mapView.accessibilityLabel = "Exploration map"
        mapView.accessibilityHint = "Shows your explored areas with a blue fog overlay for unexplored regions. Double tap and hold to explore an area."
    }
    
    /// Update the accessibility value with current exploration info
    private func updateAccessibilityValue(_ mapView: MKMapView) {
        // Calculate approximate explored percentage for accessibility
        let exploredPercentage = calculateExploredPercentage()
        mapView.accessibilityValue = String(format: "%.2f percent of the world explored", exploredPercentage)
    }
    
    /// Calculate an approximate percentage for accessibility information
    private func calculateExploredPercentage() -> Double {
        // Use the number of explored coordinates as a simple approximation
        // A more accurate calculation would come from the viewModel, but this is just for accessibility
        let maxCoordinates = MapArea.maxCoordinatesStored
        let currentCoordinates = exploredArea.count
        
        return min(Double(currentCoordinates) / Double(maxCoordinates) * 100, 100)
    }
    
    /// Create a coordinator to handle delegate methods
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator class to handle MKMapViewDelegate methods and gestures
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        /// Provide renderers for map overlays
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(overlay: polygon)
                renderer.fillColor = UIColor(red: 0, green: 0.31, blue: 0.78, alpha: 0.45)
                renderer.strokeColor = UIColor(red: 0, green: 0.31, blue: 0.78, alpha: 0.6)
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        /// Notify when the map region changes
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.onRegionChange(mapView.region)
        }
        
        /// Handle pan gesture for erasing areas
        @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
            if gestureRecognizer.state == .changed || gestureRecognizer.state == .ended {
                let location = gestureRecognizer.location(in: gestureRecognizer.view)
                parent.onMapTouch(location)
            }
        }
        
        /// Allow the pan gesture to work alongside map panning
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
} 