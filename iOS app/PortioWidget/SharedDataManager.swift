import Foundation
import SwiftData

public class SharedDataManager {
    public static let shared = SharedDataManager()

    public let container: ModelContainer

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([FoodItem.self])
        let modelConfiguration: ModelConfiguration

        if inMemory {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ivan.Portio") {
            let sqliteURL = groupURL.appendingPathComponent("default.store")
            modelConfiguration = ModelConfiguration(schema: schema, url: sqliteURL)
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }

    private init() {
        do {
            container = try Self.makeContainer()
        } catch {
            SharedDataDiagnostics.log("Could not create persistent ModelContainer: \(error)")
            do {
                container = try Self.makeContainer(inMemory: true)
            } catch {
                fatalError("Could not create fallback ModelContainer: \(error)")
            }
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
                && item.isProcessing == false
                && item.processingErrorMessage == nil
        }

        let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)

        do {
            let items = try context.fetch(descriptor)
            let completedItems = items.filter { !$0.hasFailedProcessing }
            let calories = completedItems.reduce(0) { $0 + $1.calories }
            let protein = completedItems.reduce(0) { $0 + $1.protein }
            let carbs = completedItems.reduce(0) { $0 + $1.carbs }
            let fat = completedItems.reduce(0) { $0 + $1.fat }

            return NutritionStats(date: startOfDay, calories: calories, protein: protein, carbs: carbs, fat: fat)
        } catch {
            SharedDataDiagnostics.log("Failed to fetch today's stats: \(error.localizedDescription)")
            return NutritionStats(date: startOfDay, calories: 0, protein: 0, carbs: 0, fat: 0)
        }
    }

    @MainActor
    public func hasLoggedToday() -> Bool {
        let context = container.mainContext
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = #Predicate<FoodItem> { item in
            item.dateEaten >= startOfDay && item.dateEaten < endOfDay
        }

        var descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
        descriptor.fetchLimit = 1

        do {
            let count = try context.fetchCount(descriptor)
            return count > 0
        } catch {
            return false
        }
    }
}

private enum SharedDataDiagnostics {
    static func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[SharedDataManager] \(message())")
        #endif
    }
}
