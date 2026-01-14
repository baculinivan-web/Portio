import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("calorieGoal") private var calorieGoal: Double = UserSettings.calorieGoal
    @AppStorage("proteinGoal") private var proteinGoal: Double = UserSettings.proteinGoal
    @AppStorage("carbsGoal") private var carbsGoal: Double = UserSettings.carbsGoal
    @AppStorage("fatGoal") private var fatGoal: Double = UserSettings.fatGoal
    @AppStorage("goalExplanation") private var goalExplanation: String = UserSettings.goalExplanation

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Nutritional Goals") {
                    NutrientEditor(label: "Calories (kcal)", value: $calorieGoal)
                    NutrientEditor(label: "Protein (g)", value: $proteinGoal)
                    NutrientEditor(label: "Carbs (g)", value: $carbsGoal)
                    NutrientEditor(label: "Fat (g)", value: $fatGoal)
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