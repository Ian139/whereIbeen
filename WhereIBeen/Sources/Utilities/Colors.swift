import SwiftUI

extension Color {
    /// Primary blue color used throughout the app
    static let appBlue = Color(red: 0, green: 0.31, blue: 0.78)
    
    /// Secondary gold color used for progress indicators
    static let appGold = Color.yellow
    
    /// Background color for UI elements
    static let uiBackground = Color.black.opacity(0.7)
    
    /// Color for unexplored fog areas on the map
    static let fogColor = Color(red: 0, green: 0.31, blue: 0.78, opacity: 0.45)
    
    /// Border color for unexplored fog areas
    static let fogBorderColor = Color(red: 0, green: 0.31, blue: 0.78, opacity: 0.6)
} 