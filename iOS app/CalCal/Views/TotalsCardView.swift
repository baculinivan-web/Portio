import SwiftUI

struct TotalsCardView: View {
    // These values are now passed in from the ContentView
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    
    let calorieGoal: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double

    private var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(calories / calorieGoal, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(calories, format: .number.precision(.fractionLength(0)))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .contentTransition(.numericText(value: calories))
                
                Text("/ \(calorieGoal, format: .number.precision(.fractionLength(0))) kcal")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.1))
                    Capsule().fill(.primary)
                        .frame(width: geo.size.width * calorieProgress)
                        .animation(.spring, value: calorieProgress)
                }
            }
            .frame(height: 8)

            HStack {
                NutrientView(name: "Protein", value: protein, goal: proteinGoal)
                Spacer()
                NutrientView(name: "Carbs", value: carbs, goal: carbsGoal)
                Spacer()
                NutrientView(name: "Fat", value: fat, goal: fatGoal)
            }
        }
        .padding(.vertical, 8)
    }
}
