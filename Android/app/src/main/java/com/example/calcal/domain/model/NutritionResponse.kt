package com.example.calcal.domain.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class NutritionResponse(
    val identifiedFood: String,
    val cleanFoodName: String,
    val calories: Double,
    val protein: Double,
    val carbs: Double,
    val fat: Double,
    val estimatedWeightGrams: Double,
    val caloriesPer100g: Double,
    val proteinPer100g: Double,
    val carbsPer100g: Double,
    val fatPer100g: Double,
    val isSearchGrounded: Boolean? = null,
    val dataSource: String? = null
)

@Serializable
data class FoodArrayResponse(
    val foods: List<NutritionResponse>
)

@Serializable
data class GoalResponse(
    val calories: Double,
    val protein: Double,
    val carbs: Double,
    val fat: Double,
    val explanation: String
)

data class SearchResult(
    val title: String,
    val link: String,
    val snippet: String
)

data class SearchStep(
    val query: String,
    val results: List<SearchResult>,
    val answerBox: String? = null
)

// Non-serializable wrapper that carries searchSteps alongside the parsed response
data class NutritionResponseWithSteps(
    val response: NutritionResponse,
    val searchSteps: List<SearchStep> = emptyList()
)
