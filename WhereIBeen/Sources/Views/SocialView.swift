import SwiftUI
import MapKit

struct SocialView: View {
    @State private var posts = SocialPost.samplePosts()
    @State private var selectedPost: SocialPost?
    
    // Grid layout configuration
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(posts) { post in
                        TripPostCard(post: post)
                            .onTapGesture {
                                selectedPost = post
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Social")
            .navigationBarItems(
                trailing: Button(action: {
                    // TODO: Add new trip post
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            )
            .sheet(item: $selectedPost) { post in
                TripPostDetail(post: post)
            }
        }
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
} 