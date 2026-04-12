import XCTest
@testable import CalCal

class MacroCardLogicTests: XCTestCase {
    
    func testFilteringAndSorting() {
        let items = [
            FoodItem(name: "Apple", identifiedFood: "Apple", cleanFoodName: "Apple", dateEaten: .now, calories: 95, protein: 0.5, carbs: 25, fat: 0.3, weightGrams: 180, caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2),
            FoodItem(name: "Egg", identifiedFood: "Egg", cleanFoodName: "Egg", dateEaten: .now, calories: 70, protein: 6, carbs: 0.6, fat: 5, weightGrams: 50, caloriesPer100g: 140, proteinPer100g: 12, carbsPer100g: 1.2, fatPer100g: 10)
        ]
        
        // This is what I'll implement in the card
        func filterItems(title: String, items: [FoodItem]) -> [(name: String, value: Double)] {
            items.compactMap { item in
                let val: Double
                switch title.lowercased() {
                case "calories": val = item.calories
                case "protein": val = item.protein
                case "carbs": val = item.carbs
                case "fat": val = item.fat
                default: val = 0
                }
                return val > 0 ? (name: item.cleanFoodName, value: val) : nil
            }.sorted { $0.value > $1.value }
        }
        
        let proteinList = filterItems(title: "Protein", items: items)
        XCTAssertEqual(proteinList.count, 2)
        XCTAssertEqual(proteinList[0].name, "Egg")
        XCTAssertEqual(proteinList[0].value, 6)
        
        let carbsList = filterItems(title: "Carbs", items: items)
        XCTAssertEqual(carbsList.count, 2)
        XCTAssertEqual(carbsList[0].name, "Apple")
        XCTAssertEqual(carbsList[0].value, 25)
    }
}
