import SwiftUI
import MapKit

struct SettingsView: View {
    // Reference to the settings service for immediate updates
    @StateObject private var settingsService = SettingsService.shared
    
    var body: some View {
        NavigationView {
            Form {
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