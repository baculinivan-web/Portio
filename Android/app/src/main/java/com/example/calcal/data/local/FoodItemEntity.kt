package com.example.calcal.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "food_items")
data class FoodItemEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val identifiedFood: String = "",
    val cleanFoodName: String = "",
    val calories: Double = 0.0,
    val protein: Double = 0.0,
    val carbs: Double = 0.0,
    val fat: Double = 0.0,
    val weightGrams: Double = 0.0,
    val caloriesPer100g: Double = 0.0,
    val proteinPer100g: Double = 0.0,
    val carbsPer100g: Double = 0.0,
    val fatPer100g: Double = 0.0,
    val dateEaten: Long = System.currentTimeMillis(),
    val isProcessing: Boolean = false,
    val isSearchGrounded: Boolean = false,
    val dataSource: String? = null,
    val healthConnectIds: String = "", // JSON array of record UUIDs
    val searchStepsJson: String = ""   // JSON array of SearchStep
)