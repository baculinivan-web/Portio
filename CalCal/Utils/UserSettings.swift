import SwiftUI

// A centralized place to manage user-defined goals using UserDefaults.
struct UserSettings {
    static let shared = UserDefaults(suiteName: "group.com.ivan.CalCal") ?? .standard
    
    @AppStorage("calorieGoal", store: shared) static var calorieGoal: Double = 2200
    @AppStorage("proteinGoal", store: shared) static var proteinGoal: Double = 120
    @AppStorage("carbsGoal", store: shared) static var carbsGoal: Double = 250
    @AppStorage("fatGoal", store: shared) static var fatGoal: Double = 70
    @AppStorage("goalExplanation", store: shared) static var goalExplanation: String = ""
    @AppStorage("hasCompletedOnboarding", store: shared) static var hasCompletedOnboarding: Bool = false
}
