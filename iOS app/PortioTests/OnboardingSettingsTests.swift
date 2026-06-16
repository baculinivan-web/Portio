import Testing
import Foundation
@testable import Portio

struct OnboardingSettingsTests {
    @Test func openAICompatibleProviderIsTheDefaultAPIMode() {
        let previousProvider = UserSettings.shared.string(forKey: "llmProvider")
        defer {
            if let previousProvider {
                UserSettings.shared.set(previousProvider, forKey: "llmProvider")
            } else {
                UserSettings.shared.removeObject(forKey: "llmProvider")
            }
        }

        UserSettings.shared.removeObject(forKey: "llmProvider")

        #expect(UserSettings.llmProvider == .custom)
    }

    @Test func onboardingProfileDraftPersistsAcrossLaunches() {
        UserSettings.clearOnboardingProfileDraft()

        UserSettings.onboardingAge = "31"
        UserSettings.onboardingHeightCm = "181"
        UserSettings.onboardingWeightKg = "76.5"
        UserSettings.onboardingGender = .female
        UserSettings.onboardingActivityLevel = .veryActive
        UserSettings.onboardingCustomGoal = "Build muscle without losing energy"

        #expect(UserSettings.onboardingAge == "31")
        #expect(UserSettings.onboardingHeightCm == "181")
        #expect(UserSettings.onboardingWeightKg == "76.5")
        #expect(UserSettings.onboardingGender == .female)
        #expect(UserSettings.onboardingActivityLevel == .veryActive)
        #expect(UserSettings.onboardingCustomGoal == "Build muscle without losing energy")

        UserSettings.clearOnboardingProfileDraft()

        #expect(UserSettings.onboardingAge == "")
        #expect(UserSettings.onboardingHeightCm == "")
        #expect(UserSettings.onboardingWeightKg == "")
        #expect(UserSettings.onboardingGender == .male)
        #expect(UserSettings.onboardingActivityLevel == .moderatelyActive)
        #expect(UserSettings.onboardingCustomGoal == "")
    }

    @Test func replayingOnboardingCanBeMarkedSeparatelyFromCompletion() {
        let previousReplay = UserSettings.isReplayingOnboarding
        let previousCompletion = UserSettings.hasCompletedOnboarding
        defer {
            UserSettings.isReplayingOnboarding = previousReplay
            UserSettings.hasCompletedOnboarding = previousCompletion
        }

        UserSettings.hasCompletedOnboarding = false
        UserSettings.isReplayingOnboarding = true

        #expect(UserSettings.isReplayingOnboarding)
        #expect(!UserSettings.hasCompletedOnboarding)
    }
}
