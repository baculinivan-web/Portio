import Foundation
import SwiftData

enum AchievementLevel {
    case level1 // First log
    case level2 // Goal reached
}

class StreakAchievementManager {
    static func checkAchievement(
        totalCalories: Double,
        calorieGoal: Double,
        weightGoalMode: UserSettings.WeightGoalMode,
        hasEntries: Bool
    ) -> AchievementLevel? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 1. Check Level 2 (Priority if both met)
        if isGoalMet(intake: totalCalories, goal: calorieGoal, mode: weightGoalMode) {
            if !isShownToday(lastDate: UserSettings.lastLevel2ShownDate) {
                UserSettings.lastLevel2ShownDate = today
                return .level2
            }
        }
        
        // 2. Check Level 1
        if hasEntries {
            if !isShownToday(lastDate: UserSettings.lastLevel1ShownDate) {
                UserSettings.lastLevel1ShownDate = today
                return .level1
            }
        }
        
        return nil
    }
    
    private static func isShownToday(lastDate: Date?) -> Bool {
        guard let lastDate = lastDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    private static func isGoalMet(intake: Double, goal: Double, mode: UserSettings.WeightGoalMode) -> Bool {
        guard goal > 0 else { return false }
        
        switch mode {
        case .lose:
            // For losing, we usually want to be UNDER or AT goal.
            // But we should also have logged something significant.
            return intake > 0 && intake <= goal
        case .gain:
            return intake >= goal
        case .maintain:
            let lowerBound = goal * 0.9
            let upperBound = goal * 1.1
            return intake >= lowerBound && intake <= upperBound
        }
    }
}
