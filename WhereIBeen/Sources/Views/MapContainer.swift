import SwiftUI
import MapKit

/// Container for the MapView that sets up the MKMapView reference
struct MapContainer: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    
    // Track previous values to avoid unnecessary updates
    class MapState {
        var lastRegion: MKCoordinateRegion?
        var lastOverlayCount: Int = 0
    }
    
    // Use UIViewRepresentableContext.Coordinator to store state
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapContainer
        var mapState = MapState()
        var isUpdating = false
        
        init(_ parent: MapContainer) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let fogOverlay = overlay as? FogOverlay {
                let renderer = MKPolygonRenderer(overlay: fogOverlay)
                
                // Use shared colors for consistent look
                let fogUIColor = UIColor(Color.fogColor)
                let fogBorderUIColor = UIColor(Color.fogBorderColor)
                
                renderer.fillColor = fogUIColor
                renderer.strokeColor = fogBorderUIColor
                renderer.lineWidth = 1
                return renderer
            } else if let polygon = overlay as? MKPolygon {
                // For simplified overlays
                let renderer = MKPolygonRenderer(overlay: polygon)
                
                // Use shared colors for consistent look
                let fogUIColor = UIColor(Color.fogColor)
                let fogBorderUIColor = UIColor(Color.fogBorderColor)
                
                renderer.fillColor = fogUIColor
                renderer.strokeColor = fogBorderUIColor
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Throttle region change updates to prevent overload
            guard !isUpdating else { return }
            
            isUpdating = true
            
            // Use debounce technique for zoom operations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                
                self.parent.viewModel.handleRegionChange(mapView.region)
                self.isUpdating = false
            }
        }
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        viewModel.setMapView(mapView)
        
        // Configure the map
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        mapView.isPitchEnabled = false
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let coordinator = context.coordinator
        
        // Only update region if it has changed significantly (avoid constant small updates)
        if shouldUpdateRegion(mapView.region, viewModel.region, context) {
            mapView.setRegion(viewModel.region, animated: true)
            coordinator.mapState.lastRegion = viewModel.region
        }
        
        // Check if we need to update the overlay
        let overlayCount = viewModel.erasedRegions.count
        if overlayCount != coordinator.mapState.lastOverlayCount || 
           coordinator.mapState.lastRegion?.span.latitudeDelta != viewModel.region.span.latitudeDelta {
            // Update fog overlay
            mapView.overlays.forEach { mapView.removeOverlay($0) }
            let fogOverlay = viewModel.createFogOverlay()
            mapView.addOverlay(fogOverlay)
            coordinator.mapState.lastOverlayCount = overlayCount
        }
    }
    
    private func shouldUpdateRegion(_ current: MKCoordinateRegion, _ new: MKCoordinateRegion, _ context: Context) -> Bool {
        let coordinator = context.coordinator
        guard let lastRegion = coordinator.mapState.lastRegion else { 
            return true // First time, always update
        }
        
        // Check if the change is significant enough to warrant an update
        let latDiff = abs(current.center.latitude - new.center.latitude)
        let lngDiff = abs(current.center.longitude - new.center.longitude)
        let spanLatDiff = abs(current.span.latitudeDelta - new.span.latitudeDelta)
        let spanLngDiff = abs(current.span.longitudeDelta - new.span.longitudeDelta)
        
        let threshold = 0.0001 // Small threshold to avoid unnecessary updates
        
        return latDiff > threshold || 
               lngDiff > threshold || 
               spanLatDiff > threshold || 
               spanLngDiff > threshold
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
} 