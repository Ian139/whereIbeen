import SwiftUI
import MapKit
import Combine
import CoreLocation

class MapViewModel: ObservableObject {
    // Published properties that the View can observe
    @Published var mapArea = MapArea()
    
    // Services
    private let mapOverlayService = MapOverlayService()
    private let locationService = LocationService()
    
    // Map view reference for coordinate conversion
    private weak var mapView: MKMapView?
    
    // Timer for auto-erasing based on location
    private var autoErasingTimer: Timer?
    private var locationUpdateSubscription: AnyCancellable?
    
    // Computed properties
    var region: MKCoordinateRegion {
        get { mapArea.currentRegion }
        set { mapArea.currentRegion = newValue }
    }
    
    var exploredArea: [CLLocationCoordinate2D] {
        get { mapArea.exploredCoordinates }
        set { mapArea.exploredCoordinates = newValue }
    }
    
    var erasedRegions: [ErasedRegion] {
        get { mapArea.erasedRegions }
        set { mapArea.erasedRegions = newValue }
    }
    
    var percentExplored: Double {
        get { mapArea.percentExplored }
        set { mapArea.percentExplored = newValue }
    }
    
    var isFollowingUser: Bool {
        get { mapArea.isFollowingUser }
        set { mapArea.isFollowingUser = newValue }
    }
    
    var userLocation: CLLocationCoordinate2D? {
        get { mapArea.userLocation }
        set { mapArea.userLocation = newValue }
    }
    
    var isLocationAvailable: Bool {
        locationService.isLocationAvailable()
    }
    
    init() {
        // Initialize services first
        setupLocationServices()
    }
    
    /// Set up location services and subscriptions
    private func setupLocationServices() {
        // Subscribe to location updates
        locationUpdateSubscription = locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
        
        // Set up location update callback
        locationService.onLocationUpdate = { [weak self] location in
            self?.handleLocationUpdate(location)
        }
    }
    
    /// Set the reference to the MKMapView
    /// - Parameter mapView: The MKMapView instance
    func setMapView(_ mapView: MKMapView) {
        self.mapView = mapView
    }
    
    /// Start location services and exploration tracking
    func startExploration() {
        locationService.requestLocationAuthorization()
        
        if locationService.isLocationAvailable() {
            locationService.startUpdatingLocation()
            startAutoErasing()
        }
    }
    
    /// Stop location services and exploration tracking
    func stopExploration() {
        locationService.stopUpdatingLocation()
        stopAutoErasing()
    }
    
    /// Toggle following the user's location
    func toggleFollowUser() {
        isFollowingUser.toggle()
        
        if isFollowingUser, let _ = userLocation {
            centerOnUser()
        }
    }
    
    /// Center the map on the user's current location
    func centerOnUser() {
        if let updatedRegion = mapArea.centerOnUserLocation() {
            region = updatedRegion
        }
    }
    
    /// Handle changes to the map region
    /// - Parameter newRegion: The new region after user interaction
    func handleRegionChange(_ newRegion: MKCoordinateRegion) {
        // Enforce zoom limits
        var limitedRegion = newRegion
        limitedRegion.span.latitudeDelta = min(max(newRegion.span.latitudeDelta, MapArea.minZoomDelta), MapArea.maxZoomDelta)
        limitedRegion.span.longitudeDelta = min(max(newRegion.span.longitudeDelta, MapArea.minZoomDelta), MapArea.maxZoomDelta)
        
        // Compare span values individually instead of using != operator
        if limitedRegion.span.latitudeDelta != newRegion.span.latitudeDelta || 
           limitedRegion.span.longitudeDelta != newRegion.span.longitudeDelta {
            region = limitedRegion
        } else {
            region = newRegion
        }
        
        // Update the explored percentage based on erased area
        updateExploredPercentage()
    }
    
    /// Handle a touch event on the map
    /// - Parameter screenPoint: The point on the screen where the touch occurred
    func handleMapTouch(at screenPoint: CGPoint) {
        guard let mapView = mapView else { return }
        
        let coordinate = mapView.convert(screenPoint, toCoordinateFrom: mapView)
        addErasedRegion(at: coordinate, withRadius: MapArea.manualEraserRadiusMiles)
    }
    
    /// Handle location update from the location service
    /// - Parameter location: The updated location
    private func handleLocationUpdate(_ location: CLLocation) {
        let coordinate = location.coordinate
        userLocation = coordinate
        
        // Auto-center on user if following is enabled
        if isFollowingUser {
            centerOnUser()
        }
        
        // Add erased region at the user's location
        addErasedRegion(at: coordinate, withRadius: MapArea.autoEraserRadiusMiles)
    }
    
    /// Start the timer for automatic erasing based on user location
    private func startAutoErasing() {
        autoErasingTimer = Timer.scheduledTimer(withTimeInterval: MapArea.autoErasingInterval, repeats: true) { [weak self] _ in
            guard let self = self, let location = self.userLocation else { return }
            self.addErasedRegion(at: location, withRadius: MapArea.autoEraserRadiusMiles)
        }
    }
    
    /// Stop the automatic erasing timer
    private func stopAutoErasing() {
        autoErasingTimer?.invalidate()
        autoErasingTimer = nil
    }
    
    /// Add a new erased region at the specified coordinate
    /// - Parameters:
    ///   - coordinate: The center coordinate of the region to erase
    ///   - radius: The radius of the region in miles
    func addErasedRegion(at coordinate: CLLocationCoordinate2D, withRadius radius: Double) {
        let newRegion = ErasedRegion(
            center: coordinate,
            radiusMiles: radius
        )
        
        // Only add if we don't already have a very similar region
        // This helps prevent too many overlapping regions
        let isNearlySame = erasedRegions.contains { existingRegion in
            let distance = calculateDistance(from: existingRegion.center, to: coordinate)
            return distance < (radius * 1609.34 * 0.5) // If within half the radius
        }
        
        if !isNearlySame {
            erasedRegions.append(newRegion)
            updateExploredPercentage()
        }
    }
    
    /// Calculate distance between two coordinates in meters
    /// - Parameters:
    ///   - source: The source coordinate
    ///   - destination: The destination coordinate
    /// - Returns: Distance in meters
    private func calculateDistance(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let sourceLocation = CLLocation(latitude: source.latitude, longitude: source.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return sourceLocation.distance(from: destinationLocation)
    }
    
    /// Reset the map to its default state
    func resetMap() {
        erasedRegions = []
        exploredArea = []
        percentExplored = 0
        region = MapArea.defaultRegion
    }
    
    /// Create a fog overlay for the map
    /// - Returns: A polygon representing the fog overlay
    func createFogOverlay() -> MKPolygon {
        return mapOverlayService.createFogOverlay(region: region, erasedRegions: erasedRegions)
    }
    
    /// Update the percentage of the world that has been explored
    private func updateExploredPercentage() {
        let totalErasedArea = mapArea.calculateErasedArea()
        percentExplored = mapOverlayService.calculateExploredPercentage(erasedArea: totalErasedArea)
    }
} 