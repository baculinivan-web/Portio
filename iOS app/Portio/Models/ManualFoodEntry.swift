import Foundation

struct ManualFoodEntry {
    static let maxCalories = 10_000.0
    static let maxWeightGrams = 10_000.0

    var name: String
    var weightGrams: Double
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    var isValid: Bool {
        !trimmedName.isEmpty
            && weightGrams.isFinite
            && calories.isFinite
            && protein.isFinite
            && carbs.isFinite
            && fat.isFinite
            && weightGrams > 0
            && weightGrams <= Self.maxWeightGrams
            && calories >= 0
            && calories <= Self.maxCalories
            && protein >= 0
            && carbs >= 0
            && fat >= 0
            && totalMacroGrams <= weightGrams
    }

    var totalMacroGrams: Double {
        protein + carbs + fat
    }

    func makeFoodItem(loggedAt date: Date = .now) -> FoodItem {
        let ratio = weightGrams / 100
        return FoodItem(
            name: trimmedName,
            identifiedFood: trimmedName,
            cleanFoodName: trimmedName,
            dateEaten: date,
            isProcessing: false,
            isSearchGrounded: false,
            dataSource: "Manual",
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            weightGrams: weightGrams,
            caloriesPer100g: ratio > 0 ? calories / ratio : 0,
            proteinPer100g: ratio > 0 ? protein / ratio : 0,
            carbsPer100g: ratio > 0 ? carbs / ratio : 0,
            fatPer100g: ratio > 0 ? fat / ratio : 0
        )
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
