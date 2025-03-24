import Foundation
import CoreLocation
import Combine

/// Service for handling location-related functionality
class LocationService: NSObject, ObservableObject {
    // Published properties
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // Location manager
    private let locationManager = CLLocationManager()
    
    // Callback for location updates
    var onLocationUpdate: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        
        // Configure location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update when the user moves 10 meters
        locationManager.pausesLocationUpdatesAutomatically = false
        
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
        }
    }
    
    /// Request authorization to use location services
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start updating the user's location
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    /// Stop updating the user's location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Check if location services are enabled and authorized
    /// - Returns: Boolean indicating if location services are available
    func isLocationAvailable() -> Bool {
        return CLLocationManager.locationServicesEnabled() &&
               (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out inaccurate locations
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 100 else { return }
        
        currentLocation = location
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
} 
