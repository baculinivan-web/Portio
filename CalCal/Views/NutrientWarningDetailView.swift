import SwiftUI

struct NutrientWarningDetailView: View {
    let triggeredNutrients: [WarningNutrient]
    let todaysItems: [FoodItem]
    let totals: (calories: Double, carbs: Double, fat: Double)
    let goals: (calories: Double, carbs: Double, fat: Double)
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(triggeredNutrients, id: \.self) { nutrient in
                        VStack(alignment: .leading, spacing: 20) {
                            // Header with overshoot info
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(nutrient.rawValue.uppercased())
                                        .font(.system(.caption, design: .rounded))
                                        .fontWeight(.heavy)
                                        .foregroundColor(getNutrientColor(nutrient))
                                    
                                    let intake = getIntake(for: nutrient)
                                    let goal = getGoal(for: nutrient)
                                    let overshoot = NutrientWarningManager.getOvershootPercentage(intake: intake, goal: goal)
                                    
                                    if overshoot > 0 {
                                        Text("\(overshoot)% Overshoot")
                                            .font(.system(.title2, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                        
                                        Text("+ \(Int(intake - goal)) \(nutrient.unit)")
                                            .font(.system(.headline, design: .rounded))
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Approaching Goal")
                                            .font(.system(.title2, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                    }
                                }
                                Spacer()
                            }
                            
                            // Explanation
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Context")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                
                                Text(getExplanation(for: nutrient))
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            
                            // Top Contributors
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Highest Impact Items")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                
                                let contributors = NutrientWarningManager.getTopContributors(for: nutrient, in: todaysItems, count: 3)
                                if contributors.isEmpty {
                                    Text("No items recorded yet.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(contributors) { item in
                                        HStack {
                                            Text(item.cleanFoodName)
                                                .font(.system(.subheadline, design: .rounded))
                                            Spacer()
                                            Text("\(Int(getNutrientValue(item, nutrient)))\(nutrient.unit)")
                                                .font(.system(.subheadline, design: .rounded).bold())
                                                .foregroundColor(getNutrientColor(nutrient))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.primary.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private func getIntake(for nutrient: WarningNutrient) -> Double {
        switch nutrient {
        case .calories: return totals.calories
        case .carbs: return totals.carbs
        case .fat: return totals.fat
        }
    }
    
    private func getGoal(for nutrient: WarningNutrient) -> Double {
        switch nutrient {
        case .calories: return goals.calories
        case .carbs: return goals.carbs
        case .fat: return goals.fat
        }
    }
    
    private func getNutrientValue(_ item: FoodItem, _ nutrient: WarningNutrient) -> Double {
        switch nutrient {
        case .calories: return item.calories
        case .carbs: return item.carbs
        case .fat: return item.fat
        }
    }
    
    private func getNutrientColor(_ nutrient: WarningNutrient) -> Color {
        switch nutrient {
        case .calories: return .orange
        case .carbs: return .blue
        case .fat: return .green
        }
    }
    
    private func getExplanation(for nutrient: WarningNutrient) -> String {
        switch nutrient {
        case .calories:
            return "Consuming more calories than your body needs leads to weight gain. It's important to balance energy intake with your activity levels to maintain a healthy metabolism."
        case .carbs:
            return "Excessive carbohydrate intake, especially simple sugars, can cause rapid spikes in blood sugar and insulin levels, which may lead to energy crashes and increased fat storage."
        case .fat:
            return "While healthy fats are essential, they are calorie-dense. High fat intake can easily lead to exceeding your daily calorie goal and may impact cardiovascular health if saturated fats are high."
        }
    }
}
