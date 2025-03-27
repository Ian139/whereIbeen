import Foundation
import CoreData
import CoreLocation
import MapKit

class Trip: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date?
    @NSManaged public var description: String?
    @NSManaged public var isPrivate: Bool
    @NSManaged public var totalMiles: Double
    @NSManaged public var coordinatesData: Data?
    @NSManaged public var regionData: Data?
    
    // Computed properties
    var coordinates: [CLLocationCoordinate2D] {
        get {
            guard let data = coordinatesData else { return [] }
            do {
                return try JSONDecoder().decode([Coordinate].self, from: data).map { $0.toCLCoordinate() }
            } catch {
                print("Error decoding coordinates: \(error)")
                return []
            }
        }
        set {
            do {
                let coordinates = newValue.map(Coordinate.init)
                coordinatesData = try JSONEncoder().encode(coordinates)
            } catch {
                print("Error encoding coordinates: \(error)")
            }
        }
    }
    
    var region: MKCoordinateRegion? {
        get {
            guard let data = regionData else { return nil }
            do {
                let savedRegion = try JSONDecoder().decode(SavedRegion.self, from: data)
                return savedRegion.toMKCoordinateRegion()
            } catch {
                print("Error decoding region: \(error)")
                return nil
            }
        }
        set {
            guard let newRegion = newValue else {
                regionData = nil
                return
            }
            do {
                let savedRegion = SavedRegion(from: newRegion)
                regionData = try JSONEncoder().encode(savedRegion)
            } catch {
                print("Error encoding region: \(error)")
            }
        }
    }
}

// Helper structs for JSON encoding/decoding
private struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    func toCLCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private struct SavedRegion: Codable {
    let centerLatitude: Double
    let centerLongitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double
    
    init(from region: MKCoordinateRegion) {
        self.centerLatitude = region.center.latitude
        self.centerLongitude = region.center.longitude
        self.latitudeDelta = region.span.latitudeDelta
        self.longitudeDelta = region.span.longitudeDelta
    }
    
    func toMKCoordinateRegion() -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: centerLatitude,
                longitude: centerLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
    }
} 