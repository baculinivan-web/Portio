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
    @State private var isOpenRouterKeyVisible = false
    @State private var isSerperKeyVisible = false
    
    private var nutritionService: NutritionService {
        let apiKey = openRouterApiKey.isEmpty ? (APIKeyManager.getOpenRouterAPIKey() ?? "") : openRouterApiKey
        let serperKey = serperApiKey.isEmpty ? (APIKeyManager.getSerperAPIKey() ?? "") : serperApiKey
        let model = modelName.isEmpty ? (APIKeyManager.getModelName() ?? "openai/gpt-oss-120b:free") : modelName
        return NutritionService(apiKey: apiKey, modelName: model, serperApiKey: serperKey)
    }
    
    private var isFormValid: Bool {
        !age.isEmpty && !height.isEmpty && !weight.isEmpty &&
        Int(age) != nil && Double(height) != nil && Double(weight) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Stats") {
                    TextField("e.g. 28", text: $age).keyboardType(.numberPad)
                    TextField("e.g. 175", text: $height).keyboardType(.decimalPad)
                    TextField("e.g. 70", text: $weight).keyboardType(.decimalPad)
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
                
                Section {
                    Button("Calculate My Goals", action: calculateGoals)
                        .disabled(!isFormValid)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Welcome to CalCal")
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
                
                let goals = try await nutritionService.fetchAIGoals(userStats: userStats, userGoals: customGoal, baselineTDEE: tdee)
                
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