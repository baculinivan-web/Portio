package com.example.portio

import com.example.portio.domain.model.FoodItem
import com.example.portio.domain.util.NutrientWarning
import com.example.portio.domain.util.NutrientWarningManager
import org.junit.Assert.*
import org.junit.Test
import java.util.UUID

class NutrientWarningManagerTest {

    private fun item(calories: Double = 0.0, protein: Double = 0.0, carbs: Double = 0.0, fat: Double = 0.0) =
        FoodItem(id = UUID.randomUUID().toString(), name = "test", calories = calories, protein = protein, carbs = carbs, fat = fat)

    @Test
    fun `no warnings when within goals`() {
        val items = listOf(item(calories = 1800.0, protein = 100.0, carbs = 200.0, fat = 60.0))
        val warnings = NutrientWarningManager.getWarnings(items, 2200.0, 120.0, 250.0, 70.0)
        assertTrue(warnings.isEmpty())
    }

    @Test
    fun `calorie warning when exceeding goal by more than 10 percent`() {
        val items = listOf(item(calories = 2500.0))
        val warnings = NutrientWarningManager.getWarnings(items, 2200.0, 120.0, 250.0, 70.0)
        assertTrue(warnings.any { it.nutrient == "Calories" && it.severity == NutrientWarning.Severity.HIGH })
    }

    @Test
    fun `protein warning when below 50 percent of goal`() {
        val items = listOf(item(protein = 40.0))
        val warnings = NutrientWarningManager.getWarnings(items, 2200.0, 120.0, 250.0, 70.0)
        assertTrue(warnings.any { it.nutrient == "Protein" && it.severity == NutrientWarning.Severity.LOW })
    }

    @Test
    fun `fat warning when exceeding goal by more than 20 percent`() {
        val items = listOf(item(fat = 90.0))
        val warnings = NutrientWarningManager.getWarnings(items, 2200.0, 120.0, 250.0, 70.0)
        assertTrue(warnings.any { it.nutrient == "Fat" && it.severity == NutrientWarning.Severity.HIGH })
    }

    @Test
    fun `multiple warnings can be returned`() {
        val items = listOf(item(calories = 2600.0, fat = 100.0))
        val warnings = NutrientWarningManager.getWarnings(items, 2200.0, 120.0, 250.0, 70.0)
        assertTrue(warnings.size >= 2)
    }
}
