import SwiftUI
import MapKit
import Combine
import CoreLocation
import WhereIBeenShared

/// Extension to make CLLocationCoordinate2D Codable
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

/// Represents a cell in the exploration grid
struct GridCell: Hashable, Codable {
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
            
            // Save grid cells whenever they change
            saveExploredGridCells()
        }
    }
    
    // Keys for UserDefaults
    private enum StorageKeys {
        static let gridCells = "exploredGridCells"
        static let totalMiles = "totalMiles"
        static let level = "level"
    }
    
    // Error and location restored publishers
    private let locationErrorSubject = PassthroughSubject<LocationServiceError, Never>()
    var locationErrorPublisher: AnyPublisher<LocationServiceError, Never> {
        locationErrorSubject.eraseToAnyPublisher()
    }
    
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
    private var subscriptions = Set<AnyCancellable>()
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
    
    var erasedRegions: [WhereIBeenErasedRegion] {
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
        
        // Load saved data before setting up subscriptions
        loadSavedData()
        
        // Handle any existing coordinate-based data from previous app versions
        syncGridCellsFromExploredArea()
        
        setupSubscriptions()
        startExploration()
    }
    
    deinit {
        stopAutoErasing()
        locationService.stop()
        subscriptions.forEach { $0.cancel() }
    }
    
    /// Load saved data from UserDefaults
    private func loadSavedData() {
        loadExploredGridCells()
        loadTotalMiles()
        
        // Sync exploration data from grid cells to ensure consistency
        syncExploredAreaFromGridCells()
    }
    
    /// Save explored grid cells to UserDefaults
    private func saveExploredGridCells() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(Array(exploredGridCells))
            UserDefaults.standard.set(data, forKey: StorageKeys.gridCells)
            
            // Sync with explored area to keep them consistent
            syncExploredAreaFromGridCells()
        } catch {
            print("Error saving grid cells: \(error)")
        }
    }
    
    /// Load explored grid cells from UserDefaults
    private func loadExploredGridCells() {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.gridCells) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let gridCells = try decoder.decode([GridCell].self, from: data)
            exploredGridCells = Set(gridCells)
        } catch {
            print("Error loading grid cells: \(error)")
        }
    }
    
    /// Save total miles to UserDefaults
    private func saveTotalMiles() {
        UserDefaults.standard.set(totalMiles, forKey: StorageKeys.totalMiles)
    }
    
    /// Load total miles from UserDefaults
    private func loadTotalMiles() {
        if let savedMiles = UserDefaults.standard.object(forKey: StorageKeys.totalMiles) as? Double {
            totalMiles = savedMiles
        }
    }
    
    /// Set up location services and subscriptions
    private func setupSubscriptions() {
        // Subscribe to location updates
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
                self?.locationRestoredSubject.send()
            }
            .store(in: &subscriptions)
        
        // Subscribe to location errors
        locationService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.locationErrorSubject.send(error)
            }
            .store(in: &subscriptions)
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
        // Enforce zoom limits to prevent performance issues
        var limitedRegion = newRegion
        let maxZoomDelta = 75.0
        
        limitedRegion.span.latitudeDelta = min(newRegion.span.latitudeDelta, maxZoomDelta)
        limitedRegion.span.longitudeDelta = min(newRegion.span.longitudeDelta, maxZoomDelta)
        
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
            
            // Save total miles when updated
            saveTotalMiles()
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
    
    /// Reset the map to its default state
    func resetMap() {
        // Clear both models
        erasedRegions = []
        exploredArea = []
        exploredGridCells = []
        totalMiles = 0
        level = 1
        squaresUntilNextLevel = 100
        region = MapArea.defaultRegion
        lastLocation = nil
        
        // Clear saved data
        UserDefaults.standard.removeObject(forKey: StorageKeys.gridCells)
        UserDefaults.standard.removeObject(forKey: StorageKeys.totalMiles)
        UserDefaults.standard.removeObject(forKey: StorageKeys.level)
        
        if userLocation != nil {
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
    
    /// Generate explored area coordinates from grid cells
    /// This syncs the grid-based exploration system with the coordinate-based API
    private func syncExploredAreaFromGridCells() {
        var coordinates: [CLLocationCoordinate2D] = []
        
        for cell in exploredGridCells {
            // Convert grid indices back to coordinates
            let lat = Double(cell.latIndex) * gridSize
            let lon = Double(cell.lonIndex) * gridSize
            
            // Add center point of the grid cell
            coordinates.append(CLLocationCoordinate2D(
                latitude: lat + (gridSize/2),
                longitude: lon + (gridSize/2)
            ))
        }
        
        // Limit to max coordinates if needed
        if coordinates.count > MapArea.maxCoordinatesStored {
            coordinates = Array(coordinates.suffix(MapArea.maxCoordinatesStored))
        }
        
        // Update explored area
        exploredArea = coordinates
    }
    
    /// Generate grid cells from explored area coordinates
    /// This ensures backward compatibility with any saved coordinates
    private func syncGridCellsFromExploredArea() {
        var cells = Set<GridCell>()
        
        for coordinate in exploredArea {
            // Calculate the cell indices
            let latIndex = Int(floor(coordinate.latitude / gridSize))
            let lonIndex = Int(floor(coordinate.longitude / gridSize))
            
            // Add the cell
            cells.insert(GridCell(latIndex: latIndex, lonIndex: lonIndex))
        }
        
        // Only update if there are cells to add
        if !cells.isEmpty {
            // Merge with existing cells
            exploredGridCells = exploredGridCells.union(cells)
        }
    }
    
    /// Export the exploration data for backup or sharing
    func exportExplorationData() -> Data? {
        struct ExplorationData: Codable {
            let gridCells: [GridCell]
            let totalMiles: Double
            let level: Int
        }
        
        let data = ExplorationData(
            gridCells: Array(exploredGridCells),
            totalMiles: totalMiles,
            level: level
        )
        
        do {
            let encoder = JSONEncoder()
            return try encoder.encode(data)
        } catch {
            print("Error exporting exploration data: \(error)")
            return nil
        }
    }
    
    /// Import exploration data from a backup or shared file
    /// - Parameter data: The data to import
    /// - Returns: Whether the import was successful
    func importExplorationData(_ data: Data) -> Bool {
        struct ExplorationData: Codable {
            let gridCells: [GridCell]
            let totalMiles: Double
            let level: Int
        }
        
        do {
            let decoder = JSONDecoder()
            let importedData = try decoder.decode(ExplorationData.self, from: data)
            
            // Update model with imported data
            exploredGridCells = Set(importedData.gridCells)
            totalMiles = importedData.totalMiles
            level = importedData.level
            squaresUntilNextLevel = (level * 100) - exploredGridCells.count
            
            // Sync with explored area
            syncExploredAreaFromGridCells()
            
            // Save to user defaults
            saveExploredGridCells()
            saveTotalMiles()
            
            return true
        } catch {
            print("Error importing exploration data: \(error)")
            return false
        }
    }
} 