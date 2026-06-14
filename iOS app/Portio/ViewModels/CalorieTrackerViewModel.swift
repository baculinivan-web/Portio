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

        let model: String
        let customBaseURL: String?
        let provider = UserSettings.llmProvider

        if provider == .blockRun {
            model = UserSettings.modelName.isEmpty ? "nvidia/mistral-small-4-119b" : UserSettings.modelName
            customBaseURL = nil
        } else {
            model = UserSettings.modelName.isEmpty
                ? (APIKeyManager.getModelName() ?? "openai/gpt-oss-120b:free")
                : UserSettings.modelName
            customBaseURL = UserSettings.customApiBaseUrl
        }

        return NutritionService(apiKey: apiKey, modelName: model, serperApiKey: serperKey, customBaseURL: customBaseURL, provider: provider)
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
        _ = BackgroundTaskManager.shared.scheduleContinuedProcessingIfAvailable()

        let jobId = "foreground-\(UUID().uuidString)"
        processItem(placeholderItem, jobId: jobId, context: context)
    }

    func retryItem(_ item: FoodItem, context: ModelContext) {
        item.resetForRetry(jobId: nil, at: .now)
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        BackgroundTaskManager.shared.scheduleIfNeeded()
        _ = BackgroundTaskManager.shared.scheduleContinuedProcessingIfAvailable()

        let jobId = "foreground-\(UUID().uuidString)"
        _ = item.claimProcessingJob(id: jobId, at: .now)
        processItem(item, jobId: jobId, context: context)
    }

    func addManualItem(_ entry: ManualFoodEntry, context: ModelContext) {
        guard entry.isValid else { return }

        let item = entry.makeFoodItem()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            context.insert(item)
            try? context.save()
        }

        WidgetCenter.shared.reloadAllTimelines()

        guard UserSettings.isAppleHealthSyncEnabled else { return }
        Task {
            do {
                item.healthKitSampleUUIDs = try await HealthKitManager.shared.writeNutrition(for: item)
                try? context.save()
            } catch {
                item.markProcessingFailed("Saved locally, but Apple Health sync failed: \(error.localizedDescription)")
                errorMessage = item.processingErrorMessage
                try? context.save()
            }
        }
    }

    private func processItem(_ item: FoodItem, jobId: String, context: ModelContext) {
        let query = item.name
        let imageDatas = item.imageDatas

        Task {
            guard item.claimProcessingJob(id: jobId, at: .now) else { return }

            do {
                let nutritionDataArray = try await nutritionService.fetchNutrition(for: query, images: imageDatas)

                guard let firstItemData = nutritionDataArray.first else {
                    item.markProcessingFailed("No nutrition data was returned.")
                    try? context.save()
                    WidgetCenter.shared.reloadAllTimelines()
                    return
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    apply(firstItemData, to: item)
                    item.markProcessingFinished()
                }

                if UserSettings.isAppleHealthSyncEnabled {
                    do {
                        item.healthKitSampleUUIDs = try await HealthKitManager.shared.writeNutrition(for: item)
                    } catch {
                        item.markProcessingFailed("Saved locally, but Apple Health sync failed: \(error.localizedDescription)")
                        errorMessage = item.processingErrorMessage
                    }
                }

                for itemData in nutritionDataArray.dropFirst() {
                    let newItem = makeFoodItem(from: itemData, originalQuery: query)
                    context.insert(newItem)

                    if UserSettings.isAppleHealthSyncEnabled {
                        do {
                            newItem.healthKitSampleUUIDs = try await HealthKitManager.shared.writeNutrition(for: newItem)
                        } catch {
                            newItem.markProcessingFailed("Saved locally, but Apple Health sync failed: \(error.localizedDescription)")
                            errorMessage = newItem.processingErrorMessage
                        }
                    }
                }

                try? context.save()
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                errorMessage = error.localizedDescription
                item.markProcessingFailed(error.localizedDescription)
                try? context.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    private func apply(_ data: NutritionResponse, to item: FoodItem) {
        item.identifiedFood = data.identifiedFood
        item.cleanFoodName = data.cleanFoodName
        item.calories = data.calories
        item.protein = data.protein
        item.carbs = data.carbs
        item.fat = data.fat
        item.weightGrams = data.estimatedWeightGrams
        item.caloriesPer100g = data.caloriesPer100g
        item.proteinPer100g = data.proteinPer100g
        item.carbsPer100g = data.carbsPer100g
        item.fatPer100g = data.fatPer100g
        item.isSearchGrounded = data.isSearchGrounded ?? false
        item.dataSource = data.dataSource
        item.searchSteps = data.searchSteps ?? []
    }

    private func makeFoodItem(from data: NutritionResponse, originalQuery: String) -> FoodItem {
        FoodItem(
            name: originalQuery,
            identifiedFood: data.identifiedFood,
            cleanFoodName: data.cleanFoodName,
            dateEaten: .now,
            isProcessing: false,
            isSearchGrounded: data.isSearchGrounded ?? false,
            dataSource: data.dataSource,
            searchSteps: data.searchSteps ?? [],
            calories: data.calories,
            protein: data.protein,
            carbs: data.carbs,
            fat: data.fat,
            weightGrams: data.estimatedWeightGrams,
            caloriesPer100g: data.caloriesPer100g,
            proteinPer100g: data.proteinPer100g,
            carbsPer100g: data.carbsPer100g,
            fatPer100g: data.fatPer100g
        )
    }
}
