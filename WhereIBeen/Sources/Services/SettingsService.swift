import SwiftUI
import MapKit
import Combine

/// Service for managing app settings
class SettingsService: ObservableObject {
    // Singleton instance
    static let shared = SettingsService()
    
    // Published properties for settings
    @Published var mapType: MKMapType = .standard
    @Published var fogOpacity: Double = 0.45
    @Published var fogColorHue: Double = 0.6
    
    // UserDefaults keys
    private enum Keys {
        static let mapType = "mapType"
        static let fogOpacity = "fogOpacity"
        static let fogColorHue = "fogColorHue"
    }
    
    // Publishers
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load settings from UserDefaults
        loadSettings()
        
        // Set up observers
        setupObservers()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Map type (stored as Int, convert to MKMapType)
        if let mapTypeInt = defaults.object(forKey: Keys.mapType) as? Int {
            switch mapTypeInt {
            case 0:
                mapType = .standard
            case 1:
                mapType = .satellite
            case 2:
                mapType = .hybrid
            default:
                mapType = .standard
            }
        }
        
        if let opacity = defaults.object(forKey: Keys.fogOpacity) as? Double {
            fogOpacity = opacity
        }
        
        if let hue = defaults.object(forKey: Keys.fogColorHue) as? Double {
            fogColorHue = hue
        }
    }
    
    private func setupObservers() {
        // Save settings when they change
        $mapType
            .sink { [weak self] newValue in
                let mapTypeInt: Int
                switch newValue {
                case .standard:
                    mapTypeInt = 0
                case .satellite:
                    mapTypeInt = 1
                case .hybrid:
                    mapTypeInt = 2
                default:
                    mapTypeInt = 0
                }
                UserDefaults.standard.set(mapTypeInt, forKey: Keys.mapType)
            }
            .store(in: &cancellables)
        
        $fogOpacity
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.fogOpacity)
            }
            .store(in: &cancellables)
        
        $fogColorHue
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.fogColorHue)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Color extension for fog colors
extension Color {
    static var fogColor: Color {
        Color(
            hue: SettingsService.shared.fogColorHue,
            saturation: 0.8,
            brightness: 0.8,
            opacity: SettingsService.shared.fogOpacity
        )
    }
    
    static var fogBorderColor: Color {
        Color(
            hue: SettingsService.shared.fogColorHue,
            saturation: 0.8,
            brightness: 0.7,
            opacity: min(SettingsService.shared.fogOpacity + 0.15, 1.0)
        )
    }
} 