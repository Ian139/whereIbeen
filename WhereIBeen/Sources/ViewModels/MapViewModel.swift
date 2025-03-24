import SwiftUI
import MapKit
import Combine
import CoreLocation

class MapViewModel: ObservableObject {
    // Published properties that the View can observe
    @Published var mapArea = MapArea()
    
    // Error publishers
    private let locationErrorSubject = PassthroughSubject<LocationServiceError, Never>()
    var locationErrorPublisher: AnyPublisher<LocationServiceError, Never> {
        locationErrorSubject.eraseToAnyPublisher()
    }
    
    // Location restored publisher
    private let locationRestoredSubject = PassthroughSubject<Void, Never>()
    var locationRestoredPublisher: AnyPublisher<Void, Never> {
        locationRestoredSubject.eraseToAnyPublisher()
    }
    
    // Services
    private let mapOverlayService: MapOverlayService
    private let locationService: LocationService
    
    // Map view reference for coordinate conversion
    private weak var mapView: MKMapView?
    
    // Timer for auto-erasing based on location
    private var autoErasingTimer: Timer?
    private var locationUpdateSubscription: AnyCancellable?
    private var errorSubscription: AnyCancellable?
    private var locationSubscription: AnyCancellable?
    
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
    
    // Initialize with dependency injection
    init(mapOverlayService: MapOverlayService = MapOverlayService(), 
         locationService: LocationService = LocationService()) {
        self.mapOverlayService = mapOverlayService
        self.locationService = locationService
        
        // Initialize services
        setupLocationServices()
        setupErrorHandling()
        
        // Start location tracking immediately
        startExploration()
    }
    
    deinit {
        stopAutoErasing()
        locationService.stopUpdatingLocation()
        locationUpdateSubscription?.cancel()
        errorSubscription?.cancel()
        locationSubscription?.cancel()
    }
    
    /// Set up location services and subscriptions
    private func setupLocationServices() {
        // Subscribe to location updates
        locationUpdateSubscription = locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
        
        // Listen for successful location updates
        locationSubscription = locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] _ in
                // When we get a valid location, notify that location services are restored
                self?.locationRestoredSubject.send()
            }
        
        // Set up location update callback
        locationService.onLocationUpdate = { [weak self] location in
            self?.handleLocationUpdate(location)
            self?.locationRestoredSubject.send()
        }
    }
    
    /// Set up error handling
    private func setupErrorHandling() {
        errorSubscription = locationService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.locationErrorSubject.send(error)
            }
        
        locationService.onError = { [weak self] error in
            self?.locationErrorSubject.send(error)
        }
    }
    
    /// Retry location services after an error
    func retryLocationServices() {
        startExploration()
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
        // Enforce zoom limits - use more restrictive limits to prevent performance issues
        var limitedRegion = newRegion
        
        // Set even stricter limits for very extreme zoom levels
        let minZoomDelta = MapArea.minZoomDelta // Keep the minimum (most zoomed in) limit as is
        let maxZoomDelta = 75.0 // Lower the maximum (most zoomed out) limit
        
        limitedRegion.span.latitudeDelta = min(max(newRegion.span.latitudeDelta, minZoomDelta), maxZoomDelta)
        limitedRegion.span.longitudeDelta = min(max(newRegion.span.longitudeDelta, minZoomDelta), maxZoomDelta)
        
        // Compare span values individually instead of using != operator
        if limitedRegion.span.latitudeDelta != newRegion.span.latitudeDelta || 
           limitedRegion.span.longitudeDelta != newRegion.span.longitudeDelta {
            region = limitedRegion
            
            // If we had to correct the zoom due to limits, add a small delay to prevent freezing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updateExploredPercentage()
            }
        } else {
            region = newRegion
            updateExploredPercentage()
        }
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
    private func addErasedRegion(at coordinate: CLLocationCoordinate2D, withRadius radius: Double) {
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
        
        // Don't stop location tracking after reset
        if let location = userLocation {
            centerOnUser()
        }
    }
    
    /// Create a fog overlay for the map
    /// - Returns: A polygon representing the fog overlay
    func createFogOverlay() -> MKPolygon {
        // If the zoom level is extreme, return a simplified overlay
        if region.span.latitudeDelta > 70 || region.span.latitudeDelta < 0.01 {
            return createSimplifiedFogOverlay()
        }
        
        return mapOverlayService.createFogOverlay(region: region, erasedRegions: erasedRegions)
    }
    
    /// Create a simplified fog overlay for extreme zoom levels
    /// - Returns: A simplified polygon with minimal detail
    private func createSimplifiedFogOverlay() -> MKPolygon {
        // Create a simple rectangle for the fog with no holes
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
        
        return MKPolygon(coordinates: bounds, count: bounds.count)
    }
    
    /// Update the percentage of the world that has been explored
    private func updateExploredPercentage() {
        let totalErasedArea = mapArea.calculateErasedArea()
        percentExplored = mapOverlayService.calculateExploredPercentage(erasedArea: totalErasedArea)
    }
} 