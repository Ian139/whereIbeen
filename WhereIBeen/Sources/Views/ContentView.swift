import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()
    
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
                    
                    // Compass button to center on user's location
                    CompassButton(action: viewModel.centerOnUser)
                }
                .padding()
            }
        }
        .overlay(
            // Reset button in the top-left corner as a small option
            VStack {
                HStack {
                    Button(action: viewModel.resetMap) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
        )
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
    
    class Coordinator: NSObject, MKMapViewDelegate {
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