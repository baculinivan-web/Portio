import SwiftUI

struct NutrientWarningDetailView: View {
    let triggeredWarnings: [WarningType]
    let todaysItems: [FoodItem]
    let totals: (calories: Double, protein: Double, carbs: Double, fat: Double)
    let goals: (calories: Double, protein: Double, carbs: Double, fat: Double)
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(triggeredWarnings, id: \.self) { warning in
                        let nutrient = getNutrient(from: warning)
                        VStack(alignment: .leading, spacing: 20) {
                            // Header with overshoot/imbalance info
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(nutrient.rawValue.uppercased())
                                        .font(.system(.caption, design: .rounded))
                                        .fontWeight(.heavy)
                                        .foregroundColor(getNutrientColor(nutrient))
                                    
                                    switch warning {
                                    case .overshoot:
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
                                    case .imbalance:
                                        let intake = getIntake(for: nutrient)
                                        let goal = getGoal(for: nutrient)
                                        if let gap = NutrientWarningManager.getImbalanceGap(intake: intake, goal: goal, proteinIntake: totals.protein, proteinGoal: goals.protein) {
                                            Text("\(gap)% Nutrient Imbalance")
                                                .font(.system(.title2, design: .rounded))
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                            
                                            Text("Relative to Protein intake")
                                                .font(.system(.subheadline, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            
                            // Explanation
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Context")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                
                                Text(getExplanation(for: warning))
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
    
    private func getNutrient(from warning: WarningType) -> WarningNutrient {
        switch warning {
        case .overshoot(let n): return n
        case .imbalance(let n): return n
        }
    }
    
    private func getIntake(for nutrient: WarningNutrient) -> Double {
        switch nutrient {
        case .calories: return totals.calories
        case .protein: return totals.protein
        case .carbs: return totals.carbs
        case .fat: return totals.fat
        }
    }
    
    private func getGoal(for nutrient: WarningNutrient) -> Double {
        switch nutrient {
        case .calories: return goals.calories
        case .protein: return goals.protein
        case .carbs: return goals.carbs
        case .fat: return goals.fat
        }
    }
    
    private func getNutrientValue(_ item: FoodItem, _ nutrient: WarningNutrient) -> Double {
        switch nutrient {
        case .calories: return item.calories
        case .protein: return item.protein
        case .carbs: return item.carbs
        case .fat: return item.fat
        }
    }
    
    private func getNutrientColor(_ nutrient: WarningNutrient) -> Color {
        switch nutrient {
        case .calories: return .orange
        case .protein: return .red
        case .carbs: return .blue
        case .fat: return .green
        }
    }
    
    private func getExplanation(for warning: WarningType) -> String {
        switch warning {
        case .overshoot(let nutrient):
            switch nutrient {
            case .calories:
                return "Consuming more calories than your body needs leads to weight gain. It's important to balance energy intake with your activity levels to maintain a healthy metabolism."
            case .protein:
                return "Protein is essential for muscle maintenance and recovery. A balanced intake ensures your body has the building blocks it needs."
            case .carbs:
                return "Excessive carbohydrate intake, especially simple sugars, can cause rapid spikes in blood sugar and insulin levels, which may lead to energy crashes and increased fat storage."
            case .fat:
                return "While healthy fats are essential, they are calorie-dense. High fat intake can easily lead to exceeding your daily calorie goal and may impact cardiovascular health if saturated fats are high."
            }
        case .imbalance(let nutrient):
            var advice = ""
            if nutrient == .carbs {
                advice = "Consider reducing high-carb foods for the rest of the day. "
            } else if nutrient == .fat {
                advice = "Consider reducing high-fat foods for the rest of the day. "
            }
            return advice + "Try increasing protein-rich foods like chicken, eggs, or legumes to restore balance. A balanced nutrient intake supports stable energy levels and muscle maintenance."
        }
    }
}
