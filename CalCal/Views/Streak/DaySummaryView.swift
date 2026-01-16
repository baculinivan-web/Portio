import SwiftUI
import SwiftData

struct DaySummaryView: View {
    let date: Date
    @Query private var items: [FoodItem]
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("calorieGoal", store: UserSettings.shared) private var calorieGoal: Double = UserSettings.calorieGoal
    @AppStorage("proteinGoal", store: UserSettings.shared) private var proteinGoal: Double = UserSettings.proteinGoal
    @AppStorage("carbsGoal", store: UserSettings.shared) private var carbsGoal: Double = UserSettings.carbsGoal
    @AppStorage("fatGoal", store: UserSettings.shared) private var fatGoal: Double = UserSettings.fatGoal
    
    init(date: Date) {
        self.date = date
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = #Predicate<FoodItem> { item in
            item.dateEaten >= start && item.dateEaten < end
        }
        _items = Query(filter: predicate, sort: \.dateEaten)
    }
    
    private var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { items.reduce(0) { $0 + $1.fat } }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TotalsCardView(
                        calories: totalCalories,
                        protein: totalProtein,
                        carbs: totalCarbs,
                        fat: totalFat,
                        calorieGoal: calorieGoal,
                        proteinGoal: proteinGoal,
                        carbsGoal: carbsGoal,
                        fatGoal: fatGoal
                    )
                }
                
                Section("Entries") {
                    if items.isEmpty {
                        Text("No entries for this day")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(items) { item in
                            FoodItemRowView(item: item)
                        }
                    }
                }
            }
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
