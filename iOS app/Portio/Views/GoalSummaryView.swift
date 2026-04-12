import SwiftUI

struct GoalSummaryView: View {
    // This view reads the goals directly from UserSettings
    @AppStorage("calorieGoal") private var calorieGoal: Double = UserSettings.calorieGoal
    @AppStorage("proteinGoal") private var proteinGoal: Double = UserSettings.proteinGoal
    @AppStorage("carbsGoal") private var carbsGoal: Double = UserSettings.carbsGoal
    @AppStorage("fatGoal") private var fatGoal: Double = UserSettings.fatGoal
    @AppStorage("goalExplanation") private var goalExplanation: String = UserSettings.goalExplanation
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Here Are Your Personalized Goals!")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 20)

                VStack {
                    Text(String(format: "%.0f", calorieGoal))
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("kcal / day")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)
                
                HStack(spacing: 20) {
                    NutrientGoalView(name: "Protein", value: proteinGoal)
                    NutrientGoalView(name: "Carbs", value: carbsGoal)
                    NutrientGoalView(name: "Fat", value: fatGoal)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("AI Recommendation")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(goalExplanation)
                        .font(.body)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
        }
        
        // Button is placed outside the ScrollView to stick to the bottom
        .safeAreaInset(edge: .bottom) {
            Button("Get Started") {
                dismiss()
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .padding()
            .background(.ultraThinMaterial)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// A new private view for displaying individual macro goals
private struct NutrientGoalView: View {
    let name: String
    let value: Double
    
    var body: some View {
        VStack {
            Text(String(format: "%.0f g", value))
                .font(.title2.weight(.semibold))
                .fontDesign(.rounded)
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
