import SwiftUI

// A centralized place to manage user-defined goals using UserDefaults.
struct UserSettings {
    static let shared = UserDefaults(suiteName: "group.com.ivan.Portio") ?? .standard

    enum WeightGoalMode: String, CaseIterable, Identifiable {
        case lose = "Lose Weight"
        case maintain = "Maintain Weight"
        case gain = "Gain Weight"

        var id: String { self.rawValue }
    }

    enum CalorieCommentaryLevel: String, CaseIterable, Identifiable {
        case professional = "Professional"
        case sassy = "Sassy"
        case crazy = "Crazy"

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

    static var isCalorieCommentaryEnabled: Bool {
        get {
            if shared.object(forKey: "isCalorieCommentaryEnabled") == nil {
                return true
            }
            return shared.bool(forKey: "isCalorieCommentaryEnabled")
        }
        set { shared.set(newValue, forKey: "isCalorieCommentaryEnabled") }
    }

    static var calorieCommentaryLevel: CalorieCommentaryLevel {
        get {
            let rawValue = shared.string(forKey: "calorieCommentaryLevel") ?? CalorieCommentaryLevel.sassy.rawValue
            return CalorieCommentaryLevel(rawValue: rawValue) ?? .sassy
        }
        set { shared.set(newValue.rawValue, forKey: "calorieCommentaryLevel") }
    }

    static var isDayAnalysisEnabled: Bool {
        get {
            if shared.object(forKey: "isDayAnalysisEnabled") == nil {
                return true
            }
            return shared.bool(forKey: "isDayAnalysisEnabled")
        }
        set { shared.set(newValue, forKey: "isDayAnalysisEnabled") }
    }

    static var isDayAnalysisAutomaticEnabled: Bool {
        get {
            if shared.object(forKey: "isDayAnalysisAutomaticEnabled") == nil {
                return true
            }
            return shared.bool(forKey: "isDayAnalysisAutomaticEnabled")
        }
        set { shared.set(newValue, forKey: "isDayAnalysisAutomaticEnabled") }
    }

    static var hasCompletedOnboarding: Bool {
        get { shared.bool(forKey: "hasCompletedOnboarding") }
        set { shared.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    static var isReplayingOnboarding: Bool {
        get { shared.bool(forKey: "isReplayingOnboarding") }
        set { shared.set(newValue, forKey: "isReplayingOnboarding") }
    }

    static var isAppleHealthSyncEnabled: Bool {
        get { shared.bool(forKey: "isAppleHealthSyncEnabled") }
        set { shared.set(newValue, forKey: "isAppleHealthSyncEnabled") }
    }

    // MARK: - Onboarding Draft

    static var onboardingAge: String {
        get { shared.string(forKey: "onboardingAge") ?? "" }
        set { shared.set(newValue, forKey: "onboardingAge") }
    }

    static var onboardingHeightCm: String {
        get { shared.string(forKey: "onboardingHeightCm") ?? "" }
        set { shared.set(newValue, forKey: "onboardingHeightCm") }
    }

    static var onboardingWeightKg: String {
        get { shared.string(forKey: "onboardingWeightKg") ?? "" }
        set { shared.set(newValue, forKey: "onboardingWeightKg") }
    }

    static var onboardingGender: CalorieCalculator.Gender {
        get {
            let rawValue = shared.string(forKey: "onboardingGender") ?? CalorieCalculator.Gender.male.rawValue
            return CalorieCalculator.Gender(rawValue: rawValue) ?? .male
        }
        set { shared.set(newValue.rawValue, forKey: "onboardingGender") }
    }

    static var onboardingActivityLevel: CalorieCalculator.ActivityLevel {
        get {
            let rawValue = shared.string(forKey: "onboardingActivityLevel") ?? CalorieCalculator.ActivityLevel.moderatelyActive.rawValue
            return CalorieCalculator.ActivityLevel(rawValue: rawValue) ?? .moderatelyActive
        }
        set { shared.set(newValue.rawValue, forKey: "onboardingActivityLevel") }
    }

    static var onboardingCustomGoal: String {
        get { shared.string(forKey: "onboardingCustomGoal") ?? "" }
        set { shared.set(newValue, forKey: "onboardingCustomGoal") }
    }

    static func clearOnboardingProfileDraft() {
        [
            "onboardingAge",
            "onboardingHeightCm",
            "onboardingWeightKg",
            "onboardingGender",
            "onboardingActivityLevel",
            "onboardingCustomGoal"
        ].forEach { shared.removeObject(forKey: $0) }
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

    enum LLMProvider: String, CaseIterable, Identifiable {
        case openRouter = "OpenRouter"
        case custom = "Custom OpenAI-compatible"
        case blockRun = "BlockRun AI (Beta)"

        var id: String { self.rawValue }
    }

    static var llmProvider: LLMProvider {
        get {
            let rawValue = shared.string(forKey: "llmProvider") ?? LLMProvider.custom.rawValue
            return LLMProvider(rawValue: rawValue) ?? .openRouter
        }
        set { shared.set(newValue.rawValue, forKey: "llmProvider") }
    }

    // MARK: - API Keys (Stored in Keychain for security)

    static var openRouterApiKey: String {
        get { (try? KeychainHelper.shared.read(service: "com.ivan.Portio", account: "openRouterApiKey")) ?? "" }
        set { try? KeychainHelper.shared.save(newValue, service: "com.ivan.Portio", account: "openRouterApiKey") }
    }

    static var serperApiKey: String {
        get { (try? KeychainHelper.shared.read(service: "com.ivan.Portio", account: "serperApiKey")) ?? "" }
        set { try? KeychainHelper.shared.save(newValue, service: "com.ivan.Portio", account: "serperApiKey") }
    }

    // MARK: - Model Name

    static var modelName: String {
        get { shared.string(forKey: "modelName") ?? "" }
        set { shared.set(newValue, forKey: "modelName") }
    }

    // MARK: - Custom API Provider

    static var customApiBaseUrl: String {
        get { shared.string(forKey: "customApiBaseUrl") ?? "" }
        set { shared.set(newValue, forKey: "customApiBaseUrl") }
    }

    // MARK: - BlockRun AI

    static var isBlockRunEnabled: Bool {
        get { shared.bool(forKey: "isBlockRunEnabled") }
        set { shared.set(newValue, forKey: "isBlockRunEnabled") }
    }

    static var blockRunWalletId: String {
        get { (try? KeychainHelper.shared.read(service: "com.ivan.Portio", account: "blockRunWalletId")) ?? "" }
        set { try? KeychainHelper.shared.save(newValue, service: "com.ivan.Portio", account: "blockRunWalletId") }
    }

    static var blockRunProxyUrl: String {
        get { shared.string(forKey: "blockRunProxyUrl") ?? "https://blockrun.ai/api/v1" }
        set { shared.set(newValue, forKey: "blockRunProxyUrl") }
    }

    static var hasShownBlockRunPrompt: Bool {
        get { shared.bool(forKey: "hasShownBlockRunPrompt") }
        set { shared.set(newValue, forKey: "hasShownBlockRunPrompt") }
    }
}
