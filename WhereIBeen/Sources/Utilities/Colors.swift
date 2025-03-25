import SwiftUI

extension Color {
    /// Primary blue color used throughout the app - using Apple's system blue
    static let appBlue = Color.blue
    
    /// Secondary color used for progress indicators
    static let appGold = Color.white
    
    /// Background color for UI elements
    static let uiBackground = Color.black.opacity(0.7)
    
    /// Color for unexplored fog areas on the map
    static let fogColor = Color.blue.opacity(0.45)
    
    /// Border color for unexplored fog areas
    static let fogBorderColor = Color.blue.opacity(0.6)
} 