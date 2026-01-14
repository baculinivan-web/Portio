import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \FoodItem.dateEaten, order: .reverse) private var items: [FoodItem]
    
    @AppStorage("calorieGoal", store: UserSettings.shared) private var calorieGoal: Double = UserSettings.calorieGoal
    @AppStorage("proteinGoal", store: UserSettings.shared) private var proteinGoal: Double = UserSettings.proteinGoal
    @AppStorage("carbsGoal", store: UserSettings.shared) private var carbsGoal: Double = UserSettings.carbsGoal
    @AppStorage("fatGoal", store: UserSettings.shared) private var fatGoal: Double = UserSettings.fatGoal
    
    private var todaysItems: [FoodItem] {
        items.filter { Calendar.current.isDateInToday($0.dateEaten) }
    }
    
    private var totalCalories: Double { todaysItems.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { todaysItems.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { todaysItems.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { todaysItems.reduce(0) { $0 + $1.fat } }
    
    var body: some View {
        VStack(spacing: 20) {
            InteractiveMacroCard(
                title: "Calories",
                value: totalCalories,
                goal: calorieGoal,
                unit: "kcal",
                color: .orange,
                items: todaysItems
            )
            
            InteractiveMacroCard(
                title: "Protein",
                value: totalProtein,
                goal: proteinGoal,
                unit: "g",
                color: .red,
                items: todaysItems
            )
            
            InteractiveMacroCard(
                title: "Carbs",
                value: totalCarbs,
                goal: carbsGoal,
                unit: "g",
                color: .blue,
                items: todaysItems
            )
            
            InteractiveMacroCard(
                title: "Fat",
                value: totalFat,
                goal: fatGoal,
                unit: "g",
                color: .green,
                items: todaysItems
            )
        }
        .padding()
    }
}

#Preview {
    TodayView()
}
