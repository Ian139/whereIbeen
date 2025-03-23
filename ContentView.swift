import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        ZStack {
            MapView(region: $viewModel.region,
                   erasedArea: $viewModel.erasedArea,
                   onRegionChange: viewModel.handleRegionChange)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                HStack {
                    // Percentage View
                    Text(String(format: "%.4f%%", viewModel.percentExplored))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Reset Button
                    Button(action: viewModel.resetMap) {
                        Text("Reset Map")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }
}

// Custom MapView using UIViewRepresentable
struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var erasedArea: [CLLocationCoordinate2D]
    var onRegionChange: (MKCoordinateRegion) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsUserLocation = false
        mapView.isPitchEnabled = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Update fog overlay
        mapView.overlays.forEach { mapView.removeOverlay($0) }
        let fogOverlay = FogOverlay(region: region, erasedArea: erasedArea)
        mapView.addOverlay(fogOverlay)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
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
            parent.onRegionChange(mapView.region)
        }
    }
}

// Custom Fog Overlay
class FogOverlay: MKPolygon {
    convenience init(region: MKCoordinateRegion, erasedArea: [CLLocationCoordinate2D]) {
        let padding = max(region.span.latitudeDelta, region.span.longitudeDelta) * 0.5
        
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
        
        if erasedArea.count >= 3 {
            self.init(coordinates: bounds, count: bounds.count, interiorPolygons: [MKPolygon(coordinates: erasedArea, count: erasedArea.count)])
        } else {
            self.init(coordinates: bounds, count: bounds.count)
        }
    }
}

// ViewModel
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.0922, longitudeDelta: 0.0421)
    )
    @Published var erasedArea: [CLLocationCoordinate2D] = []
    @Published var percentExplored: Double = 0
    
    private let minDelta: Double = 0.15
    private let maxDelta: Double = 100
    private let earthSurfaceArea: Double = 510100000 // km²
    
    func handleRegionChange(_ newRegion: MKCoordinateRegion) {
        // Enforce zoom limits
        var limitedRegion = newRegion
        limitedRegion.span.latitudeDelta = min(max(newRegion.span.latitudeDelta, minDelta), maxDelta)
        limitedRegion.span.longitudeDelta = min(max(newRegion.span.longitudeDelta, minDelta), maxDelta)
        
        if limitedRegion.span != newRegion.span {
            region = limitedRegion
        } else {
            region = newRegion
        }
        
        updateExploredPercentage(region)
    }
    
    func resetMap() {
        erasedArea = []
        percentExplored = 0
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            span: MKCoordinateSpan(latitudeDelta: 0.0922, longitudeDelta: 0.0421)
        )
    }
    
    private func updateExploredPercentage(_ region: MKCoordinateRegion) {
        let latDegrees = region.span.latitudeDelta
        let lngDegrees = region.span.longitudeDelta
        let centerLat = region.center.latitude
        
        let degreesToKm = 111.32
        let correction = cos(centerLat * .pi / 180)
        let visibleAreaKm = latDegrees * lngDegrees * degreesToKm * degreesToKm * correction
        
        percentExplored = min((visibleAreaKm / earthSurfaceArea) * 100, 100)
    }
} 