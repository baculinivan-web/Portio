import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("calorieGoal", store: UserSettings.shared) private var calorieGoal: Double = UserSettings.calorieGoal
    @AppStorage("proteinGoal", store: UserSettings.shared) private var proteinGoal: Double = UserSettings.proteinGoal
    @AppStorage("carbsGoal", store: UserSettings.shared) private var carbsGoal: Double = UserSettings.carbsGoal
    @AppStorage("fatGoal", store: UserSettings.shared) private var fatGoal: Double = UserSettings.fatGoal
    @AppStorage("weightGoalMode", store: UserSettings.shared) private var weightGoalModeRaw: String = UserSettings.weightGoalMode.rawValue
    @AppStorage("isAppleHealthSyncEnabled", store: UserSettings.shared) private var isAppleHealthSyncEnabled: Bool = UserSettings.isAppleHealthSyncEnabled
    @AppStorage("goalExplanation", store: UserSettings.shared) private var goalExplanation: String = UserSettings.goalExplanation

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Nutritional Goals") {
                    Picker("Goal Type", selection: $weightGoalModeRaw) {
                        ForEach(UserSettings.WeightGoalMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    NutrientEditor(label: "Calories (kcal)", value: $calorieGoal)
                    NutrientEditor(label: "Protein (g)", value: $proteinGoal)
                    NutrientEditor(label: "Carbs (g)", value: $carbsGoal)
                    NutrientEditor(label: "Fat (g)", value: $fatGoal)
                }

                Section("Integrations") {
                    Toggle("Apple Health Sync", isOn: $isAppleHealthSyncEnabled)
                        .onChange(of: isAppleHealthSyncEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    try? await HealthKitManager.shared.requestAuthorization()
                                }
                            }
                        }
                }
                
                if !goalExplanation.isEmpty {
                    Section("Your AI Goal Recommendation") {
                        Text(goalExplanation)
                    }
                }

                Section("Recalculate") {
                    Button("Recalculate Personal Goals") {
                        // By setting this flag to false, the onboarding view will appear
                        // automatically when this sheet is dismissed.
                        UserSettings.hasCompletedOnboarding = false
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: calorieGoal) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: proteinGoal) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: carbsGoal) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: fatGoal) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}