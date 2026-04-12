package com.example.calcal.domain.model

import com.example.calcal.data.local.FoodItemEntity
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

data class FoodItem(
    val id: String,
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
    val healthConnectIds: List<String> = emptyList(),
    val searchSteps: List<SearchStep> = emptyList()
)

private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

fun FoodItemEntity.toDomain(): FoodItem {
    val steps = try {
        if (searchStepsJson.isBlank()) emptyList()
        else json.decodeFromString<List<SearchStepJson>>(searchStepsJson).map { it.toSearchStep() }
    } catch (e: Exception) { emptyList() }

    return FoodItem(
        id = id, name = name, identifiedFood = identifiedFood, cleanFoodName = cleanFoodName,
        calories = calories, protein = protein, carbs = carbs, fat = fat,
        weightGrams = weightGrams, caloriesPer100g = caloriesPer100g,
        proteinPer100g = proteinPer100g, carbsPer100g = carbsPer100g, fatPer100g = fatPer100g,
        dateEaten = dateEaten, isProcessing = isProcessing, isSearchGrounded = isSearchGrounded,
        dataSource = dataSource,
        healthConnectIds = if (healthConnectIds.isBlank()) emptyList() else healthConnectIds.split(","),
        searchSteps = steps
    )
}

fun FoodItem.toEntity(): FoodItemEntity {
    val stepsJson = try {
        if (searchSteps.isEmpty()) ""
        else json.encodeToString(searchSteps.map { it.toJson() })
    } catch (e: Exception) { "" }

    return FoodItemEntity(
        id = id, name = name, identifiedFood = identifiedFood, cleanFoodName = cleanFoodName,
        calories = calories, protein = protein, carbs = carbs, fat = fat,
        weightGrams = weightGrams, caloriesPer100g = caloriesPer100g,
        proteinPer100g = proteinPer100g, carbsPer100g = carbsPer100g, fatPer100g = fatPer100g,
        dateEaten = dateEaten, isProcessing = isProcessing, isSearchGrounded = isSearchGrounded,
        dataSource = dataSource,
        healthConnectIds = healthConnectIds.joinToString(","),
        searchStepsJson = stepsJson
    )
}

// Serializable helpers for JSON storage
@kotlinx.serialization.Serializable
data class SearchStepJson(
    val query: String,
    val results: List<SearchResultJson>,
    val answerBox: String? = null
)

@kotlinx.serialization.Serializable
data class SearchResultJson(val title: String, val link: String, val snippet: String)

fun SearchStepJson.toSearchStep() = SearchStep(
    query = query,
    results = results.map { SearchResult(it.title, it.link, it.snippet) },
    answerBox = answerBox
)

fun SearchStep.toJson() = SearchStepJson(
    query = query,
    results = results.map { SearchResultJson(it.title, it.link, it.snippet) },
    answerBox = answerBox
)
