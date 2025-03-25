import Foundation

/// Error types for location services
public enum LocationServiceError: Error {
    case locationServicesDisabled
    case authorizationDenied
    case authorizationRestricted
    case unknown
    
    public var localizedDescription: String {
        switch self {
        case .locationServicesDisabled:
            return "Location services are disabled on your device. Please enable them in Settings."
        case .authorizationDenied:
            return "Location access has been denied. Please allow access in Settings."
        case .authorizationRestricted:
            return "Location access is restricted, possibly due to parental controls."
        case .unknown:
            return "An unknown error occurred with location services."
        }
    }
} 