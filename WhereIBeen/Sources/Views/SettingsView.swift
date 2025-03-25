import SwiftUI
import MapKit

struct SettingsView: View {
    // Map Display Options
    @AppStorage("mapType") private var mapType = 0
    @AppStorage("showGridLines") private var showGridLines = true
    @AppStorage("fogOpacity") private var fogOpacity = 0.45
    @AppStorage("fogColorHue") private var fogColorHue = 0.6
    
    // Exploration Settings
    @AppStorage("gridSize") private var gridSize = 1.0 // 1 = Default size
    
    // Map type options
    private let mapTypes = ["Standard", "Satellite", "Hybrid"]
    
    // Map type mapping to MKMapType
    private let mapTypeValues: [MKMapType] = [.standard, .satellite, .hybrid]
    
    var body: some View {
        NavigationView {
            Form {
                // Map Display Options
                Section(header: Text("Map Display Options")) {
                    // Map Type Picker
                    Picker("Default Map Type", selection: $mapType) {
                        ForEach(0..<mapTypes.count, id: \.self) { index in
                            Text(mapTypes[index])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Grid Lines Toggle
                    Toggle("Show Grid Lines", isOn: $showGridLines)
                    
                    // Fog Opacity Slider
                    VStack(alignment: .leading) {
                        Text("Fog Opacity")
                        HStack {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $fogOpacity, in: 0.1...0.9, step: 0.05)
                            Text("Dense")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Fog Color Picker - using a Hue slider for simplicity
                    VStack(alignment: .leading) {
                        Text("Fog Color")
                        ColorPicker("", selection: Binding(
                            get: { Color(hue: fogColorHue, saturation: 0.8, brightness: 0.8) },
                            set: { newColor in
                                var hue: CGFloat = 0
                                var saturation: CGFloat = 0
                                var brightness: CGFloat = 0
                                var alpha: CGFloat = 0
                                
                                UIColor(newColor).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                                fogColorHue = Double(hue)
                            }
                        ))
                        .padding(.vertical, 4)
                    }
                }
                
                // Exploration Settings
                Section(header: Text("Exploration Settings")) {
                    // Grid Size Slider
                    VStack(alignment: .leading) {
                        Text("Grid Size")
                        HStack {
                            Text("Finer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $gridSize, in: 0.5...2.0, step: 0.25)
                            Text("Coarser")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Support Options
                Section(header: Text("Support & Info")) {
                    NavigationLink(destination: FAQView()) {
                        Label("FAQ", systemImage: "questionmark.circle")
                    }
                    
                    Link(destination: URL(string: "mailto:support@whereibeen.app")!) {
                        HStack {
                            Label("Contact Support", systemImage: "envelope")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://whereibeen.app/report-bug")!) {
                        HStack {
                            Label("Report a Bug", systemImage: "ladybug")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://whereibeen.app/feature-request")!) {
                        HStack {
                            Label("Submit Feature Request", systemImage: "star")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Label("App Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

/// Simple FAQ view
struct FAQView: View {
    var body: some View {
        List {
            Section(header: Text("General")) {
                FAQItem(question: "What is WhereIBeen?", 
                        answer: "WhereIBeen tracks and visualizes all the places you've visited on a map.")
                
                FAQItem(question: "How does tracking work?", 
                        answer: "The app uses your device's location to mark areas on a grid as you explore them.")
            }
            
            Section(header: Text("Privacy")) {
                FAQItem(question: "Is my location data shared?", 
                        answer: "No, your location data is stored only on your device and is not shared with others.")
                
                FAQItem(question: "Can I delete my exploration data?", 
                        answer: "Yes, you can reset all exploration history from your profile page.")
            }
            
            Section(header: Text("Features")) {
                FAQItem(question: "What are grid lines?", 
                        answer: "Grid lines show the boundaries of the tracking cells on the map.")
                
                FAQItem(question: "What does fog opacity control?", 
                        answer: "This controls how transparent or opaque the fog overlay appears on unexplored areas.")
            }
        }
        .navigationTitle("Frequently Asked Questions")
    }
}

/// Reusable FAQ item component
struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
} 