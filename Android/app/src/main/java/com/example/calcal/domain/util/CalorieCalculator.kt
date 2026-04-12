package com.example.calcal.domain.util

object CalorieCalculator {

    enum class Gender { MALE, FEMALE }

    enum class ActivityLevel(val multiplier: Double) {
        SEDENTARY(1.2),
        LIGHTLY_ACTIVE(1.375),
        MODERATELY_ACTIVE(1.55),
        VERY_ACTIVE(1.725),
        EXTRA_ACTIVE(1.9);

        fun displayName(): String = when (this) {
            SEDENTARY -> "Sedentary (little or no exercise)"
            LIGHTLY_ACTIVE -> "Lightly Active (1-3 days/week)"
            MODERATELY_ACTIVE -> "Moderately Active (3-5 days/week)"
            VERY_ACTIVE -> "Very Active (6-7 days/week)"
            EXTRA_ACTIVE -> "Extra Active (very hard exercise & physical job)"
        }
    }

    /** Mifflin-St Jeor equation */
    fun calculateTDEE(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel
    ): Double {
        val bmr = if (gender == Gender.MALE) {
            (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
        } else {
            (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161
        }
        return bmr * activityLevel.multiplier
    }
}
