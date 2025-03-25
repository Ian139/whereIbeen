import SwiftUI

struct ProfileView: View {
    // Accept the viewModel from parent view
    @ObservedObject var viewModel: MapViewModel
    
    @State private var username = "Explorer"
    @State private var joinDate = Date().addingTimeInterval(-60 * 60 * 24 * 30) // 30 days ago
    @State private var showingEditProfile = false
    @State private var followers = 42
    @State private var totalTrips = 15
    @State private var profileImage = "person.crop.circle.fill"
    
    // Badges and achievements
    @State private var badges = [
        Badge(name: "First Mile", description: "Explored your first mile", image: "trophy"),
        Badge(name: "Early Bird", description: "Explored before 7 AM", image: "sunrise"),
        Badge(name: "Night Owl", description: "Explored after 10 PM", image: "moon.stars")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: profileImage)
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                    
                    Text(username)
                        .font(.title.bold())
                    
                    Text("Member since \(formattedDate(joinDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Stats Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Stats")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        StatCard(title: "Miles Explored", value: String(format: "%.1f", viewModel.totalMiles), icon: "map")
                        StatCard(title: "Current Level", value: "\(viewModel.level)", icon: "star.fill")
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        StatCard(title: "Followers", value: "\(followers)", icon: "person.2")
                        StatCard(title: "Total Trips", value: "\(totalTrips)", icon: "figure.walk")
                    }
                    .padding(.horizontal)
                    
                    // Additional stat
                    StatCard(title: "Squares Until Next Level", value: "\(viewModel.squaresUntilNextLevel)", icon: "square.grid.2x2")
                        .padding(.horizontal)
                }
                
                // Badges Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Badges")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(badges) { badge in
                                BadgeView(badge: badge)
                            }
                            
                            // Locked badges
                            ForEach(1...3, id: \.self) { _ in
                                LockedBadgeView()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Quick actions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.resetMap()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16))
                            Text("Reset Exploration History")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(username: $username, profileImage: $profileImage)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var username: String
    @Binding var profileImage: String
    @State private var editedUsername: String = ""
    @State private var selectedImageOption: String = ""
    
    private let imageOptions = [
        "person.crop.circle.fill",
        "person.crop.circle.fill.badge.checkmark",
        "airplane.circle.fill",
        "map.circle.fill",
        "location.circle.fill",
        "figure.walk.circle.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Username")) {
                    TextField("Username", text: $editedUsername)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.default)
                        .submitLabel(.done)
                }
                
                Section(header: Text("Profile Picture")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(imageOptions, id: \.self) { image in
                                Button(action: {
                                    selectedImageOption = image
                                }) {
                                    Image(systemName: image)
                                        .font(.system(size: 40))
                                        .foregroundColor(selectedImageOption == image ? .blue : .gray)
                                        .frame(width: 60, height: 60)
                                        .background(selectedImageOption == image ? Color.blue.opacity(0.1) : Color.clear)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .frame(height: 80)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if !editedUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        username = editedUsername
                    }
                    
                    if !selectedImageOption.isEmpty {
                        profileImage = selectedImageOption
                    }
                    
                    dismiss()
                }
            )
            .onAppear {
                editedUsername = username
                selectedImageOption = profileImage
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct Badge: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let image: String
}

struct BadgeView: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badge.image)
                .font(.system(size: 30))
                .foregroundColor(.yellow)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text(badge.name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(badge.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct LockedBadgeView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 30))
                .foregroundColor(.gray)
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            Text("Locked")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Keep exploring to unlock")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView(viewModel: MapViewModel())
} 