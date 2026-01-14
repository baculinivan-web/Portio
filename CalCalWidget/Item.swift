import Foundation
import SwiftData

@Model
public final class FoodItem {
    @Attribute(.unique) public var id: UUID
    public var name: String // The user's original query
    public var identifiedFood: String
    public var cleanFoodName: String // The simple name for display
    public var dateEaten: Date
    public var isProcessing: Bool
    public var isSearchGrounded: Bool = false
    public var imageDatas: [Data] = []

    // Nutritional values for the current weight
    public var calories: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    
    // Weight and per-100g baseline values
    public var weightGrams: Double
    public var caloriesPer100g: Double
    public var proteinPer100g: Double
    public var carbsPer100g: Double
    public var fatPer100g: Double

    public init(name: String, identifiedFood: String, cleanFoodName: String, dateEaten: Date, isProcessing: Bool = false, isSearchGrounded: Bool = false, imageDatas: [Data] = [],
         calories: Double, protein: Double, carbs: Double, fat: Double,
         weightGrams: Double, caloriesPer100g: Double, proteinPer100g: Double, carbsPer100g: Double, fatPer100g: Double) {
        self.id = UUID()
        self.name = name
        self.identifiedFood = identifiedFood
        self.cleanFoodName = cleanFoodName
        self.dateEaten = dateEaten
        self.isProcessing = isProcessing
        self.isSearchGrounded = isSearchGrounded
        self.imageDatas = imageDatas
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.weightGrams = weightGrams
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
    }
    
    // Convenience initializer for the processing state
    public convenience init(name: String) {
        self.init(name: name, identifiedFood: "Analyzing...", cleanFoodName: name, dateEaten: .now, isProcessing: true, isSearchGrounded: false, imageDatas: [],
                  calories: 0, protein: 0, carbs: 0, fat: 0,
                  weightGrams: 0, caloriesPer100g: 0, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 0)
    }
    
    public func recalculateNutrients() {
        let ratio = weightGrams / 100.0
        calories = caloriesPer100g * ratio
        protein = proteinPer100g * ratio
        carbs = carbsPer100g * ratio
        fat = fatPer100g * ratio
    }
}