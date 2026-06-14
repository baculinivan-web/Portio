package com.example.portio.ui.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.portio.data.preferences.UserSettings
import com.example.portio.data.repository.FoodRepository
import com.example.portio.BuildConfig
import com.example.portio.domain.util.CalorieCalculator
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

    var weightKg = MutableStateFlow(0.0)
    var heightCm = MutableStateFlow(0.0)
    var age = MutableStateFlow(0)
    var gender = MutableStateFlow(CalorieCalculator.Gender.MALE)
    var activityLevel = MutableStateFlow(CalorieCalculator.ActivityLevel.SEDENTARY)
    var goalText = MutableStateFlow("")
    var weightGoalMode = MutableStateFlow("Maintain Weight")
    var openRouterApiKey = MutableStateFlow("")
    var serperApiKey = MutableStateFlow("")
    var modelName = MutableStateFlow("")
    var customApiBaseUrl = MutableStateFlow("")
    var blockRunWalletId = MutableStateFlow("")
    var blockRunProxyUrl = MutableStateFlow("https://blockrun.ai/api/v1")
    var llmProvider = MutableStateFlow(UserSettings.LLMProvider.OPEN_ROUTER)

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error = _error.asStateFlow()

    fun complete(onDone: () -> Unit) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
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

                userSettings.setWeightKg(weightKg.value)
                userSettings.setHeightCm(heightCm.value)
                userSettings.setAge(age.value)
                userSettings.setGender(gender.value.name)
                userSettings.setActivityLevel(activityLevel.value.name)
                userSettings.setUserGoalText(goalText.value)
                userSettings.setWeightGoalMode(weightGoalMode.value)
                if (openRouterApiKey.value.isNotBlank()) {
                    userSettings.setOpenRouterApiKey(openRouterApiKey.value.trim())
                }
                if (serperApiKey.value.isNotBlank()) {
                    userSettings.setSerperApiKey(serperApiKey.value.trim())
                }
                if (modelName.value.isNotBlank()) {
                    userSettings.setModelName(modelName.value.trim())
                }
                if (customApiBaseUrl.value.isNotBlank()) {
                    userSettings.setCustomApiBaseUrl(customApiBaseUrl.value.trim())
                }
                if (blockRunWalletId.value.isNotBlank()) {
                    userSettings.setBlockRunWalletId(blockRunWalletId.value.trim())
                }
                if (blockRunProxyUrl.value.isNotBlank()) {
                    userSettings.setBlockRunProxyUrl(blockRunProxyUrl.value.trim())
                }
                userSettings.setLlmProvider(llmProvider.value)

                val provider = llmProvider.value
                val hasOpenRouterKey = openRouterApiKey.value.isNotBlank() || BuildConfig.OPENROUTER_API_KEY.isNotBlank()
                val hasSerperKey = serperApiKey.value.isNotBlank() || BuildConfig.SERPER_API_KEY.isNotBlank()
                val hasBlockRunWallet = blockRunWalletId.value.isNotBlank() || BuildConfig.BLOCKRUN_WALLET_KEY.isNotBlank()

                when (provider) {
                    UserSettings.LLMProvider.OPEN_ROUTER -> {
                        if (!hasOpenRouterKey) throw IllegalStateException("Add an OpenRouter API key before completing setup.")
                    }
                    UserSettings.LLMProvider.CUSTOM -> {
                        if (customApiBaseUrl.value.isBlank()) throw IllegalStateException("Add a custom provider base URL before completing setup.")
                        if (!hasOpenRouterKey) throw IllegalStateException("Add the custom provider API key before completing setup.")
                    }
                    UserSettings.LLMProvider.BLOCKRUN -> {
                        if (!hasBlockRunWallet) throw IllegalStateException("Add a BlockRun wallet key before completing setup.")
                    }
                }
                if (!hasSerperKey) throw IllegalStateException("Add a Serper API key so food logging can use search tools.")

                try {
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
                } catch (e: Exception) {
                    userSettings.setCalorieGoal(tdee)
                    userSettings.setProteinGoal(weightKg.value * 1.6)
                    userSettings.setCarbsGoal(tdee * 0.45 / 4)
                    userSettings.setFatGoal(tdee * 0.30 / 9)
                    userSettings.setGoalExplanation("AI goal generation failed, so Portio used calculated fallback goals. You can update them in Settings.")
                }
                userSettings.setHasCompletedOnboarding(true)
                onDone()
            } catch (e: Exception) {
                _error.value = e.message ?: "Setup failed. Check your API settings and try again."
            } finally {
                _isLoading.value = false
            }
        }
    }
}
