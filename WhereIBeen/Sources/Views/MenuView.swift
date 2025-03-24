import SwiftUI

struct MenuView: View {
    @State private var isMenuVisible = false
    @State private var dragOffset: CGFloat = 0
    private let menuHeight: CGFloat = 200
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Fill the gap at the top
                Color(UIColor.systemBackground)
                    .frame(height: geometry.safeAreaInsets.top)
                
                // Menu Items
                VStack(spacing: 16) {
                    MenuButton(icon: "person.circle", title: "Profile")
                    MenuButton(icon: "map", title: "Trips")
                    MenuButton(icon: "person.2", title: "Friends")
                    MenuButton(icon: "gear", title: "Settings")
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Handle at bottom
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 6)
                    .padding(.bottom, 16)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: menuHeight + geometry.safeAreaInsets.top)
            .background(Color(UIColor.systemBackground))
            .offset(y: -(menuHeight + geometry.safeAreaInsets.top) + dragOffset + (isMenuVisible ? (menuHeight + geometry.safeAreaInsets.top) : 0))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newOffset = value.translation.height
                        dragOffset = min(max(newOffset, -(menuHeight + geometry.safeAreaInsets.top)), 0)
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        withAnimation(.spring()) {
                            if velocity > 100 || dragOffset > -(menuHeight + geometry.safeAreaInsets.top)/2 {
                                isMenuVisible = true
                                dragOffset = 0
                            } else {
                                isMenuVisible = false
                                dragOffset = 0
                            }
                        }
                    }
            )
            .animation(.spring(), value: isMenuVisible)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Menu")
            .accessibilityHint("Swipe down to open menu. Swipe up to close.")
            .accessibilityAddTraits(isMenuVisible ? .isSelected : [])
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {
            // Handle button tap
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .accessibility(hidden: true)
                Text(title)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .accessibility(hidden: true)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .accessibilityHint("Opens \(title.lowercased()) screen")
    }
}
//
//// Extension to create custom corner radius
//extension View {
//    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
//        clipShape(RoundedCorner(radius: radius, corners: corners))
//    }
//    
//    func only(topLeft: Bool = false, topRight: Bool = false, bottomLeft: Bool = false, bottomRight: Bool = false) -> some View {
//        var corners: UIRectCorner = []
//        if topLeft { corners.insert(.topLeft) }
//        if topRight { corners.insert(.topRight) }
//        if bottomLeft { corners.insert(.bottomLeft) }
//        if bottomRight { corners.insert(.bottomRight) }
//        return cornerRadius(20, corners: corners)
//    }
//}
//
//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
//    var corners: UIRectCorner = .allCorners
//    
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(
//            roundedRect: rect,
//            byRoundingCorners: corners,
//            cornerRadii: CGSize(width: radius, height: radius)
//        )
//        return Path(path.cgPath)
//    }
//}

#Preview {
    MenuView()
} 
