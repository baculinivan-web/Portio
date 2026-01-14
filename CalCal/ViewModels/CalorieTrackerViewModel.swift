import SwiftUI
import Combine
import SwiftData
import WidgetKit

@MainActor
class CalorieTrackerViewModel: ObservableObject {
    @Published var errorMessage: String?

    private let nutritionService = NutritionService()

    func addItem(query: String, imageDatas: [Data] = [], context: ModelContext) {
        let placeholderItem = FoodItem(name: query)
        placeholderItem.imageDatas = imageDatas
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            context.insert(placeholderItem)
            try? context.save()
        }
        WidgetCenter.shared.reloadAllTimelines()

        Task {
            do {
                let nutritionDataArray = try await nutritionService.fetchNutrition(for: query, images: imageDatas)
                
                guard let firstItemData = nutritionDataArray.first else {
                    context.delete(placeholderItem)
                    return
                }
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        // Update placeholder with the first item's data
                        placeholderItem.identifiedFood = firstItemData.identifiedFood
                        placeholderItem.cleanFoodName = firstItemData.cleanFoodName
                        placeholderItem.calories = firstItemData.calories
                        placeholderItem.protein = firstItemData.protein
                        placeholderItem.carbs = firstItemData.carbs
                        placeholderItem.fat = firstItemData.fat
                        placeholderItem.weightGrams = firstItemData.estimatedWeightGrams
                        placeholderItem.caloriesPer100g = firstItemData.caloriesPer100g
                        placeholderItem.proteinPer100g = firstItemData.proteinPer100g
                        placeholderItem.carbsPer100g = firstItemData.carbsPer100g
                        placeholderItem.fatPer100g = firstItemData.fatPer100g
                        placeholderItem.isProcessing = false
                        
                        // Create new records for any additional items
                        let remainingItemsData = nutritionDataArray.dropFirst()
                        for itemData in remainingItemsData {
                            let newItem = FoodItem(
                                name: query,
                                identifiedFood: itemData.identifiedFood,
                                cleanFoodName: itemData.cleanFoodName,
                                dateEaten: .now,
                                calories: itemData.calories,
                                protein: itemData.protein,
                                carbs: itemData.carbs,
                                fat: itemData.fat,
                                weightGrams: itemData.estimatedWeightGrams,
                                caloriesPer100g: itemData.caloriesPer100g,
                                proteinPer100g: itemData.proteinPer100g,
                                carbsPer100g: itemData.carbsPer100g,
                                fatPer100g: itemData.fatPer100g
                            )
                            context.insert(newItem)
                        }
                        
                        try? context.save()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
                
            } catch {
                errorMessage = error.localizedDescription
                context.delete(placeholderItem)
            }
        }
    }
}