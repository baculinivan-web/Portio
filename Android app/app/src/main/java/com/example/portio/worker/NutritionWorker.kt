package com.example.portio.worker

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.portio.BuildConfig
import com.example.portio.data.local.FoodItemDao
import com.example.portio.data.preferences.UserSettings
import com.example.portio.data.remote.NutritionService
import com.example.portio.domain.model.toDomain
import com.example.portio.domain.model.toEntity
import com.example.portio.health.HealthConnectManager
import com.example.portio.widget.PortioWidget
import androidx.glance.appwidget.updateAll
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import kotlinx.coroutines.flow.first

/**
 * WorkManager worker that completes nutrition lookup for a food item.
 * Runs even if the app is closed — guaranteed by WorkManager.
 *
 * Input data keys:
 *   ITEM_ID  — Room primary key of the placeholder FoodItemEntity
 *   QUERY    — original user query string
 */
@HiltWorker
class NutritionWorker @AssistedInject constructor(
    @Assisted appContext: Context,
    @Assisted params: WorkerParameters,
    private val dao: FoodItemDao,
    private val nutritionService: NutritionService,
    private val userSettings: UserSettings,
    private val healthConnect: HealthConnectManager
) : CoroutineWorker(appContext, params) {

    companion object {
        const val KEY_ITEM_ID = "ITEM_ID"
        const val KEY_QUERY   = "QUERY"
    }

    override suspend fun doWork(): Result {
        val itemId = inputData.getString(KEY_ITEM_ID) ?: return Result.failure()
        val query  = inputData.getString(KEY_QUERY)   ?: return Result.failure()

        // If item was already resolved (e.g. app was open and finished it), skip
        val existing = dao.getById(itemId) ?: return Result.success()
        if (!existing.isProcessing) return Result.success()

        val modelName       = userSettings.modelName.first().ifBlank { BuildConfig.MODEL_NAME }
        val apiKey          = userSettings.openRouterApiKey.first().ifBlank { BuildConfig.OPENROUTER_API_KEY }
        val serperKey       = userSettings.serperApiKey.first().ifBlank { BuildConfig.SERPER_API_KEY }
        val customApiBaseUrl = userSettings.customApiBaseUrl.first()

        return try {
            val results = nutritionService.fetchNutrition(
                query = query,
                images = emptyList(),
                apiKey = apiKey,
                modelName = modelName,
                serperApiKey = serperKey,
                customApiBaseUrl = customApiBaseUrl
            )

            val firstResult = results.firstOrNull()
            if (firstResult == null) {
                dao.deleteById(itemId)
                return Result.success()
            }

            val first = firstResult.response
            val updated = existing.toDomain().copy(
                identifiedFood  = first.identifiedFood,
                cleanFoodName   = first.cleanFoodName,
                calories        = first.calories,
                protein         = first.protein,
                carbs           = first.carbs,
                fat             = first.fat,
                weightGrams     = first.estimatedWeightGrams,
                caloriesPer100g = first.caloriesPer100g,
                proteinPer100g  = first.proteinPer100g,
                carbsPer100g    = first.carbsPer100g,
                fatPer100g      = first.fatPer100g,
                isProcessing    = false,
                isSearchGrounded = first.isSearchGrounded ?: false,
                dataSource      = first.dataSource,
                searchSteps     = firstResult.searchSteps
            )
            dao.update(updated.toEntity())

            val hcId = healthConnect.writeNutrition(updated)
            if (hcId != null) dao.update(updated.copy(healthConnectIds = listOf(hcId)).toEntity())

            // Extra items returned by AI
            results.drop(1).forEach { itemResult ->
                val item = itemResult.response
                val extra = existing.toDomain().copy(
                    id              = java.util.UUID.randomUUID().toString(),
                    identifiedFood  = item.identifiedFood,
                    cleanFoodName   = item.cleanFoodName,
                    calories        = item.calories,
                    protein         = item.protein,
                    carbs           = item.carbs,
                    fat             = item.fat,
                    weightGrams     = item.estimatedWeightGrams,
                    caloriesPer100g = item.caloriesPer100g,
                    proteinPer100g  = item.proteinPer100g,
                    carbsPer100g    = item.carbsPer100g,
                    fatPer100g      = item.fatPer100g,
                    isProcessing    = false,
                    isSearchGrounded = item.isSearchGrounded ?: false,
                    dataSource      = item.dataSource,
                    searchSteps     = itemResult.searchSteps
                )
                dao.insert(extra.toEntity())
            }

            PortioWidget().updateAll(applicationContext)
            Result.success()
        } catch (e: Exception) {
            // Retry up to 3 times with exponential backoff (WorkManager default)
            if (runAttemptCount < 3) Result.retry() else {
                dao.deleteById(itemId)
                Result.failure()
            }
        }
    }
}
