import SwiftUI

struct MenuView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Spacer() // Pushes the tab bar to the bottom
            
            // Bottom Tab Bar
            HStack(spacing: 0) {
                ForEach(0..<4) { index in
                    TabButton(
                        icon: getIcon(for: index),
                        title: getTitle(for: index),
                        isSelected: selectedTab == index
                    ) {
                        selectedTab = index
                    }
                }
            }
            .frame(height: 80)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private func getIcon(for index: Int) -> String {
        switch index {
        case 0:
            return "map"
        case 1:
            return "person.circle"
        case 2:
            return "person.2"
        case 3:
            return "gear"
        default:
            return "questionmark"
        }
    }
    
    private func getTitle(for index: Int) -> String {
        switch index {
        case 0:
            return "Map"
        case 1:
            return "Profile"
        case 2:
            return "Friends"
        case 3:
            return "Settings"
        default:
            return "Unknown"
        }
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }
}

// Extension to create custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    MenuView()
} 
