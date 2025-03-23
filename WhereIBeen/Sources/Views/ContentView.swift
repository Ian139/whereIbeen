import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var isExploring = false
    
    var body: some View {
        ZStack {
            // Map
            MapContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            
            // UI Overlay
            VStack {
                // Top controls
                HStack {
                    Spacer()
                    
                    // Toggle for following user
                    if viewModel.userLocation != nil {
                        FollowUserButton(
                            isFollowing: viewModel.isFollowingUser,
                            action: viewModel.toggleFollowUser
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
                
                // Bottom controls
                HStack {
                    // Percentage View
                    ExplorationPercentageView(percentage: viewModel.percentExplored)
                    
                    Spacer()
                    
                    // Control buttons
                    HStack(spacing: 12) {
                        if isExploring {
                            // Stop Exploring Button
                            StopExploringButton {
                                stopExploring()
                            }
                        } else {
                            // Start Exploring Button
                            StartExploringButton {
                                startExploring()
                            }
                        }
                        
                        // Reset Button
                        ResetButton(action: viewModel.resetMap)
                    }
                }
                .padding()
            }
        }
    }
    
    // Move actions outside of the view body to avoid SwiftUI warnings
    private func startExploring() {
        isExploring = true
        viewModel.startExploration()
    }
    
    private func stopExploring() {
        isExploring = false
        viewModel.stopExploration()
    }
}

/// Container for the MapView that sets up the MKMapView reference
struct MapContainer: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        viewModel.setMapView(mapView)
        
        // Configure the map
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        mapView.isPitchEnabled = false
        mapView.delegate = context.coordinator
        
        // Add gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(panGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(viewModel.region, animated: true)
        
        // Update fog overlay
        mapView.overlays.forEach { mapView.removeOverlay($0) }
        let fogOverlay = viewModel.createFogOverlay()
        mapView.addOverlay(fogOverlay)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapContainer
        
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
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.viewModel.handleRegionChange(mapView.region)
        }
        
        @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
            if gestureRecognizer.state == .changed || gestureRecognizer.state == .ended {
                let location = gestureRecognizer.location(in: gestureRecognizer.view)
                parent.viewModel.handleMapTouch(at: location)
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
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

/// Button to reset the map exploration
struct ResetButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Reset")
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
        }
    }
}

/// Button to start exploring
struct StartExploringButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Start Exploring")
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.8))
                .cornerRadius(8)
        }
    }
}

/// Button to stop exploring
struct StopExploringButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Stop Exploring")
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.8))
                .cornerRadius(8)
        }
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
    }
}

#Preview {
    ContentView()
} 