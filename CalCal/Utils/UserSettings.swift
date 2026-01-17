import SwiftUI

// A centralized place to manage user-defined goals using UserDefaults.
struct UserSettings {
    static let shared = UserDefaults(suiteName: "group.com.ivan.CalCal") ?? .standard
    
    enum WeightGoalMode: String, CaseIterable, Identifiable {
        case lose = "Lose Weight"
        case maintain = "Maintain Weight"
        case gain = "Gain Weight"
        
        var id: String { self.rawValue }
    }
    
    static var weightGoalMode: WeightGoalMode {
        get {
            let rawValue = shared.string(forKey: "weightGoalMode") ?? WeightGoalMode.maintain.rawValue
            return WeightGoalMode(rawValue: rawValue) ?? .maintain
        }
        set { shared.set(newValue.rawValue, forKey: "weightGoalMode") }
    }
    
    static var calorieGoal: Double {
        get { shared.double(forKey: "calorieGoal") == 0 ? 2200 : shared.double(forKey: "calorieGoal") }
        set { shared.set(newValue, forKey: "calorieGoal") }
    }
    
    static var proteinGoal: Double {
        get { shared.double(forKey: "proteinGoal") == 0 ? 120 : shared.double(forKey: "proteinGoal") }
        set { shared.set(newValue, forKey: "proteinGoal") }
    }
    
    static var carbsGoal: Double {
        get { shared.double(forKey: "carbsGoal") == 0 ? 250 : shared.double(forKey: "carbsGoal") }
        set { shared.set(newValue, forKey: "carbsGoal") }
    }
    
    static var fatGoal: Double {
        get { shared.double(forKey: "fatGoal") == 0 ? 70 : shared.double(forKey: "fatGoal") }
        set { shared.set(newValue, forKey: "fatGoal") }
    }
    
    static var goalExplanation: String {
        get { shared.string(forKey: "goalExplanation") ?? "" }
        set { shared.set(newValue, forKey: "goalExplanation") }
    }
    
    static var hasCompletedOnboarding: Bool {
        get { shared.bool(forKey: "hasCompletedOnboarding") }
        set { shared.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    static var isAppleHealthSyncEnabled: Bool {
        get { shared.bool(forKey: "isAppleHealthSyncEnabled") }
        set { shared.set(newValue, forKey: "isAppleHealthSyncEnabled") }
    }
    
    // MARK: - Streak Achievement Tracking
    
    static var lastLevel1ShownDate: Date? {
        get { shared.object(forKey: "lastLevel1ShownDate") as? Date }
        set { shared.set(newValue, forKey: "lastLevel1ShownDate") }
    }
    
    static var lastLevel2ShownDate: Date? {
        get { shared.object(forKey: "lastLevel2ShownDate") as? Date }
        set { shared.set(newValue, forKey: "lastLevel2ShownDate") }
    }
}
