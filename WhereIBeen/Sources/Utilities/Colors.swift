import SwiftUI

// Color information storage
struct FogColorInfo {
    static var opacity: Double = 0.45
    static var hue: Double = 0.6
    static var saturation: Double = 0.8
    static var brightness: Double = 0.8
}

extension Color {
    /// Primary blue color used throughout the app - using Apple's system blue
    static let appBlue = Color.blue
    
    /// Secondary color used for progress indicators
    static let appGold = Color.white
    
    /// Background color for UI elements
    static let uiBackground = Color.black.opacity(0.7)
    
    /// Color for unexplored fog areas on the map
    static var fogColor: Color {
        Color(hue: FogColorInfo.hue, 
              saturation: FogColorInfo.saturation, 
              brightness: FogColorInfo.brightness, 
              opacity: FogColorInfo.opacity)
    }
    
    /// Border color for unexplored fog areas
    static var fogBorderColor: Color {
        Color(hue: FogColorInfo.hue, 
              saturation: FogColorInfo.saturation, 
              brightness: FogColorInfo.brightness, 
              opacity: min(FogColorInfo.opacity + 0.15, 1.0))
    }
    
    /// Update fog color settings
    static func updateFogColor(opacity: Double? = nil, hue: Double? = nil) {
        if let opacity = opacity {
            FogColorInfo.opacity = opacity
        }
        
        if let hue = hue {
            FogColorInfo.hue = hue
        }
    }
} 