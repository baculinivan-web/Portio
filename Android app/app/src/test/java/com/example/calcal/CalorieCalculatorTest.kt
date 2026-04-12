package com.example.calcal

import com.example.calcal.domain.util.CalorieCalculator
import org.junit.Assert.*
import org.junit.Test

class CalorieCalculatorTest {

    @Test
    fun `male sedentary TDEE is calculated correctly`() {
        // 70kg, 175cm, 30yo male sedentary
        // BMR = 10*70 + 6.25*175 - 5*30 + 5 = 700 + 1093.75 - 150 + 5 = 1648.75
        // TDEE = 1648.75 * 1.2 = 1978.5
        val result = CalorieCalculator.calculateTDEE(
            weightKg = 70.0, heightCm = 175.0, age = 30,
            gender = CalorieCalculator.Gender.MALE,
            activityLevel = CalorieCalculator.ActivityLevel.SEDENTARY
        )
        assertEquals(1978.5, result, 0.1)
    }

    @Test
    fun `female moderately active TDEE is calculated correctly`() {
        // 60kg, 165cm, 25yo female moderately active
        // BMR = 10*60 + 6.25*165 - 5*25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
        // TDEE = 1345.25 * 1.55 = 2085.1375
        val result = CalorieCalculator.calculateTDEE(
            weightKg = 60.0, heightCm = 165.0, age = 25,
            gender = CalorieCalculator.Gender.FEMALE,
            activityLevel = CalorieCalculator.ActivityLevel.MODERATELY_ACTIVE
        )
        assertEquals(2085.1, result, 0.1)
    }

    @Test
    fun `higher activity level produces higher TDEE`() {
        val sedentary = CalorieCalculator.calculateTDEE(
            70.0, 175.0, 30, CalorieCalculator.Gender.MALE, CalorieCalculator.ActivityLevel.SEDENTARY
        )
        val veryActive = CalorieCalculator.calculateTDEE(
            70.0, 175.0, 30, CalorieCalculator.Gender.MALE, CalorieCalculator.ActivityLevel.VERY_ACTIVE
        )
        assertTrue(veryActive > sedentary)
    }

    @Test
    fun `all activity levels produce positive TDEE`() {
        CalorieCalculator.ActivityLevel.entries.forEach { level ->
            val result = CalorieCalculator.calculateTDEE(70.0, 175.0, 30, CalorieCalculator.Gender.MALE, level)
            assertTrue("TDEE should be positive for $level", result > 0)
        }
    }
}
