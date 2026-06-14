import Foundation
import BackgroundTasks
import SwiftData
import WidgetKit

/// Handles BGTaskScheduler registration and execution for completing
/// pending nutrition lookups when the app is in the background or closed.
class BackgroundTaskManager {

    static let shared = BackgroundTaskManager()
    static let processingTaskIdentifier = "com.ivan.Portio.nutrition-processing"
    static let continuedProcessingTaskIdentifier = "com.ivan.Portio.nutrition-continued-processing"
    static let continuedProcessingTitle = "Analyzing food"

    private var didRegisterContinuedProcessingTask = false
    private init() {}

    static func continuedProcessingSubtitle(completed: Int64, total: Int64) -> String {
        "\(completed) of \(total) records processed"
    }

    // MARK: - Registration (call once at app launch)

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                BackgroundDiagnostics.log("Received unexpected task type")
                return
            }

            self.handleProcessingTask(processingTask)
        }
    }

    // MARK: - Schedule

    /// Call this whenever a new isProcessing item is inserted.
    func scheduleIfNeeded() {
        let request = BGProcessingTaskRequest(identifier: Self.processingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        // Run as soon as possible
        request.earliestBeginDate = nil

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            BackgroundDiagnostics.log("Failed to schedule: \(error.localizedDescription)")
        }
    }

    /// Starts a user-initiated iOS 26 continued processing task when available.
    /// Returns false when the app should fall back to the foreground worker.
    @discardableResult
    func scheduleContinuedProcessingIfAvailable() -> Bool {
        guard #available(iOS 26.0, *) else {
            return false
        }

        registerContinuedProcessingTaskIfNeeded()

        let request = BGContinuedProcessingTaskRequest(
            identifier: Self.continuedProcessingTaskIdentifier,
            title: Self.continuedProcessingTitle,
            subtitle: Self.continuedProcessingSubtitle(completed: 0, total: 1)
        )
        request.strategy = .queue

        do {
            try BGTaskScheduler.shared.submit(request)
            return true
        } catch {
            BackgroundDiagnostics.log("Failed to schedule continued task: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Execution

    private func handleProcessingTask(_ task: BGProcessingTask) {
        let taskHandle = Task {
            let hasRemainingWork = await processAllPendingItems()
            if hasRemainingWork {
                scheduleIfNeeded()
            }
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            taskHandle.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    @available(iOS 26.0, *)
    private func registerContinuedProcessingTaskIfNeeded() {
        guard !didRegisterContinuedProcessingTask else { return }

        didRegisterContinuedProcessingTask = true
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.continuedProcessingTaskIdentifier,
            using: nil
        ) { task in
            guard let continuedTask = task as? BGContinuedProcessingTask else {
                task.setTaskCompleted(success: false)
                BackgroundDiagnostics.log("Received unexpected continued task type")
                return
            }

            self.handleContinuedProcessingTask(continuedTask)
        }
    }

    @available(iOS 26.0, *)
    private func handleContinuedProcessingTask(_ task: BGContinuedProcessingTask) {
        task.progress.totalUnitCount = 1
        task.progress.completedUnitCount = 0
        task.updateTitle(Self.continuedProcessingTitle, subtitle: Self.continuedProcessingSubtitle(completed: 0, total: 1))

        let taskHandle = Task {
            let hasRemainingWork = await processAllPendingItems { completed, total in
                task.progress.totalUnitCount = max(total, 1)
                task.progress.completedUnitCount = min(completed, task.progress.totalUnitCount)
                task.updateTitle(
                    Self.continuedProcessingTitle,
                    subtitle: Self.continuedProcessingSubtitle(
                        completed: task.progress.completedUnitCount,
                        total: task.progress.totalUnitCount
                    )
                )
            }

            guard !Task.isCancelled else {
                task.setTaskCompleted(success: false)
                return
            }

            if hasRemainingWork {
                scheduleIfNeeded()
            }

            task.updateTitle("Food analysis complete", subtitle: "Portio is up to date")
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            taskHandle.cancel()
        }
    }

    // MARK: - Core logic

    @MainActor
    private func processAllPendingItems(progress: ((Int64, Int64) -> Void)? = nil) async -> Bool {
        let context = SharedDataManager.shared.container.mainContext

        let predicate = #Predicate<FoodItem> { $0.isProcessing == true }
        let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)

        guard let pendingItems = try? context.fetch(descriptor), !pendingItems.isEmpty else {
            progress?(1, 1)
            return false
        }

        let total = Int64(pendingItems.count)
        var completed: Int64 = 0
        progress?(completed, total)

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

        let service = NutritionService(apiKey: apiKey, modelName: model, serperApiKey: serperKey, customBaseURL: customBaseURL, provider: provider)
        let jobId = "background-\(UUID().uuidString)"

        for item in pendingItems {
            guard !Task.isCancelled else { break }
            guard item.claimProcessingJob(id: jobId, at: .now) else {
                completed += 1
                progress?(completed, total)
                continue
            }

            do {
                let results = try await service.fetchNutrition(for: item.name, images: item.imageDatas)
                guard let first = results.first else {
                    item.markProcessingFailed("No nutrition data was returned.")
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
                item.isSearchGrounded = first.isSearchGrounded ?? false
                item.dataSource       = first.dataSource
                item.searchSteps      = first.searchSteps ?? []
                item.markProcessingFinished()

                if UserSettings.isAppleHealthSyncEnabled {
                    do {
                        item.healthKitSampleUUIDs = try await HealthKitManager.shared.writeNutrition(for: item)
                    } catch {
                        item.markProcessingFailed("Saved locally, but Apple Health sync failed: \(error.localizedDescription)")
                    }
                }

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

                    if UserSettings.isAppleHealthSyncEnabled {
                        do {
                            newItem.healthKitSampleUUIDs = try await HealthKitManager.shared.writeNutrition(for: newItem)
                        } catch {
                            newItem.markProcessingFailed("Saved locally, but Apple Health sync failed: \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                BackgroundDiagnostics.log("Failed to process item id=\(item.id.uuidString): \(error.localizedDescription)")
                item.markProcessingFailed(error.localizedDescription)
            }

            completed += 1
            progress?(completed, total)
        }

        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return hasPendingWork(context: context)
    }

    @MainActor
    private func hasPendingWork(context: ModelContext) -> Bool {
        let predicate = #Predicate<FoodItem> { $0.isProcessing == true }
        let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }
}

private enum BackgroundDiagnostics {
    private static let isEnabled = false

    static func log(_ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        #if DEBUG
        print("[BGTask] \(message())")
        #endif
    }
}
