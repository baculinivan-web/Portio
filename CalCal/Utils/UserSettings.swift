import SwiftUI

// A centralized place to manage user-defined goals using UserDefaults.
struct UserSettings {
    static let shared = UserDefaults(suiteName: "group.com.ivan.CalCal") ?? .standard
    
    static var calorieGoal: Double {
        return shared.double(forKey: "calorieGoal") == 0 ? 2200 : shared.double(forKey: "calorieGoal")
    }
    
    static var proteinGoal: Double {
        return shared.double(forKey: "proteinGoal") == 0 ? 120 : shared.double(forKey: "proteinGoal")
    }
    
    static var carbsGoal: Double {
        return shared.double(forKey: "carbsGoal") == 0 ? 250 : shared.double(forKey: "carbsGoal")
    }
    
    static var fatGoal: Double {
        return shared.double(forKey: "fatGoal") == 0 ? 70 : shared.double(forKey: "fatGoal")
    }
    
    static var goalExplanation: String {
        return shared.string(forKey: "goalExplanation") ?? ""
    }
    
    static var hasCompletedOnboarding: Bool {
        get { shared.bool(forKey: "hasCompletedOnboarding") }
        set { shared.set(newValue, forKey: "hasCompletedOnboarding") }
    }
}
