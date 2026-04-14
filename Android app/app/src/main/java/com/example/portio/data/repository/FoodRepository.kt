package com.example.portio.data.repository

import android.content.Context
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.example.portio.BuildConfig
import com.example.portio.data.local.FoodItemDao
import com.example.portio.data.remote.NutritionService
import com.example.portio.domain.model.FoodItem
import com.example.portio.domain.model.GoalResponse
import com.example.portio.domain.model.toDomain
import com.example.portio.domain.model.toEntity
import com.example.portio.data.preferences.UserSettings
import com.example.portio.health.HealthConnectManager
import com.example.portio.widget.PortioWidget
import com.example.portio.worker.NutritionWorker
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
     * Inserts a placeholder immediately, then enqueues a WorkManager job to fetch nutrition.
     * The job runs even if the app is closed — WorkManager guarantees execution.
     * Images are not supported in background mode (no persistent storage for byte arrays).
     */
    suspend fun addItem(
        query: String,
        images: List<ByteArray> = emptyList(),
        onError: (String) -> Unit = {}
    ) {
        val placeholder = FoodItem(
            id = UUID.randomUUID().toString(),
            name = query,
            isProcessing = true
        )
        dao.insert(placeholder.toEntity())

        val inputData = Data.Builder()
            .putString(NutritionWorker.KEY_ITEM_ID, placeholder.id)
            .putString(NutritionWorker.KEY_QUERY, query)
            .build()

        val request = OneTimeWorkRequestBuilder<NutritionWorker>()
            .setInputData(inputData)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .build()

        WorkManager.getInstance(context).enqueue(request)
    }

    suspend fun updateItem(item: FoodItem) = dao.update(item.toEntity())

    suspend fun deleteItem(item: FoodItem) {
        // Delete from Health Connect first
        if (item.healthConnectIds.isNotEmpty()) {
            healthConnect.deleteNutrition(item.healthConnectIds)
        }
        dao.delete(item.toEntity())
        PortioWidget().updateAll(context)
    }

    suspend fun fetchAIGoals(userStats: String, userGoals: String, baselineTdee: Double): GoalResponse {
        val modelName = userSettings.modelName.first().ifBlank { BuildConfig.MODEL_NAME }
        val apiKey = userSettings.openRouterApiKey.first().ifBlank { BuildConfig.OPENROUTER_API_KEY }
        val customApiBaseUrl = userSettings.customApiBaseUrl.first()
        return nutritionService.fetchAIGoals(
            userStats = userStats,
            userGoals = userGoals,
            baselineTdee = baselineTdee,
            apiKey = apiKey,
            modelName = modelName,
            customApiBaseUrl = customApiBaseUrl
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
