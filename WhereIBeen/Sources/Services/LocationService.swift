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
    private let maxRetries = 5
    private var retryTimer: Timer?
    
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
        // Reset error state when starting
        self.error = nil
        
        // Request authorization based on current status
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            self.error = .authorizationRestricted
        case .denied:
            self.error = .authorizationDenied
        case .authorizedWhenInUse, .authorizedAlways:
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
        
        // Stop updates first to ensure a clean start
        locationManager.stopUpdatingLocation()
        
        // Configure for high accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness // More aggressive tracking
        
        // Start standard location updates
        locationManager.startUpdatingLocation()
        
        // Start a backup timer in case we don't get any location update
        retryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self, self.currentLocation == nil else { return }
            // If we haven't received a location after 5 seconds, try again
            self.handleLocationUnknown()
        }
    }
    
    /// Stop updating location
    func stop() {
        locationManager.stopUpdatingLocation()
        retryTimer?.invalidate()
    }
    
    /// Check if location services are available and authorized
    func isLocationAvailable() -> Bool {
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
        }
        
        // Schedule retry with more aggressive settings
        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, self.isLocationAvailable() else { return }
            // Stop updates first
            self.locationManager.stopUpdatingLocation()
            
            // Try with different accuracy if we're having trouble
            if self.retryCount > 2 {
                self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            }
            
            // Restart location updates
            self.locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Relax accuracy requirements if we're having trouble
        let accuracyThreshold = retryCount > 2 ? 1000.0 : 500.0
        
        // Filter out inaccurate locations
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > accuracyThreshold {
            if retryCount < maxRetries {
                handleLocationUnknown()
            } else {
                error = .accuracyTooLow(accuracy: location.horizontalAccuracy)
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
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                self.error = .authorizationDenied
            case .locationUnknown:
                handleLocationUnknown()
            default:
                if retryCount < maxRetries {
                    handleLocationUnknown()
                } else {
                    self.error = .unknown(error: clError)
                }
            }
        } else {
            self.error = .unknown(error: error)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Update authorization status
        if #available(iOS 14.0, *) {
            authorizationStatus = manager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        // Handle the new authorization status
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Start location updates
            startLocationUpdates()
        case .denied, .restricted:
            stop()
            error = .authorizationDenied
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
        case .notDetermined:
            // Wait for user's response
            break
        @unknown default:
            break
        }
    }
} 
