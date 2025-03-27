import SwiftUI
import MapKit

// Comment model to represent a user comment on a post
struct Comment: Identifiable {
    let id = UUID()
    let username: String
    let profileImage: String // SF Symbol name
    let text: String
    let postedAt: Date
    let likes: Int
}

struct SocialPost: Identifiable {
    let id = UUID()
    let username: String
    let profileImage: String // SF Symbol name for now
    let tripName: String
    let tripDescription: String
    let postedAt: Date
    let likes: Int
    var comments: [Comment] // Changed from Int to store actual comments
    let mapRegion: MKCoordinateRegion
    let exploredCoordinates: [CLLocationCoordinate2D] // For fog overlay
    
    // Computed property to get comment count
    var commentCount: Int {
        return comments.count
    }
    
    // Method to add a new comment
    mutating func addComment(text: String) {
        let newComment = Comment(
            username: "You", // Default to "You" for the current user
            profileImage: "person.circle",
            text: text,
            postedAt: Date(),
            likes: 0
        )
        comments.append(newComment)
    }
    
    // Sample data generator
    static func samplePosts() -> [SocialPost] {
        [
            SocialPost(
                username: "AdventureSeeker",
                profileImage: "person.circle.fill",
                tripName: "Weekend in Big Sur",
                tripDescription: "Explored the beautiful California coastline along Highway 1. Stopped at McWay Falls and hiked through Pfeiffer Big Sur State Park. The fog rolling in over the ocean was simply breathtaking!",
                postedAt: Date().addingTimeInterval(-24 * 60 * 60),
                likes: 42,
                comments: [
                    Comment(
                        username: "NaturePhotog",
                        profileImage: "camera.circle.fill",
                        text: "The coastline views are incredible! Did you stop at Bixby Bridge?",
                        postedAt: Date().addingTimeInterval(-23 * 60 * 60),
                        likes: 5
                    ),
                    Comment(
                        username: "HikingEnthusiast",
                        profileImage: "figure.hiking",
                        text: "Big Sur is on my bucket list! Any trails you'd recommend?",
                        postedAt: Date().addingTimeInterval(-22 * 60 * 60),
                        likes: 3
                    ),
                    Comment(
                        username: "LocalExplorer",
                        profileImage: "map.circle",
                        text: "Next time check out Garrapata State Park, it's less crowded and has amazing views!",
                        postedAt: Date().addingTimeInterval(-20 * 60 * 60),
                        likes: 8
                    )
                ],
                mapRegion: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 36.2704, longitude: -121.8081),
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                ),
                exploredCoordinates: [
                    CLLocationCoordinate2D(latitude: 36.2704, longitude: -121.8081),
                    CLLocationCoordinate2D(latitude: 36.2705, longitude: -121.8082),
                    CLLocationCoordinate2D(latitude: 36.2706, longitude: -121.8083)
                ]
            ),
            SocialPost(
                username: "WorldExplorer",
                profileImage: "airplane.circle.fill",
                tripName: "Tokyo Adventure",
                tripDescription: "Getting lost in the streets of Shibuya and exploring the vibrant neighborhoods. Visited Meiji Shrine and spent hours in the anime shops of Akihabara. The street food in Ueno was incredible!",
                postedAt: Date().addingTimeInterval(-48 * 60 * 60),
                likes: 89,
                comments: [
                    Comment(
                        username: "FoodieTravel",
                        profileImage: "fork.knife.circle",
                        text: "Did you try the ramen at Ichiran? It's a must-visit!",
                        postedAt: Date().addingTimeInterval(-46 * 60 * 60),
                        likes: 12
                    ),
                    Comment(
                        username: "CultureBuff",
                        profileImage: "building.columns.circle",
                        text: "The contrast between traditional and modern in Tokyo is mind-blowing.",
                        postedAt: Date().addingTimeInterval(-44 * 60 * 60),
                        likes: 7
                    )
                ],
                mapRegion: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ),
                exploredCoordinates: [
                    CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                    CLLocationCoordinate2D(latitude: 35.6763, longitude: 139.6504),
                    CLLocationCoordinate2D(latitude: 35.6764, longitude: 139.6505)
                ]
            ),
            SocialPost(
                username: "CityHopper",
                profileImage: "map.circle.fill",
                tripName: "Paris Weekender",
                tripDescription: "Coffee, croissants, and culture in the City of Light. Climbed the Eiffel Tower at sunset and wandered through the historic streets of Le Marais. The art at the Louvre was even more impressive in person.",
                postedAt: Date().addingTimeInterval(-72 * 60 * 60),
                likes: 156,
                comments: [
                    Comment(
                        username: "ArtLover",
                        profileImage: "paintpalette.fill",
                        text: "The Louvre alone is worth the trip! Did you see Mona Lisa?",
                        postedAt: Date().addingTimeInterval(-70 * 60 * 60),
                        likes: 14
                    ),
                    Comment(
                        username: "EuropeTraveler",
                        profileImage: "airplane.departure",
                        text: "Paris is magical! Did you make it to Montmartre?",
                        postedAt: Date().addingTimeInterval(-68 * 60 * 60),
                        likes: 9
                    ),
                    Comment(
                        username: "FoodCritic",
                        profileImage: "star.circle.fill",
                        text: "Which bakery had the best croissants? I need to know for my trip next month!",
                        postedAt: Date().addingTimeInterval(-65 * 60 * 60),
                        likes: 6
                    ),
                    Comment(
                        username: "HistoryBuff",
                        profileImage: "book.circle",
                        text: "Notre-Dame's architecture is stunning even during renovation.",
                        postedAt: Date().addingTimeInterval(-64 * 60 * 60),
                        likes: 11
                    )
                ],
                mapRegion: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ),
                exploredCoordinates: [
                    CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
                    CLLocationCoordinate2D(latitude: 48.8567, longitude: 2.3523),
                    CLLocationCoordinate2D(latitude: 48.8568, longitude: 2.3524)
                ]
            )
        ]
    }
} 