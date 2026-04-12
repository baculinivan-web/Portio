import XCTest
import SwiftData
@testable import Portio

@MainActor
class NutritionAggregatorTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var aggregator: NutritionAggregator!
    
    override func setUp() {
        super.setUp()
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(for: FoodItem.self, configurations: config)
            modelContext = modelContainer.mainContext
            aggregator = NutritionAggregator(modelContext: modelContext)
        } catch {
            XCTFail("Failed to create ModelContainer: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        aggregator = nil
        super.tearDown()
    }
    
    func testFetchStatsForSingleDay() throws {
        // Given
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            XCTFail("Could not calculate end of day")
            return
        }
        
        let item1 = FoodItem(name: "Item 1", identifiedFood: "Food", cleanFoodName: "Food", dateEaten: today, calories: 100, protein: 10, carbs: 10, fat: 5, weightGrams: 100, caloriesPer100g: 100, proteinPer100g: 10, carbsPer100g: 10, fatPer100g: 5)
        let item2 = FoodItem(name: "Item 2", identifiedFood: "Food", cleanFoodName: "Food", dateEaten: today, calories: 200, protein: 20, carbs: 20, fat: 10, weightGrams: 100, caloriesPer100g: 200, proteinPer100g: 20, carbsPer100g: 20, fatPer100g: 10)
        
        modelContext.insert(item1)
        modelContext.insert(item2)
        
        // When
        let stats = try aggregator.fetchStats(start: startOfDay, end: endOfDay)
        
        // Then
        XCTAssertEqual(stats.calories, 300)
        XCTAssertEqual(stats.protein, 30)
        XCTAssertEqual(stats.carbs, 30)
        XCTAssertEqual(stats.fat, 15)
    }
    
    func testAggregateStatsForWeek() throws {
        // Given
        let calendar = Calendar.current
        let today = Date()
        
        // Add items for the last 3 days
        for i in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let item = FoodItem(name: "Item \(i)", identifiedFood: "Food", cleanFoodName: "Food", dateEaten: date, calories: 100, protein: 10, carbs: 10, fat: 5, weightGrams: 100, caloriesPer100g: 100, proteinPer100g: 10, carbsPer100g: 10, fatPer100g: 5)
            modelContext.insert(item)
        }
        
        // When
        let stats = try aggregator.aggregateStats(for: .week)
        
        // Then
        // We expect 7 days of stats. The last 3 should have data, the others 0.
        XCTAssertEqual(stats.count, 7)
        
        // Check the last entry (today)
        XCTAssertEqual(stats.last?.calories, 100)
        
        // Check the entry 2 days ago
        let indexTwoDaysAgo = stats.count - 3
        XCTAssertEqual(stats[indexTwoDaysAgo].calories, 100)
        
        // Check an older entry (should be 0)
        XCTAssertEqual(stats.first?.calories, 0)
    }
}
