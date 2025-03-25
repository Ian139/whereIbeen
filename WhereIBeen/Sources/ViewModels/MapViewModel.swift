import SwiftUI
import MapKit
import Combine
import CoreLocation

/// Represents a cell in the exploration grid
struct GridCell: Hashable {
    let latIndex: Int
    let lonIndex: Int
}

class MapViewModel: ObservableObject {
    // Published properties that the View can observe
    @Published var mapArea = MapArea()
    @Published var totalMiles: Double = 0
    @Published var level: Int = 1
    @Published var squaresUntilNextLevel: Int = 100
    
    // Grid configuration
    private let gridSize: Double = 0.003 // approximately 0.207 miles at the equator
    private var exploredGridCells: Set<GridCell> = [] {
        didSet {
            // Update level when grid cells change
            let totalSquares = exploredGridCells.count
            let newLevel = max(1, (totalSquares / 100) + 1)
            if newLevel != level {
                level = newLevel
            }
            squaresUntilNextLevel = (level * 100) - totalSquares
        }
    }
    
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
    private var lastLocation: CLLocation?
    
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
        locationService.stop()
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
        // Use the new start method instead of requestLocationAuthorization
        locationService.start()
        
        if locationService.isLocationAvailable() {
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
        let maxZoomDelta = 75.0 // Lower the maximum (most zoomed out) limit
        
        // Only enforce maximum zoom out limit
        limitedRegion.span.latitudeDelta = min(newRegion.span.latitudeDelta, maxZoomDelta)
        limitedRegion.span.longitudeDelta = min(newRegion.span.longitudeDelta, maxZoomDelta)
        
        // Compare span values individually instead of using != operator
        if limitedRegion.span.latitudeDelta != newRegion.span.latitudeDelta || 
           limitedRegion.span.longitudeDelta != newRegion.span.longitudeDelta {
            region = limitedRegion
        } else {
            region = newRegion
        }
    }
    
    /// Handle location update from the location service
    /// - Parameter location: The updated location
    private func handleLocationUpdate(_ location: CLLocation) {
        let coordinate = location.coordinate
        userLocation = coordinate
        
        // Calculate distance traveled if we have a previous location
        if let lastLoc = lastLocation {
            let distanceInMeters = location.distance(from: lastLoc)
            let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
            totalMiles += distanceInMiles
        }
        lastLocation = location
        
        // Auto-center on user if following is enabled
        if isFollowingUser {
            centerOnUser()
        }
        
        // Add the current grid cell and surrounding cells
        addGridCellsAroundLocation(coordinate)
    }
    
