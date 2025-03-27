import SwiftUI
import MapKit
import Combine

struct SaveTripView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SaveTripViewModel()
    
    let coordinates: [CLLocationCoordinate2D]
    let totalMiles: Double
    let mapRegion: MKCoordinateRegion
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Trip Name", text: $viewModel.name)
                    
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Toggle("Private Trip", isOn: $viewModel.isPrivate)
                }
                
                Section(header: Text("Trip Stats")) {
                    LabeledContent("Distance", value: String(format: "%.1f miles", totalMiles))
                    LabeledContent("Locations", value: "\(coordinates.count) points")
                }
                
                Section {
                    Button(action: {
                        viewModel.saveTrip(
                            coordinates: coordinates,
                            totalMiles: totalMiles
                        )
                        dismiss()
                    }) {
                        Text("Save Trip")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .navigationTitle("Save Trip")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

class SaveTripViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var isPrivate = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let storageService = LocalStorageService()
    private var cancellables = Set<AnyCancellable>()
    
    var isValid: Bool {
        !name.isEmpty
    }
    
    func saveTrip(coordinates: [CLLocationCoordinate2D], totalMiles: Double) {
        guard isValid else { return }
        
        do {
            let trip = Trip(
                id: UUID().uuidString,
                name: name,
                description: description,
                startDate: Date(),
                endDate: Date(), // Since we're saving a completed exploration
                coordinates: coordinates,
                totalMiles: totalMiles,
                isPrivate: isPrivate
            )
            
            storageService.saveTrip(trip)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
} 