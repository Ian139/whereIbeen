import SwiftUI
import MapKit

struct SocialPost: Identifiable {
    let id = UUID()
    let username: String
    let profileImage: String // SF Symbol name for now
    let tripName: String
    let tripDescription: String
    let postedAt: Date
    let likes: Int
    let comments: Int
    let mapRegion: MKCoordinateRegion
    let exploredCoordinates: [CLLocationCoordinate2D] // For fog overlay
    
    // Sample data generator
    static func samplePosts() -> [SocialPost] {
        [
            SocialPost(
                username: "AdventureSeeker",
                profileImage: "person.circle.fill",
                tripName: "Weekend in Big Sur",
                tripDescription: "Explored the beautiful California coastline",
                postedAt: Date().addingTimeInterval(-24 * 60 * 60),
                likes: 42,
                comments: 12,
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
                tripDescription: "Getting lost in the streets of Shibuya",
                postedAt: Date().addingTimeInterval(-48 * 60 * 60),
                likes: 89,
                comments: 24,
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
                tripDescription: "Coffee, croissants, and culture",
                postedAt: Date().addingTimeInterval(-72 * 60 * 60),
                likes: 156,
                comments: 31,
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