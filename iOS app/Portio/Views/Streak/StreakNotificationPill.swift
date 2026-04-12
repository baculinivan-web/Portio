import SwiftUI

struct StreakNotificationPill: View {
    let level: AchievementLevel
    let streakCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            
            Text(level == .level1 ? "\(streakCount) Day Streak!" : "Daily Goal Achieved!")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
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
