import SwiftUI

/// View showing the user's current level based on miles explored
struct LevelView: View {
    let level: Int
    let milesExplored: Double
    
    // Calculate progress to next level
    private var progressToNextLevel: Double {
        let nextLevelMiles = Double(level) * 100.0
        let progressInCurrentLevel = milesExplored.truncatingRemainder(dividingBy: 100.0)
        return progressInCurrentLevel / 100.0
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // The word "Level" with the current level number
            Text("Level")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            
            // Level number
            ZStack {
                // Circular background with progress
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 44, height: 44)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(progressToNextLevel))
                    .stroke(Color.appGold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                // Level number
                Text("\(level)")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
            
            // Lock icon
            Image(systemName: "lock.fill")
                .foregroundColor(.white)
                .font(.system(size: 14))
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.5)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.uiBackground)
        .cornerRadius(25)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(level), \(String(format: "%.1f", milesExplored)) miles explored")
    }
}

#if DEBUG
struct LevelView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue
            LevelView(level: 20, milesExplored: 2002.4)
        }
    }
}
#endif 