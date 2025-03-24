import Foundation
import CoreLocation
import Combine

/// Error types for location service
enum LocationServiceError: Error, LocalizedError {
    case locationServicesDisabled
    case authorizationDenied
    case authorizationRestricted
    case locationUnknown
    case accuracyTooLow(accuracy: CLLocationAccuracy)
    case unknown(error: Error)
    
    var errorDescription: String? {
        switch self {
        case .locationServicesDisabled:
            return "Location services are disabled"
        case .authorizationDenied:
            return "Location access has been denied"
        case .authorizationRestricted:
            return "Location access is restricted"
        case .locationUnknown:
            return "Unable to determine your location"
        case .accuracyTooLow(let accuracy):
            return "Location accuracy too low: \(accuracy)m"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

/// Service for handling location-related functionality
class LocationService: NSObject, ObservableObject {
    // Published properties
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: LocationServiceError?
    
    // Location manager
    private let locationManager = CLLocationManager()
    
    // Callback for location updates
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onError: ((LocationServiceError) -> Void)?
    
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
        if !CLLocationManager.locationServicesEnabled() {
            let error = LocationServiceError.locationServicesDisabled
            self.error = error
            onError?(error)
            return
        }
        
        switch authorizationStatus {
        case .denied:
            let error = LocationServiceError.authorizationDenied
            self.error = error
            onError?(error)
        case .restricted:
            let error = LocationServiceError.authorizationRestricted
            self.error = error
            onError?(error)
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            requestLocationAuthorization()
        }
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
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 100 {
            let error = LocationServiceError.accuracyTooLow(accuracy: location.horizontalAccuracy)
            self.error = error
            onError?(error)
            return
        }
        
        // Clear any previous errors
        if error != nil {
            error = nil
        }
        
        currentLocation = location
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied:
            let error = LocationServiceError.authorizationDenied
            self.error = error
            onError?(error)
        case .restricted:
            let error = LocationServiceError.authorizationRestricted
            self.error = error
            onError?(error)
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let locationError: LocationServiceError
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .authorizationDenied
            case .locationUnknown:
                locationError = .locationUnknown
            default:
                locationError = .unknown(error: clError)
            }
        } else {
            locationError = .unknown(error: error)
        }
        
        self.error = locationError
        onError?(locationError)
        print("Location manager failed with error: \(error.localizedDescription)")
    }
} 
