import SwiftUI
import SwiftData

struct OnboardingView: View {
    // This callback will be triggered when onboarding is complete.
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var age: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var gender = CalorieCalculator.Gender.male
    @State private var activityLevel = CalorieCalculator.ActivityLevel.moderatelyActive
    @State private var weightGoalMode = UserSettings.WeightGoalMode.maintain
    @State private var customGoal: String = ""
    @State private var isHealthSyncEnabled = true

    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var openRouterApiKey: String = ""
    @State private var serperApiKey: String = ""
    @State private var modelName: String = ""
    @State private var customApiBaseUrl: String = ""
    @State private var blockRunWalletId: String = ""
    @State private var blockRunProxyUrl: String = UserSettings.blockRunProxyUrl
    @State private var llmProvider: UserSettings.LLMProvider = .openRouter

    @State private var isOpenRouterKeyVisible = false
    @State private var isSerperKeyVisible = false
    @State private var isWalletIdVisible = false

    private var nutritionService: NutritionService {
        let apiKey = openRouterApiKey.isEmpty ? (APIKeyManager.getOpenRouterAPIKey() ?? "") : openRouterApiKey
        let serperKey = serperApiKey.isEmpty ? (APIKeyManager.getSerperAPIKey() ?? "") : serperApiKey

        let model: String
        let customBaseURL: String?
        let provider = llmProvider

        if provider == .blockRun {
            model = modelName.isEmpty ? "nvidia/mistral-small-4-119b" : modelName
            customBaseURL = nil
        } else {
            model = modelName.isEmpty ? (APIKeyManager.getModelName() ?? "openai/gpt-oss-120b:free") : modelName
            customBaseURL = customApiBaseUrl.isEmpty ? UserSettings.customApiBaseUrl : customApiBaseUrl
        }

        return NutritionService(apiKey: apiKey, modelName: model, serperApiKey: serperKey, customBaseURL: customBaseURL, provider: provider)
    }

    private var isFormValid: Bool {
        !age.isEmpty && !height.isEmpty && !weight.isEmpty &&
        Int(age) != nil && Double(height) != nil && Double(weight) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Stats") {
                    LabeledContent("Age") {
                        TextField("e.g. 28", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Height (cm)") {
                        TextField("e.g. 175", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Weight (kg)") {
                        TextField("e.g. 70", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Gender", selection: $gender) {
                        ForEach(CalorieCalculator.Gender.allCases) { Text($0.rawValue) }
                    }
                }

                Section("Activity Level") {
                    Picker("Activity", selection: $activityLevel) {
                        ForEach(CalorieCalculator.ActivityLevel.allCases) { Text($0.rawValue) }
                    }
                }

                Section("Weight Goal") {
                    Picker("Goal", selection: $weightGoalMode) {
                        ForEach(UserSettings.WeightGoalMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Your Goals (e.g., lose weight, build muscle)") {
                    TextEditor(text: $customGoal)
                        .frame(height: 100)
                }

                Section("Integrations") {
                    Toggle(isOn: $isHealthSyncEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple Health Sync")
                            Text("Automatically log your nutrition data to Apple Health.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("AI Provider") {
                    Picker("Provider", selection: $llmProvider) {
                        ForEach(UserSettings.LLMProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if llmProvider == .openRouter {
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
                } else if llmProvider == .custom {
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
                } else if llmProvider == .blockRun {
                    Section {
                        TextField("https://blockrun.ai/api/v1", text: $blockRunProxyUrl)
                    } header: {
                        Text("API Endpoint")
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
                        Text("Leave blank to use the built-in key.")
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

                Section {
                    Button("Calculate My Goals", action: calculateGoals)
                        .disabled(!isFormValid)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Welcome to Portio")
            .fullScreenCover(isPresented: $isLoading) { LoadingView() }
            .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }

    private func calculateGoals() {
        guard let ageInt = Int(age), let heightCm = Double(height), let weightKg = Double(weight) else { return }

        isLoading = true

        let tdee = CalorieCalculator.calculateTDEE(weightKg: weightKg, heightCm: heightCm, age: ageInt, gender: gender, activityLevel: activityLevel)
        let userStats = "Age: \(ageInt), Height: \(heightCm)cm, Weight: \(weightKg)kg, Gender: \(gender.rawValue), Activity: \(activityLevel.rawValue)"

        Task {
            do {
                if isHealthSyncEnabled {
                    try? await HealthKitManager.shared.requestAuthorization()
                    await syncExistingData()
                }

                let goals = try await nutritionService.fetchAIGoals(userStats: userStats, userGoals: customGoal, baselineTdee: tdee)

                UserSettings.calorieGoal = goals.calories
                UserSettings.proteinGoal = goals.protein
                UserSettings.carbsGoal = goals.carbs
                UserSettings.fatGoal = goals.fat
                UserSettings.goalExplanation = goals.explanation
                UserSettings.weightGoalMode = weightGoalMode
                UserSettings.isAppleHealthSyncEnabled = isHealthSyncEnabled

                if !openRouterApiKey.isEmpty { UserSettings.openRouterApiKey = openRouterApiKey }
                if !serperApiKey.isEmpty { UserSettings.serperApiKey = serperApiKey }
                if !modelName.isEmpty { UserSettings.modelName = modelName }
                if !customApiBaseUrl.isEmpty { UserSettings.customApiBaseUrl = customApiBaseUrl }
                if !blockRunWalletId.isEmpty { UserSettings.blockRunWalletId = blockRunWalletId }
                if !blockRunProxyUrl.isEmpty { UserSettings.blockRunProxyUrl = blockRunProxyUrl }
                UserSettings.llmProvider = llmProvider

                isLoading = false
                onComplete() // Trigger the callback to notify ContentView

            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
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