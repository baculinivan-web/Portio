package com.example.calcal.data.repository

import android.content.Context
import com.example.calcal.BuildConfig
import com.example.calcal.data.local.FoodItemDao
import com.example.calcal.data.remote.NutritionService
import com.example.calcal.domain.model.FoodItem
import com.example.calcal.domain.model.GoalResponse
import com.example.calcal.domain.model.toDomain
import com.example.calcal.domain.model.toEntity
import com.example.calcal.data.preferences.UserSettings
import com.example.calcal.health.HealthConnectManager
import com.example.calcal.widget.CalCalWidget
import androidx.glance.appwidget.updateAll
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.util.Calendar
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FoodRepository @Inject constructor(
    private val dao: FoodItemDao,
    private val nutritionService: NutritionService,
    private val healthConnect: HealthConnectManager,
    private val userSettings: UserSettings,
    @ApplicationContext private val context: Context
) {
    fun getTodayItems(): Flow<List<FoodItem>> {
        val (start, end) = todayRange()
        return dao.getItemsForDay(start, end).map { list -> list.map { it.toDomain() } }
    }

    fun getAllItems(): Flow<List<FoodItem>> =
        dao.getAllItems().map { list -> list.map { it.toDomain() } }

    suspend fun countForDay(start: Long, end: Long): Int = dao.countForDay(start, end)

    /**
     * Inserts a placeholder immediately, then fetches nutrition from AI and updates the record.
     * Mirrors iOS CalorieTrackerViewModel.addItem pattern.
     */
    suspend fun addItem(
        query: String,
        images: List<ByteArray> = emptyList(),
        onError: (String) -> Unit = {}
    ) {
        val modelName = userSettings.modelName.first().ifBlank { BuildConfig.MODEL_NAME }
        val apiKey = userSettings.openRouterApiKey.first().ifBlank { BuildConfig.OPENROUTER_API_KEY }
        val serperKey = userSettings.serperApiKey.first().ifBlank { BuildConfig.SERPER_API_KEY }
        val placeholder = FoodItem(
            id = UUID.randomUUID().toString(),
            name = query,
            isProcessing = true
        )
        dao.insert(placeholder.toEntity())

        try {
            val results = nutritionService.fetchNutrition(
                query = query,
                images = images,
                apiKey = apiKey,
                modelName = modelName,
                serperApiKey = serperKey
            )

            val firstResult = results.firstOrNull()
            if (firstResult == null) {
                dao.delete(placeholder.toEntity())
                return
            }
            val first = firstResult.response

            // Update placeholder with first result
            val updated = placeholder.copy(
                identifiedFood = first.identifiedFood,
                cleanFoodName = first.cleanFoodName,
                calories = first.calories,
                protein = first.protein,
                carbs = first.carbs,
                fat = first.fat,
                weightGrams = first.estimatedWeightGrams,
                caloriesPer100g = first.caloriesPer100g,
                proteinPer100g = first.proteinPer100g,
                carbsPer100g = first.carbsPer100g,
                fatPer100g = first.fatPer100g,
                isProcessing = false,
                isSearchGrounded = first.isSearchGrounded ?: false,
                dataSource = first.dataSource,
                searchSteps = firstResult.searchSteps
            )
            dao.update(updated.toEntity())

            // Sync to Health Connect
            val hcId = healthConnect.writeNutrition(updated)
            if (hcId != null) dao.update(updated.copy(healthConnectIds = listOf(hcId)).toEntity())

            // Update widget
            CalCalWidget().updateAll(context)

            // Insert additional items if AI returned multiple foods
            results.drop(1).forEach { itemResult ->
                val item = itemResult.response
                val extra = FoodItem(
                    id = UUID.randomUUID().toString(),
                    name = query,
                    identifiedFood = item.identifiedFood,
                    cleanFoodName = item.cleanFoodName,
                    calories = item.calories,
                    protein = item.protein,
                    carbs = item.carbs,
                    fat = item.fat,
                    weightGrams = item.estimatedWeightGrams,
                    caloriesPer100g = item.caloriesPer100g,
                    proteinPer100g = item.proteinPer100g,
                    carbsPer100g = item.carbsPer100g,
                    fatPer100g = item.fatPer100g,
                    isProcessing = false,
                    isSearchGrounded = item.isSearchGrounded ?: false,
                    dataSource = item.dataSource,
                    searchSteps = itemResult.searchSteps
                )
                dao.insert(extra.toEntity())
            }

        } catch (e: Exception) {
            dao.delete(placeholder.toEntity())
            onError(e.message ?: "Unknown error")
        }
    }

    suspend fun updateItem(item: FoodItem) = dao.update(item.toEntity())

    suspend fun deleteItem(item: FoodItem) {
        // Delete from Health Connect first
        if (item.healthConnectIds.isNotEmpty()) {
            healthConnect.deleteNutrition(item.healthConnectIds)
        }
        dao.delete(item.toEntity())
        CalCalWidget().updateAll(context)
    }

    suspend fun fetchAIGoals(userStats: String, userGoals: String, baselineTdee: Double): GoalResponse {
        val modelName = userSettings.modelName.first().ifBlank { BuildConfig.MODEL_NAME }
        val apiKey = userSettings.openRouterApiKey.first().ifBlank { BuildConfig.OPENROUTER_API_KEY }
        return nutritionService.fetchAIGoals(
            userStats = userStats,
            userGoals = userGoals,
            baselineTdee = baselineTdee,
            apiKey = apiKey,
            modelName = modelName
        )
    }

    fun todayRange(): Pair<Long, Long> {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
        val start = cal.timeInMillis
        cal.add(Calendar.DAY_OF_MONTH, 1)
        return start to cal.timeInMillis
    }
}
