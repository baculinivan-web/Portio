import SwiftUI
import Combine
import SwiftData
import WidgetKit

@MainActor
class CalorieTrackerViewModel: ObservableObject {
    @Published var errorMessage: String?

    private var nutritionService: NutritionService {
        let apiKey = UserSettings.openRouterApiKey.isEmpty
            ? (APIKeyManager.getOpenRouterAPIKey() ?? "")
            : UserSettings.openRouterApiKey
        let serperKey = UserSettings.serperApiKey.isEmpty
            ? (APIKeyManager.getSerperAPIKey() ?? "")
            : UserSettings.serperApiKey
        let model = UserSettings.modelName.isEmpty
            ? (APIKeyManager.getModelName() ?? "openai/gpt-oss-120b:free")
            : UserSettings.modelName
        return NutritionService(apiKey: apiKey, modelName: model, serperApiKey: serperKey)
    }

    func addItem(query: String, imageDatas: [Data] = [], context: ModelContext) {
        let placeholderItem = FoodItem(name: query)
        placeholderItem.imageDatas = imageDatas
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            context.insert(placeholderItem)
            try? context.save()
        }
        WidgetCenter.shared.reloadAllTimelines()
        // Schedule background task in case the app is closed before the request completes
        BackgroundTaskManager.shared.scheduleIfNeeded()

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
                        placeholderItem.isSearchGrounded = firstItemData.isSearchGrounded ?? false
                        placeholderItem.dataSource = firstItemData.dataSource
                        placeholderItem.searchSteps = firstItemData.searchSteps ?? []
                        
                        // Sync first item to HealthKit if enabled
                        if UserSettings.isAppleHealthSyncEnabled {
                            Task {
                                if let uuids = try? await HealthKitManager.shared.writeNutrition(for: placeholderItem) {
                                    placeholderItem.healthKitSampleUUIDs = uuids
                                }
                            }
                        }
                        
                        // Create new records for any additional items
                        let remainingItemsData = nutritionDataArray.dropFirst()
                        for itemData in remainingItemsData {
                            let newItem = FoodItem(
                                name: query,
                                identifiedFood: itemData.identifiedFood,
                                cleanFoodName: itemData.cleanFoodName,
                                dateEaten: .now,
                                isProcessing: false,
                                isSearchGrounded: itemData.isSearchGrounded ?? false,
                                dataSource: itemData.dataSource,
                                searchSteps: itemData.searchSteps ?? [],
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
                            
                            // Sync new item to HealthKit if enabled
                            if UserSettings.isAppleHealthSyncEnabled {
                                Task {
                                    if let uuids = try? await HealthKitManager.shared.writeNutrition(for: newItem) {
                                        newItem.healthKitSampleUUIDs = uuids
                                    }
                                }
                            }
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