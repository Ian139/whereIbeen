import Foundation
import CoreData
import CoreLocation
import Combine

class TripService: ObservableObject {
    private let locationService: LocationService
    private let context: NSManagedObjectContext
    private var currentTrip: Trip?
    private var locationSubscription: AnyCancellable?
    private var lastLocation: CLLocation?
    
    @Published var isTracking = false
    @Published var currentTripMiles: Double = 0
    
    init(locationService: LocationService, context: NSManagedObjectContext) {
        self.locationService = locationService
        self.context = context
    }
    
    // MARK: - Trip Management
    
    func startNewTrip(name: String, description: String? = nil, isPrivate: Bool = false) {
        // Create new trip
        let trip = Trip(context: context)
        trip.id = UUID()
        trip.name = name
        trip.description = description
        trip.isPrivate = isPrivate
        trip.startDate = Date()
        trip.totalMiles = 0
        trip.coordinates = []
        
        // Save context
        do {
            try context.save()
            currentTrip = trip
            startTracking()
        } catch {
            print("Error saving trip: \(error)")
        }
    }
    
    func endCurrentTrip() {
        guard let trip = currentTrip else { return }
        
        trip.endDate = Date()
        
        do {
            try context.save()
            stopTracking()
            currentTrip = nil
        } catch {
            print("Error ending trip: \(error)")
        }
    }
    
    // MARK: - Location Tracking
    
    private func startTracking() {
        isTracking = true
        currentTripMiles = 0
        lastLocation = nil
        
        // Start location updates
        locationService.start()
        
        // Subscribe to location updates
        locationSubscription = locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
    }
    
    private func stopTracking() {
        isTracking = false
        locationSubscription?.cancel()
        locationSubscription = nil
        lastLocation = nil
    }
    
    private func handleLocationUpdate(_ location: CLLocation) {
        guard let trip = currentTrip else { return }
        
        // Calculate distance if we have a previous location
        if let lastLoc = lastLocation {
            let distanceInMeters = location.distance(from: lastLoc)
            let distanceInMiles = distanceInMeters / 1609.34
            
            // Update trip stats
            currentTripMiles += distanceInMiles
            trip.totalMiles += distanceInMiles
            
            // Add new coordinate to trip
            var coordinates = trip.coordinates
            coordinates.append(location.coordinate)
            
            // Keep only last 1000 coordinates to prevent memory issues
            if coordinates.count > 1000 {
                coordinates = Array(coordinates.suffix(1000))
            }
            trip.coordinates = coordinates
            
            // Update region to encompass all coordinates
            trip.region = calculateRegion(for: coordinates)
            
            // Save changes
            do {
                try context.save()
            } catch {
                print("Error saving location update: \(error)")
            }
        }
        
        lastLocation = location
    }
    
    // MARK: - Helper Methods
    
    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        // Calculate the bounding box
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        // Calculate center
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate span with some padding
        let latDelta = (maxLat - minLat) * 1.1 // 10% padding
        let lonDelta = (maxLon - minLon) * 1.1
        
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        )
    }
    
    // MARK: - Trip Queries
    
    func getAllTrips() -> [Trip] {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching trips: \(error)")
            return []
        }
    }
    
    func getPublicTrips() -> [Trip] {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "isPrivate == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching public trips: \(error)")
            return []
        }
    }
} 