    /// Add grid cells around a location to create a square exploration area
    /// - Parameter coordinate: The center coordinate
    private func addGridCellsAroundLocation(_ coordinate: CLLocationCoordinate2D) {
        // Calculate the center cell indices
        let latIndex = Int(floor(coordinate.latitude / gridSize))
        let lonIndex = Int(floor(coordinate.longitude / gridSize))
        
        // Add a 3x3 grid of cells centered on the current location
        // This creates a more natural exploration area around the user
        for dLat in -1...1 {
            for dLon in -1...1 {
                let cell = GridCell(latIndex: latIndex + dLat, lonIndex: lonIndex + dLon)
                exploredGridCells.insert(cell)
            }
        }
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
    ///   - radius: The radius of the region in miles (ignored, using grid cells instead)
    private func addErasedRegion(at coordinate: CLLocationCoordinate2D, withRadius radius: Double) {
        // Convert to grid-based exploration
        addGridCellsAroundLocation(coordinate)
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
        exploredGridCells = []
        totalMiles = 0
        level = 1
        squaresUntilNextLevel = 100
        region = MapArea.defaultRegion
        lastLocation = nil
        
        // Don't stop location tracking after reset
        if let location = userLocation {
            centerOnUser()
        }
    }
    
    /// Create a fog overlay for the map
    /// - Returns: A polygon representing the fog overlay
    func createFogOverlay() -> MKPolygon {
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
        
        // Calculate visible grid cell indices
        let minLat = bounds[0].latitude
        let maxLat = bounds[2].latitude
        let minLon = bounds[0].longitude
        let maxLon = bounds[2].longitude
        
        let minLatIndex = Int(floor(minLat / gridSize))
        let maxLatIndex = Int(floor(maxLat / gridSize))
        let minLonIndex = Int(floor(minLon / gridSize))
        let maxLonIndex = Int(floor(maxLon / gridSize))
        
        // Create square interior polygons for visible explored cells
        var interiorPolygons: [MKPolygon] = []
        
        for cell in exploredGridCells {
            // Only process cells that are visible in the current viewport
            if cell.latIndex >= minLatIndex && cell.latIndex <= maxLatIndex &&
               cell.lonIndex >= minLonIndex && cell.lonIndex <= maxLonIndex {
                
                // Convert grid indices back to coordinates
                let lat = Double(cell.latIndex) * gridSize
                let lon = Double(cell.lonIndex) * gridSize
                
                // Create square coordinates
                let squareCoords = [
                    CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    CLLocationCoordinate2D(latitude: lat, longitude: lon + gridSize),
                    CLLocationCoordinate2D(latitude: lat + gridSize, longitude: lon + gridSize),
                    CLLocationCoordinate2D(latitude: lat + gridSize, longitude: lon),
                    CLLocationCoordinate2D(latitude: lat, longitude: lon) // Close the polygon
                ]
                
                interiorPolygons.append(MKPolygon(coordinates: squareCoords, count: squareCoords.count))
            }
        }
        
        if !interiorPolygons.isEmpty {
            return MKPolygon(coordinates: bounds, count: bounds.count, interiorPolygons: interiorPolygons)
        } else {
            return MKPolygon(coordinates: bounds, count: bounds.count)
        }
    }
    
    /// Create coordinates for a square centered at a point
    private func createSquareCoordinates(center: CLLocationCoordinate2D, sideLength: Double) -> [CLLocationCoordinate2D] {
        // Convert meters to approximate degrees at this latitude
        let metersPerDegree = 111319.9 // approximate meters per degree at equator
        let latDelta = sideLength / metersPerDegree
        let lonDelta = sideLength / (metersPerDegree * cos(center.latitude * .pi / 180.0))
        
        return [
            CLLocationCoordinate2D(
                latitude: center.latitude - latDelta/2,
                longitude: center.longitude - lonDelta/2
            ),
            CLLocationCoordinate2D(
                latitude: center.latitude - latDelta/2,
                longitude: center.longitude + lonDelta/2
            ),
            CLLocationCoordinate2D(
                latitude: center.latitude + latDelta/2,
                longitude: center.longitude + lonDelta/2
            ),
            CLLocationCoordinate2D(
                latitude: center.latitude + latDelta/2,
                longitude: center.longitude - lonDelta/2
            )
        ]
    }
    
    /// Check if a coordinate is within the given bounds
    private func isCoordinateInBounds(_ coordinate: CLLocationCoordinate2D, bounds: [CLLocationCoordinate2D]) -> Bool {
        let minLat = min(bounds[0].latitude, bounds[1].latitude, bounds[2].latitude, bounds[3].latitude)
        let maxLat = max(bounds[0].latitude, bounds[1].latitude, bounds[2].latitude, bounds[3].latitude)
        let minLon = min(bounds[0].longitude, bounds[1].longitude, bounds[2].longitude, bounds[3].longitude)
        let maxLon = max(bounds[0].longitude, bounds[1].longitude, bounds[2].longitude, bounds[3].longitude)
        
        return coordinate.latitude >= minLat &&
               coordinate.latitude <= maxLat &&
               coordinate.longitude >= minLon &&
               coordinate.longitude <= maxLon
    }
} 