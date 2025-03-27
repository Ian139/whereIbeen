import SwiftUI
import MapKit

class TripCreationViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var isPrivate = false
    @Published var isLoading = false
    @Published var error: String?
    
    private let tripService: TripService
    
    init(tripService: TripService = TripService()) {
        self.tripService = tripService
    }
    
    var isValid: Bool {
        !name.isEmpty
    }
    
    @MainActor
    func createTrip(coordinates: [CLLocationCoordinate2D], totalMiles: Double) async throws {
        guard isValid else { return }
        isLoading = true
        error = nil
        
        do {
            let trip = Trip(
                id: UUID().uuidString,
                name: name,
                description: description,
                startDate: Date(),
                endDate: nil,
                coordinates: coordinates,
                totalMiles: totalMiles,
                isPrivate: isPrivate
            )
            
            try await tripService.saveTrip(trip)
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
}

struct TripCreationView: View {
    @StateObject private var viewModel = TripCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    let coordinates: [CLLocationCoordinate2D]
    let totalMiles: Double
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Trip Name", text: $viewModel.name)
                    
                    TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Toggle("Private Trip", isOn: $viewModel.isPrivate)
                }
                
                Section(header: Text("Trip Stats")) {
                    LabeledContent("Distance", value: String(format: "%.1f miles", totalMiles))
                    LabeledContent("Locations", value: "\(coordinates.count) points")
                }
                
                Section {
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.createTrip(
                                    coordinates: coordinates,
                                    totalMiles: totalMiles
                                )
                                dismiss()
                            } catch {
                                // Error is already handled by viewModel
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Trip")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
                
                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
} 