import SwiftUI

// A centralized place to manage user-defined goals using UserDefaults.
struct UserSettings {
    @AppStorage("calorieGoal") static var calorieGoal: Double = 2200
    @AppStorage("proteinGoal") static var proteinGoal: Double = 120
    @AppStorage("carbsGoal") static var carbsGoal: Double = 250
    @AppStorage("fatGoal") static var fatGoal: Double = 70
    @AppStorage("goalExplanation") static var goalExplanation: String = ""
    @AppStorage("hasCompletedOnboarding") static var hasCompletedOnboarding: Bool = false
}
