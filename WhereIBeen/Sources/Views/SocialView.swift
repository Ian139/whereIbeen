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
            // Enhanced map preview
            ZStack(alignment: .bottomTrailing) {
                MapPreview(region: trip.region, exploredCoordinates: trip.coordinates)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                // Distance badge
                Text(String(format: "%.1f mi", trip.totalMiles))
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(trip.startDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
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
                    // Enhanced full-size map with exploration overlay
                    ZStack(alignment: .bottomTrailing) {
                        MapPreview(region: trip.region, exploredCoordinates: trip.coordinates)
                            .frame(height: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Trip stats badge
                        HStack(spacing: 8) {
                            Label(
                                String(format: "%.1f mi", trip.totalMiles),
                                systemImage: "figure.walk"
                            )
                            .font(.caption)
                            .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Trip details
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trip.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if trip.isPrivate {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text("Private")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Text(formatDate(trip.startDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(6)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(8)
                        }
                        
                        // Trip description with background
                        Text(trip.description)
                            .font(.body)
                            .padding(12)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        // Delete button with improved styling
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Trip")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                        }
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
            // Enhanced map preview with fog overlay
            ZStack(alignment: .bottomTrailing) {
                MapPreview(region: post.mapRegion, exploredCoordinates: post.exploredCoordinates)
                    .frame(height: 180)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                // Likes badge
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                    
                    Text("\(post.likes)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(8)
            }
            
            // Post header and trip info
            VStack(alignment: .leading, spacing: 6) {
                // Post header
                HStack {
                    Image(systemName: post.profileImage)
                        .font(.subheadline)
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
                
                // Comments count
                HStack {
                    Spacer()
                    
                    Label("\(post.comments) comments", systemImage: "bubble.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
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
    
    // Define a simple identifiable struct to use with Map
    private struct MapPoint: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
    
    var body: some View {
        // Use MapKit to show the preview with improved fog overlay
        ZStack {
            Map(coordinateRegion: .constant(region), showsUserLocation: false)
                .allowsHitTesting(false) // Prevent interaction with the preview
            
            // Enhanced fog overlay
            EnhancedFogOverlay(region: region, exploredCoordinates: exploredCoordinates)
        }
        .cornerRadius(12)
    }
}

struct EnhancedFogOverlay: View {
    let region: MKCoordinateRegion
    let exploredCoordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent dark fog
                Color.black.opacity(0.4)
                
                // Explored area visualization
                Canvas { context, size in
                    // Calculate the map bounds
                    let minLat = region.center.latitude - region.span.latitudeDelta/2
                    let maxLat = region.center.latitude + region.span.latitudeDelta/2
                    let minLon = region.center.longitude - region.span.longitudeDelta/2
                    let maxLon = region.center.longitude + region.span.longitudeDelta/2
                    
                    // Draw explored cells
                    for coordinate in exploredCoordinates {
                        // Skip if outside visible region with some buffer
                        if coordinate.latitude < minLat - 0.1 || coordinate.latitude > maxLat + 0.1 ||
                           coordinate.longitude < minLon - 0.1 || coordinate.longitude > maxLon + 0.1 {
                            continue
                        }
                        
                        // Convert to view coordinates
                        let x = ((coordinate.longitude - minLon) / (maxLon - minLon)) * size.width
                        let y = ((maxLat - coordinate.latitude) / (maxLat - minLat)) * size.height
                        
                        // Draw a small circle for each coordinate
                        let cellSize = min(size.width, size.height) / 30
                        let rect = CGRect(x: x - cellSize/2, y: y - cellSize/2, width: cellSize, height: cellSize)
                        let path = Path(ellipseIn: rect)
                        
                        // Use a gradient fill for better visibility
                        context.fill(path, with: .color(.blue.opacity(0.6)))
                        context.stroke(path, with: .color(.white.opacity(0.4)), lineWidth: 1)
                    }
                }
                
                // Add subtle glow effect
                Text("")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
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
                    // Enhanced full-size map with fog overlay
                    ZStack(alignment: .bottomTrailing) {
                        MapPreview(region: post.mapRegion, exploredCoordinates: post.exploredCoordinates)
                            .frame(height: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Social stats badge
                        HStack(spacing: 10) {
                            Label("\(post.likes)", systemImage: "heart.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Post header with profile info
                        HStack(spacing: 12) {
                            Image(systemName: post.profileImage)
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(post.username)
                                    .font(.headline)
                                
                                Text(timeAgo(from: post.postedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Label("\(post.comments)", systemImage: "bubble.right")
                                .font(.caption)
                                .padding(6)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(8)
                                .foregroundColor(.secondary)
                        }
                        
                        // Trip details
                        Text(post.tripName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(post.tripDescription)
                            .font(.body)
                            .padding(12)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Comment input with enhanced styling
                        VStack(spacing: 12) {
                            Text("Add a comment")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("Write something...", text: $comment)
                                    .padding(10)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    // TODO: Handle comment posting
                                    comment = ""
                                }) {
                                    Text("Post")
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(comment.isEmpty ? Color.blue.opacity(0.3) : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .disabled(comment.isEmpty)
                            }
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