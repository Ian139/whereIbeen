import SwiftUI
import MapKit

struct SocialView: View {
    @State private var posts = SocialPost.samplePosts()
    @State private var selectedPost: SocialPost?
    @StateObject private var storageService = LocalStorageService()
    @State private var showingSaveExplorationSheet = false
    @State private var showingTripDetail = false
    @State private var selectedTrip: Trip?
    
    // Need access to the MapViewModel to get current exploration data
    @EnvironmentObject var mapViewModel: MapViewModel
    
    // Grid layout configuration
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                // My Trips Section
                if !storageService.localTrips.isEmpty {
                    VStack(alignment: .leading) {
                        Text("My Trips")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(storageService.localTrips) { trip in
                                    TripCard(trip: trip)
                                        .frame(width: 250, height: 200)
                                        .onTapGesture {
                                            selectedTrip = trip
                                            showingTripDetail = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                // Social Posts Section
                VStack(alignment: .leading) {
                    Text("Explore")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(posts) { post in
                            TripPostCard(post: post)
                                .onTapGesture {
                                    selectedPost = post
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Social")
            .navigationBarItems(
                trailing: Button(action: {
                    showingSaveExplorationSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $showingSaveExplorationSheet) {
                SaveTripView(
                    coordinates: mapViewModel.exploredArea,
                    totalMiles: mapViewModel.totalMiles,
                    mapRegion: mapViewModel.region
                )
            }
            .sheet(item: $selectedPost) { post in
                TripPostDetail(post: post)
            }
            .sheet(isPresented: $showingTripDetail, onDismiss: {
                storageService.loadTrips() // Refresh trips when dismissing
            }) {
                if let trip = selectedTrip {
                    TripDetailView(trip: trip)
                }
            }
            .onAppear {
                storageService.loadTrips()
            }
        }
    }
}

struct TripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Map preview
            MapPreview(region: trip.region, exploredCoordinates: trip.coordinates)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
            
            Text(trip.name)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f miles", trip.totalMiles))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDate(trip.startDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct TripDetailView: View {
    let trip: Trip
    @StateObject private var storageService = LocalStorageService()
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Full-size map with exploration overlay
                    MapPreview(region: trip.region, exploredCoordinates: trip.coordinates)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Trip details
                        Text(trip.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(trip.description)
                            .font(.body)
                        
                        Divider()
                        
                        // Trip stats
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(trip.startDate))
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f miles", trip.totalMiles))
                                    .font(.subheadline)
                            }
                        }
                        
                        if trip.isPrivate {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                Text("Private")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Text("Delete Trip")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Trip Details", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Trip"),
                    message: Text("Are you sure you want to delete this trip? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        storageService.deleteTrip(withId: trip.id)
                        dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct TripPostCard: View {
    let post: SocialPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Map preview with fog overlay
            MapPreview(region: post.mapRegion, exploredCoordinates: post.exploredCoordinates)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
            
            // Post header
            HStack {
                Image(systemName: post.profileImage)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(post.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(timeAgo(from: post.postedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Trip name
            Text(post.tripName)
                .font(.headline)
                .lineLimit(1)
            
            // Interaction stats
            HStack {
                Label("\(post.likes)", systemImage: "heart")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(post.comments)", systemImage: "bubble.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MapPreview: View {
    let region: MKCoordinateRegion
    let exploredCoordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        // Use MapKit to show the preview with fog overlay
        Map(coordinateRegion: .constant(region), showsUserLocation: false)
            .overlay(
                // Semi-transparent fog overlay
                FogOverlay(exploredCoordinates: exploredCoordinates)
            )
            .disabled(true) // Prevent interaction with the preview
    }
}

struct FogOverlay: View {
    let exploredCoordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        GeometryReader { geometry in
            // For now, just show a simple overlay
            // TODO: Implement actual fog overlay based on explored coordinates
            Color.black.opacity(0.3)
                .overlay(
                    Path { path in
                        // Create a simple path connecting explored coordinates
                        if let first = exploredCoordinates.first {
                            path.move(to: coordinateToPoint(first, in: geometry))
                            for coordinate in exploredCoordinates.dropFirst() {
                                path.addLine(to: coordinateToPoint(coordinate, in: geometry))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                )
        }
    }
    
    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D, in geometry: GeometryProxy) -> CGPoint {
        // Convert coordinate to point in the view
        // This is a simplified conversion for demonstration
        let x = (coordinate.longitude + 180) / 360 * geometry.size.width
        let y = (90 - coordinate.latitude) / 180 * geometry.size.height
        return CGPoint(x: x, y: y)
    }
}

struct TripPostDetail: View {
    let post: SocialPost
    @Environment(\.dismiss) private var dismiss
    @State private var comment = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Full-size map with fog overlay
                    MapPreview(region: post.mapRegion, exploredCoordinates: post.exploredCoordinates)
                        .frame(height: 300)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Post header
                        HStack {
                            Image(systemName: post.profileImage)
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(post.username)
                                    .font(.headline)
                                Text(timeAgo(from: post.postedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Trip details
                        Text(post.tripName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(post.tripDescription)
                            .font(.body)
                        
                        // Interaction stats
                        HStack {
                            Button(action: {}) {
                                Label("\(post.likes)", systemImage: "heart")
                            }
                            
                            Spacer()
                            
                            Label("\(post.comments) comments", systemImage: "bubble.right")
                        }
                        .foregroundColor(.secondary)
                        
                        Divider()
                        
                        // Comment input
                        HStack {
                            TextField("Add a comment...", text: $comment)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Post") {
                                // TODO: Handle comment posting
                                comment = ""
                            }
                            .disabled(comment.isEmpty)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    SocialView()
        .environmentObject(MapViewModel())
} 