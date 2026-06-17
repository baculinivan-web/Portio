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
    @AppStorage("modelName", store: UserSettings.shared) private var modelName: String = UserSettings.modelName
    @AppStorage("customApiBaseUrl", store: UserSettings.shared) private var customApiBaseUrl: String = UserSettings.customApiBaseUrl
    @AppStorage("llmProvider", store: UserSettings.shared) private var llmProviderRaw: String = UserSettings.llmProvider.rawValue
    @AppStorage("blockRunProxyUrl", store: UserSettings.shared) private var blockRunProxyUrl: String = UserSettings.blockRunProxyUrl
    @AppStorage("isCalorieCommentaryEnabled", store: UserSettings.shared) private var isCalorieCommentaryEnabled: Bool = UserSettings.isCalorieCommentaryEnabled
    @AppStorage("calorieCommentaryLevel", store: UserSettings.shared) private var calorieCommentaryLevelRaw: String = UserSettings.calorieCommentaryLevel.rawValue
    @AppStorage("isDayAnalysisEnabled", store: UserSettings.shared) private var isDayAnalysisEnabled: Bool = UserSettings.isDayAnalysisEnabled
    @AppStorage("isDayAnalysisAutomaticEnabled", store: UserSettings.shared) private var isDayAnalysisAutomaticEnabled: Bool = UserSettings.isDayAnalysisAutomaticEnabled

    @State private var openRouterApiKey: String = UserSettings.openRouterApiKey
    @State private var serperApiKey: String = UserSettings.serperApiKey
    @State private var blockRunWalletId: String = UserSettings.blockRunWalletId

    @State private var isOpenRouterKeyVisible = false
    @State private var isSerperKeyVisible = false
    @State private var isWalletIdVisible = false

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
                    Toggle("Show calorie remarks", isOn: $isCalorieCommentaryEnabled)

                    Picker("Cringe Level", selection: $calorieCommentaryLevelRaw) {
                        ForEach(UserSettings.CalorieCommentaryLevel.allCases) { level in
                            Text(level.rawValue).tag(level.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!isCalorieCommentaryEnabled)
                } header: {
                    Text("Calorie Commentary")
                } footer: {
                    Text("Crazy mode is intentionally rude, unserious roast text and may include profanity. It is not health advice, not a real judgment, and only appears because you chose it.")
                }

                Section {
                    Toggle("AI day analysis", isOn: $isDayAnalysisEnabled)
                    Toggle("Run automatically", isOn: $isDayAnalysisAutomaticEnabled)
                        .disabled(!isDayAnalysisEnabled)
                } header: {
                    Text("AI Analysis")
                } footer: {
                    Text("When automatic analysis is off, the card stays manual and runs only after you tap it.")
                }

                Section("AI Provider") {
                    Picker("Provider", selection: $llmProviderRaw) {
                        ForEach(UserSettings.LLMProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if llmProviderRaw == UserSettings.LLMProvider.openRouter.rawValue {
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

                    Section("Model") {
                        TextField("e.g. google/gemini-flash-1.5", text: $modelName)
                    }
                } else if llmProviderRaw == UserSettings.LLMProvider.custom.rawValue {
                    Section {
                        TextField("https://api.openai.com/v1", text: $customApiBaseUrl)
                    } header: {
                        Text("Base URL")
                    }

                    Section {
                        HStack {
                            if isOpenRouterKeyVisible {
                                TextField("API Key", text: $openRouterApiKey)
                            } else {
                                SecureField("API Key", text: $openRouterApiKey)
                            }
                            Button { isOpenRouterKeyVisible.toggle() } label: {
                                Image(systemName: isOpenRouterKeyVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("API Key")
                    }

                    Section("Model") {
                        TextField("e.g. gpt-4o", text: $modelName)
                    }
                } else if llmProviderRaw == UserSettings.LLMProvider.blockRun.rawValue {
                    Section {
                        TextField("https://blockrun.ai/api/v1", text: $blockRunProxyUrl)
                    } header: {
                        Text("API Endpoint")
                    } footer: {
                        Text("Default is https://blockrun.ai/api/v1. This cloud gateway connects directly to models.")
                    }

                    Section {
                        HStack {
                            if isWalletIdVisible {
                                TextField("0x...", text: $blockRunWalletId)
                            } else {
                                SecureField("0x...", text: $blockRunWalletId)
                            }
                            Button { isWalletIdVisible.toggle() } label: {
                                Image(systemName: isWalletIdVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Wallet Key / ID")
                    } footer: {
                        Text("Your wallet key used for Bearer authentication.")
                    }

                    Section("Model") {
                        Picker("Model", selection: $modelName) {
                            Text("GPT OSS 120B").tag("nvidia/gpt-oss-120b")
                            Text("GPT OSS 20B").tag("nvidia/gpt-oss-20b")
                            Text("DeepSeek V3.2").tag("nvidia/deepseek-v3.2")
                            Text("Qwen3 Coder 480B").tag("nvidia/qwen3-coder-480b")
                            Text("GLM 4.7").tag("nvidia/glm-4.7")
                            Text("Llama 4 Maverick").tag("nvidia/llama-4-maverick")
                            Text("Qwen3 Thinking").tag("nvidia/qwen3-next-80b-a3b-thinking")
                            Text("Mistral Small 4").tag("nvidia/mistral-small-4-119b")
                        }
                        .pickerStyle(.menu)
                    }
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

                if !goalExplanation.isEmpty {
                    Section("Your AI Goal Recommendation") {
                        Text(goalExplanation)
                    }
                }

                Section("Recalculate") {
                    Button("Recalculate Personal Goals") {
                        UserSettings.isReplayingOnboarding = true
                        UserSettings.hasCompletedOnboarding = false
                        dismiss()
                    }
                }

                Section("Onboarding") {
                    Button("Restart Onboarding") {
                        UserSettings.isReplayingOnboarding = true
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
            .onChange(of: openRouterApiKey) { _, newValue in UserSettings.openRouterApiKey = newValue }
            .onChange(of: serperApiKey) { _, newValue in UserSettings.serperApiKey = newValue }
            .onChange(of: blockRunWalletId) { _, newValue in UserSettings.blockRunWalletId = newValue }
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
