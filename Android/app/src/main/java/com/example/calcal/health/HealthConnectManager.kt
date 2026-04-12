package com.example.calcal.health

import android.content.Context
import com.example.calcal.domain.model.FoodItem
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Stub implementation — Health Connect requires AGP 8.9.1+ and compileSdk 36.
 * Re-enable after upgrading AGP.
 */
@Singleton
class HealthConnectManager @Inject constructor(@ApplicationContext private val context: Context) {

    suspend fun isAvailable(): Boolean = false

    suspend fun hasPermissions(): Boolean = false

    suspend fun writeNutrition(item: FoodItem): String? = null

    suspend fun deleteNutrition(recordIds: List<String>) { /* no-op */ }
}
