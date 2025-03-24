import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showLocationErrorAlert = false
    @State private var errorMessage = ""
    @State private var showRetryButton = false
    
    var body: some View {
        ZStack {
            // Map
            MapContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            
            // UI Overlay
            VStack {
                Spacer()
                
                // Bottom controls
                HStack {
                    // Percentage View
                    ExplorationPercentageView(percentage: viewModel.percentExplored)
                    
                    Spacer()
                    
                    // Compass button to center on user's location
                    CompassButton(action: viewModel.centerOnUser)
                }
                .padding()
            }
            
            // Menu Overlay
            MenuView()
                .frame(maxHeight: .infinity, alignment: .top)
            
            // Error overlay for persistent errors
            if showRetryButton {
                VStack {
                    Text("Location Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    Button(action: {
                        viewModel.retryLocationServices()
                        // Don't dismiss the view yet until we get a successful location
                    }) {
                        Text("Retry")
                            .fontWeight(.medium)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.75))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }
        }
        .alert(isPresented: $showLocationErrorAlert) {
            Alert(
                title: Text("Location Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(viewModel.locationErrorPublisher) { error in
            errorMessage = error.localizedDescription
            
            // Determine if this is a persistent error that requires user action
            switch error {
            case .locationServicesDisabled, .authorizationDenied, .authorizationRestricted:
                showRetryButton = true
                showLocationErrorAlert = false
            default:
                // For transient errors, just show an alert
                if !showRetryButton {
                    showLocationErrorAlert = true
                }
            }
        }
        .onReceive(viewModel.locationRestoredPublisher) {
            // Hide error UI when location is restored
            showRetryButton = false
            showLocationErrorAlert = false
        }
    }
}

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
                renderer.fillColor = UIColor(red: 0, green: 0.31, blue: 0.78, alpha: 0.45)
                renderer.strokeColor = UIColor(red: 0, green: 0.31, blue: 0.78, alpha: 0.6)
                renderer.lineWidth = 1
                return renderer
            } else if let polygon = overlay as? MKPolygon {
                // For simplified overlays
                let renderer = MKPolygonRenderer(overlay: polygon)
                renderer.fillColor = UIColor(red: 0, green: 0.31, blue: 0.78, alpha: 0.45)
                renderer.strokeColor = UIColor(red: 0, green: 0.31, blue: 0.78, alpha: 0.6)
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

/// View showing the percentage of the world explored
struct ExplorationPercentageView: View {
    let percentage: Double
    
    var body: some View {
        Text(String(format: "%.4f%%", percentage))
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
    }
}

/// Compass button that centers the map on the user's location
struct CompassButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "location.north.fill")
                .foregroundColor(.white)
                .font(.system(size: 22))
                .padding(12)
                .background(Color.blue.opacity(0.8))
                .clipShape(Circle())
                .shadow(radius: 2)
        }
        .accessibilityLabel("Center on your location")
    }
}

/// Button to toggle following user location
struct FollowUserButton: View {
    let isFollowing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFollowing ? "location.fill" : "location")
                .foregroundColor(.white)
                .font(.system(size: 20))
                .padding(10)
                .background(Color.blue.opacity(0.8))
                .clipShape(Circle())
        }
        .accessibilityLabel(isFollowing ? "Stop following your location" : "Follow your location")
    }
}

#Preview {
    ContentView()
} 
