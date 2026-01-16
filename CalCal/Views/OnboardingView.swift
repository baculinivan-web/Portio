import SwiftUI

struct OnboardingView: View {
    // This callback will be triggered when onboarding is complete.
    var onComplete: () -> Void

    @State private var age: String = "28"
    @State private var height: String = "175"
    @State private var weight: String = "70"
    @State private var gender = CalorieCalculator.Gender.male
    @State private var activityLevel = CalorieCalculator.ActivityLevel.moderatelyActive
    @State private var weightGoalMode = UserSettings.WeightGoalMode.maintain
    @State private var customGoal: String = "I want to maintain my current weight and feel energetic."
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let nutritionService = NutritionService()
    
    private var isFormValid: Bool {
        !age.isEmpty && !height.isEmpty && !weight.isEmpty &&
        Int(age) != nil && Double(height) != nil && Double(weight) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Stats") {
                    TextField("Age", text: $age).keyboardType(.numberPad)
                    TextField("Height (cm)", text: $height).keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $weight).keyboardType(.decimalPad)
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
                let goals = try await nutritionService.fetchAIGoals(userStats: userStats, userGoals: customGoal, baselineTDEE: tdee)
                
                UserSettings.calorieGoal = goals.calories
                UserSettings.proteinGoal = goals.protein
                UserSettings.carbsGoal = goals.carbs
                UserSettings.fatGoal = goals.fat
                UserSettings.goalExplanation = goals.explanation
                UserSettings.weightGoalMode = weightGoalMode
                
                isLoading = false
                onComplete() // Trigger the callback to notify ContentView
                
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}