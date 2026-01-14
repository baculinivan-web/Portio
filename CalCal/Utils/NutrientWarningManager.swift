import Foundation

enum WarningNutrient: String, CaseIterable {
    case calories = "Calories"
    case carbs = "Carbs"
    case fat = "Fat"
    
    var unit: String {
        switch self {
        case .calories: return "kcal"
        default: return "g"
        }
    }
}

class NutrientWarningManager {
    static func shouldTriggerWarning(intake: Double, goal: Double, date: Date = Date()) -> Bool {
        guard goal > 0 else { return false }
        let percentage = intake / goal
        
        if percentage > 1.0 {
            return true
        }
        
        if percentage >= 0.95 {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            return hour < 17
        }
        
        return false
    }
    
    static func getTopContributors(for nutrient: WarningNutrient, in items: [FoodItem], count: Int = 2) -> [FoodItem] {
        return items.filter { !$0.isProcessing }.sorted { item1, item2 in
            switch nutrient {
            case .calories: return item1.calories > item2.calories
            case .carbs: return item1.carbs > item2.carbs
            case .fat: return item1.fat > item2.fat
            }
        }.prefix(count).map { $0 }
    }
    
    static func getOvershootPercentage(intake: Double, goal: Double) -> Int {
        guard goal > 0, intake > goal else { return 0 }
        return Int(((intake - goal) / goal) * 100)
    }
}