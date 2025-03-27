import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ProfileEditViewModel
    
    init(storageService: LocalStorageService) {
        _viewModel = StateObject(wrappedValue: ProfileEditViewModel(storageService: storageService))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Username", text: $viewModel.username)
                    TextField("Bio", text: $viewModel.bio)
                }
                
                Section {
                    Button("Save") {
                        viewModel.saveProfile()
                        dismiss()
                    }
                    .disabled(viewModel.username.isEmpty)
                }
            }
            .navigationTitle("Edit Profile")
            .onAppear {
                viewModel.loadProfile()
            }
        }
    }
}

class ProfileEditViewModel: ObservableObject {
    @Published var username = ""
    @Published var bio = ""
    
    private let storageService: LocalStorageService
    
    init(storageService: LocalStorageService) {
        self.storageService = storageService
    }
    
    func loadProfile() {
        let profile = storageService.getCurrentProfile()
        username = profile["username"] ?? ""
        bio = profile["bio"] ?? ""
    }
    
    func saveProfile() {
        storageService.updateProfile(username: username, bio: bio)
    }
} 