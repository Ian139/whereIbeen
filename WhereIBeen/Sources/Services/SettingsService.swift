import SwiftUI
import MapKit
import Combine

/// Service for managing app settings
class SettingsService: ObservableObject {
    // Singleton instance
    static let shared = SettingsService()
    
    // Published properties for settings
    @Published var fogOpacity: Double = 0.35  // More transparent
    
    // UserDefaults keys
    private enum Keys {
        static let fogOpacity = "fogOpacity"
    }
    
    // Publishers
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load settings from UserDefaults
        loadSettings()
        
        // Set up observers
        setupObservers()
        
        // Listen for AppStorage changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func userDefaultsDidChange() {
        DispatchQueue.main.async {
            self.loadSettings()
        }
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        if let opacity = defaults.object(forKey: Keys.fogOpacity) as? Double {
            fogOpacity = opacity
        }
    }
    
    private func setupObservers() {
        // Save settings when they change
        $fogOpacity
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.fogOpacity)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Color extension for fog colors
extension Color {
    static var fogColor: Color {
        Color.blue.opacity(SettingsService.shared.fogOpacity)
    }
    
    static var fogBorderColor: Color {
        Color.blue.opacity(min(SettingsService.shared.fogOpacity + 0.15, 1.0))
    }
} 