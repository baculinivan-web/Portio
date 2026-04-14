import Foundation
import BackgroundTasks
import SwiftData

/// Handles BGTaskScheduler registration and execution for completing
/// pending nutrition lookups when the app is in the background or closed.
class BackgroundTaskManager {

    static let shared = BackgroundTaskManager()
    static let taskIdentifier = "com.ivan.Portio.nutrition-processing"

    private init() {}

    // MARK: - Registration (call once at app launch)

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleProcessingTask(task as! BGProcessingTask)
        }
    }

    // MARK: - Schedule

    /// Call this whenever a new isProcessing item is inserted.
    func scheduleIfNeeded() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        // Run as soon as possible
        request.earliestBeginDate = nil

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[BGTask] Failed to schedule: \(error)")
        }
    }

    // MARK: - Execution

    private func handleProcessingTask(_ task: BGProcessingTask) {
        // Re-schedule for any items that might still be pending after this run
        scheduleIfNeeded()

        let taskHandle = Task {
            await processAllPendingItems()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            taskHandle.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - Core logic

    @MainActor
    private func processAllPendingItems() async {
        let context = SharedDataManager.shared.container.mainContext

        let predicate = #Predicate<FoodItem> { $0.isProcessing == true }
        let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)

        guard let pendingItems = try? context.fetch(descriptor), !pendingItems.isEmpty else {
            return
        }

        let apiKey = UserSettings.openRouterApiKey.isEmpty
            ? (APIKeyManager.getOpenRouterAPIKey() ?? "")
            : UserSettings.openRouterApiKey
        let serperKey = UserSettings.serperApiKey.isEmpty
            ? (APIKeyManager.getSerperAPIKey() ?? "")
            : UserSettings.serperApiKey
        let model = UserSettings.modelName.isEmpty
            ? (APIKeyManager.getModelName() ?? "openai/gpt-oss-120b:free")
            : UserSettings.modelName

        let service = NutritionService(apiKey: apiKey, modelName: model, serperApiKey: serperKey)

        for item in pendingItems {
            guard !Task.isCancelled else { break }
            do {
                let results = try await service.fetchNutrition(for: item.name, images: item.imageDatas)
                guard let first = results.first else {
                    context.delete(item)
                    continue
                }
                item.identifiedFood   = first.identifiedFood
                item.cleanFoodName    = first.cleanFoodName
                item.calories         = first.calories
                item.protein          = first.protein
                item.carbs            = first.carbs
                item.fat              = first.fat
                item.weightGrams      = first.estimatedWeightGrams
                item.caloriesPer100g  = first.caloriesPer100g
                item.proteinPer100g   = first.proteinPer100g
                item.carbsPer100g     = first.carbsPer100g
                item.fatPer100g       = first.fatPer100g
                item.isProcessing     = false
                item.isSearchGrounded = first.isSearchGrounded ?? false
                item.dataSource       = first.dataSource
                item.searchSteps      = first.searchSteps ?? []

                // Extra items
                for extra in results.dropFirst() {
                    let newItem = FoodItem(
                        name: item.name,
                        identifiedFood: extra.identifiedFood,
                        cleanFoodName: extra.cleanFoodName,
                        dateEaten: item.dateEaten,
                        isProcessing: false,
                        isSearchGrounded: extra.isSearchGrounded ?? false,
                        dataSource: extra.dataSource,
                        searchSteps: extra.searchSteps ?? [],
                        calories: extra.calories,
                        protein: extra.protein,
                        carbs: extra.carbs,
                        fat: extra.fat,
                        weightGrams: extra.estimatedWeightGrams,
                        caloriesPer100g: extra.caloriesPer100g,
                        proteinPer100g: extra.proteinPer100g,
                        carbsPer100g: extra.carbsPer100g,
                        fatPer100g: extra.fatPer100g
                    )
                    context.insert(newItem)
                }
            } catch {
                print("[BGTask] Failed to process '\(item.name)': \(error)")
                context.delete(item)
            }
        }

        try? context.save()
    }
}
