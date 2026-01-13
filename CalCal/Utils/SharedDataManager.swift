import Foundation
import SwiftData

public class SharedDataManager {
    public static let shared = SharedDataManager()
    
    public let container: ModelContainer
    
    private init() {
        let schema = Schema([FoodItem.self])
        let modelConfiguration: ModelConfiguration
        
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ivan.CalCal") {
            let sqliteURL = groupURL.appendingPathComponent("default.store")
            modelConfiguration = ModelConfiguration(schema: schema, url: sqliteURL)
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create Shared ModelContainer: \(error)")
        }
    }
    
    @MainActor
    public func fetchTodaysStats() -> NutritionStats {
        let context = container.mainContext
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<FoodItem> { item in
            item.dateEaten >= startOfDay && item.dateEaten < endOfDay
        }
        
        let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
        
        do {
            let items = try context.fetch(descriptor)
            let calories = items.reduce(0) { $0 + $1.calories }
            let protein = items.reduce(0) { $0 + $1.protein }
            let carbs = items.reduce(0) { $0 + $1.carbs }
            let fat = items.reduce(0) { $0 + $1.fat }
            
            return NutritionStats(date: startOfDay, calories: calories, protein: protein, carbs: carbs, fat: fat)
        } catch {
            print("Failed to fetch today's stats: \(error)")
            return NutritionStats(date: startOfDay, calories: 0, protein: 0, carbs: 0, fat: 0)
        }
    }
}
