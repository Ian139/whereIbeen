import Foundation
import SwiftUI
import MapKit
import CoreLocation

class LocalStorageService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var localTrips: [Trip] = []
    private let defaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum StorageKeys {
        static let trips = "trips"
        static let profile = "profile"
        static let comments = "comments"
        static let likes = "likes"
    }
    
    init() {
        loadTrips()
    }
    
    // MARK: - Profile Management
    
    func getCurrentProfile() -> [String: String] {
        defaults.dictionary(forKey: StorageKeys.profile) as? [String: String] ?? [:]
    }
    
    func updateProfile(username: String, bio: String) {
        let profile = ["username": username, "bio": bio]
        defaults.set(profile, forKey: StorageKeys.profile)
    }
    
    // MARK: - Trip Management
    
    func saveTrip(_ trip: Trip) {
        var trips = getAllTrips()
        
        // Check if trip already exists by ID
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
        } else {
            trips.append(trip)
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(trips)
            defaults.set(data, forKey: StorageKeys.trips)
            loadTrips()
        } catch {
            print("Error saving trips: \(error)")
        }
    }
    
    func loadTrips() {
        do {
            guard let data = defaults.data(forKey: StorageKeys.trips) else {
                localTrips = []
                return
            }
            
            let decoder = JSONDecoder()
            localTrips = try decoder.decode([Trip].self, from: data)
        } catch {
            print("Error loading trips: \(error)")
            localTrips = []
        }
    }
    
    func getAllTrips() -> [Trip] {
        return localTrips
    }
    
    func getPublicTrips() -> [Trip] {
        return localTrips.filter { !$0.isPrivate }
    }
    
    func deleteTrip(withId id: String) {
        var trips = getAllTrips()
        trips.removeAll { $0.id == id }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(trips)
            defaults.set(data, forKey: StorageKeys.trips)
            loadTrips()
        } catch {
            print("Error deleting trip: \(error)")
        }
    }
    
    // MARK: - Comments
    
    func getComments(tripId: String) -> [[String: Any]] {
        let allComments = defaults.dictionary(forKey: StorageKeys.comments) as? [String: [[String: Any]]] ?? [:]
        return allComments[tripId] ?? []
    }
    
    func addComment(tripId: String, content: String) -> [String: Any] {
        var allComments = defaults.dictionary(forKey: StorageKeys.comments) as? [String: [[String: Any]]] ?? [:]
        let comment: [String: Any] = [
            "id": UUID().uuidString,
            "content": content,
            "createdAt": Date(),
            "tripId": tripId
        ]
        
        var tripComments = allComments[tripId] ?? []
        tripComments.append(comment)
        allComments[tripId] = tripComments
        
        defaults.set(allComments, forKey: StorageKeys.comments)
        return comment
    }
    
    // MARK: - Likes
    
    func getLikeStatus(tripId: String) -> Bool {
        let likes = defaults.dictionary(forKey: StorageKeys.likes) as? [String: Bool] ?? [:]
        return likes[tripId] ?? false
    }
    
    func toggleLike(tripId: String) -> Bool {
        var likes = defaults.dictionary(forKey: StorageKeys.likes) as? [String: Bool] ?? [:]
        let newStatus = !(likes[tripId] ?? false)
        likes[tripId] = newStatus
        defaults.set(likes, forKey: StorageKeys.likes)
        return newStatus
    }
    
    // MARK: - Auth simulation
    
    func signIn(email: String, password: String) {
        // Simple simulation of auth - in real app would need proper auth
        isAuthenticated = true
    }
    
    func signUp(email: String, password: String) {
        // Simple simulation of auth - in real app would need proper auth
        isAuthenticated = true
    }
    
    func signOut() {
        isAuthenticated = false
    }
} 