import SwiftUI

struct StreakNotificationPill: View {
    let level: AchievementLevel
    let streakCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 32, weight: .bold)) // Bigger icon
            
            Text(level == .level1 ? "\(streakCount) Day Streak!" : "Daily Goal Achieved!")
                .font(.system(size: 24, weight: .bold, design: .rounded)) // Bigger text
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.3), lineWidth: 1)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        VStack(spacing: 20) {
            StreakNotificationPill(level: .level1, streakCount: 5)
            StreakNotificationPill(level: .level2, streakCount: 5)
        }
    }
}
