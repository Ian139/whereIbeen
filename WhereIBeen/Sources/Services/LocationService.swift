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
            return "Location services are disabled on your device. Please enable them in Settings > Privacy > Location Services."
        case .authorizationDenied:
            return "You've denied location access for this app. Please go to Settings > Privacy > Location Services > WhereIBeen to enable it."
        case .authorizationRestricted:
            return "Location access is restricted, possibly due to parental controls. Please check your device settings."
        case .locationUnknown:
            return "Unable to determine your location at this time. Please ensure you have a clear view of the sky or try again later."
        case .accuracyTooLow(let accuracy):
            if accuracy < 0 {
                return "Your current location is invalid. Please ensure you have a clear view of the sky and try again."
            } else {
                return "Your current location has low accuracy (\(Int(accuracy))m). Try moving to an open area for better GPS signal."
            }
        case .unknown(let error):
            return "Location error: \(error.localizedDescription). Please try again."
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
    private var retryCount = 0
    private let maxRetries = 3
    private var retryTimer: Timer?
    
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
        
        // Initial authorization status check
        authorizationStatus = locationManager.authorizationStatus
    }
    
    deinit {
        retryTimer?.invalidate()
    }
    
    /// Request authorization to use location services
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start updating the user's location
    func startUpdatingLocation() {
        // Reset retry count when starting
        retryCount = 0
        
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
    
    /// Retry location updates after a delay
    private func scheduleRetry() {
        guard retryCount < maxRetries else {
            // Max retries reached, send the error
            let error = LocationServiceError.locationUnknown
            self.error = error
            onError?(error)
            return
        }
        
        retryCount += 1
        retryTimer?.invalidate()
        
        // Retry after a short delay
        retryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.locationManager.startUpdatingLocation()
        }
    }
    
    /// Stop updating the user's location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        retryTimer?.invalidate()
        retryTimer = nil
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
        guard let location = locations.last else { 
            scheduleRetry()
            return 
        }
        
        // Be more lenient with accuracy - only reject extremely inaccurate locations
        // Negative accuracy means the location is invalid
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 500 {
            if retryCount < maxRetries {
                scheduleRetry()
            } else {
                let error = LocationServiceError.accuracyTooLow(accuracy: location.horizontalAccuracy)
                self.error = error
                onError?(error)
            }
            return
        }
        
        // Reset retry count on success
        retryCount = 0
        retryTimer?.invalidate()
        
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
        // For transient errors, retry a few times
        if let clError = error as? CLError, clError.code == .locationUnknown {
            if retryCount < maxRetries {
                scheduleRetry()
                return
            }
        }
        
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
