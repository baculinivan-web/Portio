package com.example.calcal.ui.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.calcal.data.preferences.UserSettings
import com.example.calcal.data.repository.FoodRepository
import com.example.calcal.domain.util.CalorieCalculator
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val userSettings: UserSettings,
    private val repository: FoodRepository
) : ViewModel() {

    var weightKg = MutableStateFlow(70.0)
    var heightCm = MutableStateFlow(170.0)
    var age = MutableStateFlow(25)
    var gender = MutableStateFlow(CalorieCalculator.Gender.MALE)
    var activityLevel = MutableStateFlow(CalorieCalculator.ActivityLevel.SEDENTARY)
    var goalText = MutableStateFlow("")
    var weightGoalMode = MutableStateFlow("Maintain Weight")

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error = _error.asStateFlow()

    fun complete(onDone: () -> Unit) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val tdee = CalorieCalculator.calculateTDEE(
                    weightKg = weightKg.value,
                    heightCm = heightCm.value,
                    age = age.value,
                    gender = gender.value,
                    activityLevel = activityLevel.value
                )

                val userStats = "Weight: ${weightKg.value}kg, Height: ${heightCm.value}cm, Age: ${age.value}, " +
                        "Gender: ${gender.value}, Activity: ${activityLevel.value.displayName()}"

                val goals = repository.fetchAIGoals(
                    userStats = userStats,
                    userGoals = goalText.value.ifBlank { weightGoalMode.value },
                    baselineTdee = tdee
                )

                userSettings.setCalorieGoal(goals.calories)
                userSettings.setProteinGoal(goals.protein)
                userSettings.setCarbsGoal(goals.carbs)
                userSettings.setFatGoal(goals.fat)
                userSettings.setGoalExplanation(goals.explanation)
                userSettings.setWeightKg(weightKg.value)
                userSettings.setHeightCm(heightCm.value)
                userSettings.setAge(age.value)
                userSettings.setGender(gender.value.name)
                userSettings.setActivityLevel(activityLevel.value.name)
                userSettings.setUserGoalText(goalText.value)
                userSettings.setWeightGoalMode(weightGoalMode.value)
                userSettings.setHasCompletedOnboarding(true)

                onDone()
            } catch (e: Exception) {
                // Fallback: use TDEE-based defaults without AI
                val tdee = CalorieCalculator.calculateTDEE(
                    weightKg = weightKg.value, heightCm = heightCm.value,
                    age = age.value, gender = gender.value, activityLevel = activityLevel.value
                )
                userSettings.setCalorieGoal(tdee)
                userSettings.setProteinGoal(weightKg.value * 1.6)
                userSettings.setCarbsGoal(tdee * 0.45 / 4)
                userSettings.setFatGoal(tdee * 0.30 / 9)
                userSettings.setHasCompletedOnboarding(true)
                onDone()
            } finally {
                _isLoading.value = false
            }
        }
    }
}
