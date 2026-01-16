import Foundation

enum WarningNutrient: String, CaseIterable {
    case calories = "Calories"
    case carbs = "Carbs"
    case fat = "Fat"
    case protein = "Protein"
    
    var unit: String {
        switch self {
        case .calories: return "kcal"
        default: return "g"
        }
    }
}

enum WarningType: Hashable {
    case overshoot(WarningNutrient)
    case imbalance(WarningNutrient) // Which nutrient is higher than protein
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
    
    static func getImbalanceGap(intake: Double, goal: Double, proteinIntake: Double, proteinGoal: Double) -> Int? {
        guard goal > 0, proteinGoal > 0 else { return nil }
        
        let completion = intake / goal
        let proteinCompletion = proteinIntake / proteinGoal
        
        let gap = (completion - proteinCompletion) * 100
        
        if gap > 30 {
            return Int(gap)
        }
        
        return nil
    }
    
    static func getTopContributors(for nutrient: WarningNutrient, in items: [FoodItem], count: Int = 2) -> [FoodItem] {
        return items.filter { !$0.isProcessing }.sorted { item1, item2 in
            switch nutrient {
            case .calories: return item1.calories > item2.calories
            case .carbs: return item1.carbs > item2.carbs
            case .fat: return item1.fat > item2.fat
            case .protein: return item1.protein > item2.protein
            }
        }.prefix(count).map { $0 }
    }
    
    static func getOvershootPercentage(intake: Double, goal: Double) -> Int {
        guard goal > 0, intake > goal else { return 0 }
        return Int(((intake - goal) / goal) * 100)
    }
}