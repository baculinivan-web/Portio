package com.example.portio.domain.util

import com.example.portio.domain.model.FoodItem

data class NutrientWarning(
    val nutrient: String,
    val message: String,
    val severity: Severity
) {
    enum class Severity { LOW, HIGH }
}

object NutrientWarningManager {

    fun getWarnings(
        items: List<FoodItem>,
        calorieGoal: Double,
        proteinGoal: Double,
        carbsGoal: Double,
        fatGoal: Double
    ): List<NutrientWarning> {
        val warnings = mutableListOf<NutrientWarning>()

        val totalCalories = items.sumOf { it.calories }
        val totalProtein = items.sumOf { it.protein }
        val totalCarbs = items.sumOf { it.carbs }
        val totalFat = items.sumOf { it.fat }

        if (calorieGoal > 0 && totalCalories > calorieGoal * 1.1) {
            warnings.add(NutrientWarning("Calories", "You've exceeded your calorie goal", NutrientWarning.Severity.HIGH))
        }
        if (proteinGoal > 0 && totalProtein < proteinGoal * 0.5) {
            warnings.add(NutrientWarning("Protein", "Protein intake is very low", NutrientWarning.Severity.LOW))
        }
        if (fatGoal > 0 && totalFat > fatGoal * 1.2) {
            warnings.add(NutrientWarning("Fat", "Fat intake is high", NutrientWarning.Severity.HIGH))
        }
        if (carbsGoal > 0 && totalCarbs > carbsGoal * 1.2) {
            warnings.add(NutrientWarning("Carbs", "Carbohydrate intake is high", NutrientWarning.Severity.HIGH))
        }

        return warnings
    }
}
