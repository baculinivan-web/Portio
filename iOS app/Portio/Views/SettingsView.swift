import SwiftUI
import SwiftData
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
    @AppStorage("openRouterApiKey", store: UserSettings.shared) private var openRouterApiKey: String = UserSettings.openRouterApiKey
    @AppStorage("serperApiKey", store: UserSettings.shared) private var serperApiKey: String = UserSettings.serperApiKey
    @AppStorage("modelName", store: UserSettings.shared) private var modelName: String = UserSettings.modelName

    @State private var isOpenRouterKeyVisible = false
    @State private var isSerperKeyVisible = false

    @Environment(\.modelContext) private var modelContext

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
                                    await syncExistingData()
                                }
                            }
                        }
                }
                
                Section {
                    HStack {
                        if isOpenRouterKeyVisible {
                            TextField("sk-or-...", text: $openRouterApiKey)
                        } else {
                            SecureField("sk-or-...", text: $openRouterApiKey)
                        }
                        Button { isOpenRouterKeyVisible.toggle() } label: {
                            Image(systemName: isOpenRouterKeyVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("OpenRouter API Key")
                } footer: {
                    Text("Get your free key at openrouter.ai/keys — the free tier is sufficient for normal app usage.")
                }
                
                Section {
                    HStack {
                        if isSerperKeyVisible {
                            TextField("...", text: $serperApiKey)
                        } else {
                            SecureField("...", text: $serperApiKey)
                        }
                        Button { isSerperKeyVisible.toggle() } label: {
                            Image(systemName: isSerperKeyVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Serper API Key")
                } footer: {
                    Text("Get your free key at serper.dev — 2,500 free searches/month, enough for everyday use.")
                }
                
                Section("AI Model") {
                    TextField("e.g. google/gemini-flash-1.5", text: $modelName)
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

    private func syncExistingData() async {
        let descriptor = FetchDescriptor<FoodItem>()
        if let items = try? modelContext.fetch(descriptor) {
            await HealthKitManager.shared.syncAllData(items: items)
            try? modelContext.save()
        }
    }
}

#Preview {
    SettingsView()
}
