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
            if let fogOverlay = overlay as? FogOverlay {
                let renderer = MKPolygonRenderer(overlay: fogOverlay)
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