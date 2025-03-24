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
        
        // Get initial authorization status
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            // For iOS 13 and earlier
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
    }
    
    deinit {
        retryTimer?.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    /// Start location services - call this from your view model or controller
    func start() {
        // Don't check location services on main thread - wait for delegate callbacks instead
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            self.error = .authorizationDenied
            self.onError?(.authorizationDenied)
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized, start updating
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    /// Start updating location - only called after authorization is confirmed
    private func startLocationUpdates() {
        // Reset retry count
        retryCount = 0
        retryTimer?.invalidate()
        
        // Start standard location updates
        locationManager.startUpdatingLocation()
    }
    
    /// Stop updating location
    func stop() {
        locationManager.stopUpdatingLocation()
        retryTimer?.invalidate()
    }
    
    /// Check if location services are available and authorized
    func isLocationAvailable() -> Bool {
        // Don't check here, rely on the published authorizationStatus instead
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    /// Handle location unknown errors with progressive retry
    private func handleLocationUnknown() {
        retryCount += 1
        retryTimer?.invalidate()
        
        // Determine retry delay with exponential backoff
        let delay: TimeInterval
        if retryCount <= 2 {
            delay = 1.0
        } else {
            delay = min(pow(2.0, Double(retryCount - 2)), 30.0)
        }
        
        // Only show error if we've exceeded retry attempts
        if retryCount > maxRetries {
            self.error = .locationUnknown
            self.onError?(.locationUnknown)
        }
        
        // Schedule retry
        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, self.isLocationAvailable() else { return }
            self.locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out inaccurate locations
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 500 {
            if retryCount < maxRetries {
                handleLocationUnknown()
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
        
        // Update the current location
        currentLocation = location
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                self.error = .authorizationDenied
                onError?(.authorizationDenied)
            case .locationUnknown:
                handleLocationUnknown()
            default:
                if retryCount < maxRetries {
                    handleLocationUnknown()
                } else {
                    self.error = .unknown(error: clError)
                    onError?(.unknown(error: clError))
                }
            }
        } else {
            self.error = .unknown(error: error)
            onError?(.unknown(error: error))
        }
    }
    
    // iOS 14 and above
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Update authorization status
        authorizationStatus = manager.authorizationStatus
        
        // Handle the new authorization status
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Start location updates
            startLocationUpdates()
        case .denied, .restricted:
            stop()
            error = .authorizationDenied
            onError?(.authorizationDenied)
        case .notDetermined:
            // Wait for user's response
            break
        @unknown default:
            break
        }
    }
    
    // iOS 13 and below (deprecated in iOS 14)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if #available(iOS 14.0, *) {
            // Use the newer method above
            return
        }
        
        // Update authorization status
        authorizationStatus = status
        
        // Handle the new authorization status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Start location updates
            startLocationUpdates()
        case .denied, .restricted:
            stop()
            error = .authorizationDenied
            onError?(.authorizationDenied)
        case .notDetermined:
            // Wait for user's response
            break
        @unknown default:
            break
        }
    }
} 
