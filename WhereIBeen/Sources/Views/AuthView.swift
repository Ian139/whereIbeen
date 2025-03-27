import SwiftUI

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AuthViewModel
    
    init(storageService: LocalStorageService) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(storageService: storageService))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                }
                
                Section {
                    Button(viewModel.isSignUp ? "Sign Up" : "Sign In") {
                        Task {
                            await viewModel.authenticate()
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
                
                Section {
                    Button(viewModel.isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up") {
                        viewModel.isSignUp.toggle()
                    }
                }
            }
            .navigationTitle(viewModel.isSignUp ? "Sign Up" : "Sign In")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error ?? "An unknown error occurred")
            }
            .onChange(of: viewModel.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
        }
    }
}

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isSignUp = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    @Published var isAuthenticated = false
    
    private let storageService: LocalStorageService
    
    init(storageService: LocalStorageService) {
        self.storageService = storageService
    }
    
    @MainActor
    func authenticate() async {
        guard !email.isEmpty && !password.isEmpty else {
            error = "Please fill in all fields"
            showError = true
            return
        }
        
        isLoading = true
        
        if isSignUp {
            storageService.signUp(email: email, password: password)
        } else {
            storageService.signIn(email: email, password: password)
        }
        
        isAuthenticated = storageService.isAuthenticated
        isLoading = false
    }
} 