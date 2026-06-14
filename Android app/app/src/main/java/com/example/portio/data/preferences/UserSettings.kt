package com.example.portio.data.preferences

import android.content.Context
import com.example.portio.BuildConfig
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_settings")

object UserSettingsKeys {
    val CALORIE_GOAL = doublePreferencesKey("calorieGoal")
    val PROTEIN_GOAL = doublePreferencesKey("proteinGoal")
    val CARBS_GOAL = doublePreferencesKey("carbsGoal")
    val FAT_GOAL = doublePreferencesKey("fatGoal")
    val HAS_COMPLETED_ONBOARDING = booleanPreferencesKey("hasCompletedOnboarding")
    val HEALTH_CONNECT_ENABLED = booleanPreferencesKey("healthConnectEnabled")
    val WEIGHT_GOAL_MODE = stringPreferencesKey("weightGoalMode")
    val GOAL_EXPLANATION = stringPreferencesKey("goalExplanation")
    // Onboarding profile
    val WEIGHT_KG = doublePreferencesKey("weightKg")
    val HEIGHT_CM = doublePreferencesKey("heightCm")
    val AGE = intPreferencesKey("age")
    val GENDER = stringPreferencesKey("gender")
    val ACTIVITY_LEVEL = stringPreferencesKey("activityLevel")
    val USER_GOAL_TEXT = stringPreferencesKey("userGoalText")
    val MODEL_NAME = stringPreferencesKey("modelName")
    val OPENROUTER_API_KEY = stringPreferencesKey("openRouterApiKey")
    val SERPER_API_KEY = stringPreferencesKey("serperApiKey")
    val CUSTOM_API_BASE_URL = stringPreferencesKey("customApiBaseUrl")
    val IS_BLOCKRUN_ENABLED = booleanPreferencesKey("isBlockRunEnabled")
    val BLOCKRUN_WALLET_ID = stringPreferencesKey("blockRunWalletId")
    val HAS_SHOWN_BLOCKRUN_PROMPT = booleanPreferencesKey("hasShownBlockRunPrompt")
    val LLM_PROVIDER = stringPreferencesKey("llmProvider")
    val BLOCKRUN_PROXY_URL = stringPreferencesKey("blockRunProxyUrl")
}

@Singleton
class UserSettings @Inject constructor(
    @ApplicationContext private val context: Context,
    private val securePrefs: SecurePrefs
) {
    private val openRouterApiKeyState = MutableStateFlow(securePrefs.getString("openRouterApiKey"))
    private val serperApiKeyState = MutableStateFlow(securePrefs.getString("serperApiKey"))
    private val blockRunWalletIdState = MutableStateFlow(securePrefs.getString("blockRunWalletId", BuildConfig.BLOCKRUN_WALLET_KEY))

    enum class LLMProvider(val displayName: String) {
        OPEN_ROUTER("OpenRouter"),
        CUSTOM("Custom OpenAI-compatible"),
        BLOCKRUN("BlockRun AI (Beta)")
    }

    val calorieGoal: Flow<Double> = context.dataStore.data.map { it[UserSettingsKeys.CALORIE_GOAL] ?: 2200.0 }
    val proteinGoal: Flow<Double> = context.dataStore.data.map { it[UserSettingsKeys.PROTEIN_GOAL] ?: 120.0 }
    val carbsGoal: Flow<Double> = context.dataStore.data.map { it[UserSettingsKeys.CARBS_GOAL] ?: 250.0 }
    val fatGoal: Flow<Double> = context.dataStore.data.map { it[UserSettingsKeys.FAT_GOAL] ?: 70.0 }
    val hasCompletedOnboarding: Flow<Boolean> = context.dataStore.data.map { it[UserSettingsKeys.HAS_COMPLETED_ONBOARDING] ?: false }
    val healthConnectEnabled: Flow<Boolean> = context.dataStore.data.map { it[UserSettingsKeys.HEALTH_CONNECT_ENABLED] ?: false }
    val weightGoalMode: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.WEIGHT_GOAL_MODE] ?: "Maintain Weight" }
    val goalExplanation: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.GOAL_EXPLANATION] ?: "" }
    val weightKg: Flow<Double> = context.dataStore.data.map { it[UserSettingsKeys.WEIGHT_KG] ?: 70.0 }
    val heightCm: Flow<Double> = context.dataStore.data.map { it[UserSettingsKeys.HEIGHT_CM] ?: 170.0 }
    val age: Flow<Int> = context.dataStore.data.map { it[UserSettingsKeys.AGE] ?: 25 }
    val gender: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.GENDER] ?: "Male" }
    val activityLevel: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.ACTIVITY_LEVEL] ?: "Sedentary" }
    val userGoalText: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.USER_GOAL_TEXT] ?: "" }
    val modelName: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.MODEL_NAME] ?: BuildConfig.MODEL_NAME.ifBlank { "openai/gpt-oss-120b:free" } }

    // Sensitive keys stored in SecurePrefs
    val openRouterApiKey: Flow<String> = openRouterApiKeyState.asStateFlow()
    val serperApiKey: Flow<String> = serperApiKeyState.asStateFlow()
    val blockRunWalletId: Flow<String> = blockRunWalletIdState.asStateFlow()

    // Empty = use OpenRouter (default). Set to any OpenAI-compatible base URL, e.g. "https://api.openai.com/v1"
    val customApiBaseUrl: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.CUSTOM_API_BASE_URL] ?: "" }
    val isBlockRunEnabled: Flow<Boolean> = context.dataStore.data.map { it[UserSettingsKeys.IS_BLOCKRUN_ENABLED] ?: false }
    val hasShownBlockRunPrompt: Flow<Boolean> = context.dataStore.data.map { it[UserSettingsKeys.HAS_SHOWN_BLOCKRUN_PROMPT] ?: false }
    val blockRunProxyUrl: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.BLOCKRUN_PROXY_URL] ?: "https://blockrun.ai/api/v1" }
    val llmProvider: Flow<LLMProvider> = context.dataStore.data.map {
        val name = it[UserSettingsKeys.LLM_PROVIDER] ?: LLMProvider.OPEN_ROUTER.name
        try { LLMProvider.valueOf(name) } catch (e: Exception) { LLMProvider.OPEN_ROUTER }
    }

    suspend fun setCalorieGoal(value: Double) = context.dataStore.edit { it[UserSettingsKeys.CALORIE_GOAL] = value }
    suspend fun setProteinGoal(value: Double) = context.dataStore.edit { it[UserSettingsKeys.PROTEIN_GOAL] = value }
    suspend fun setCarbsGoal(value: Double) = context.dataStore.edit { it[UserSettingsKeys.CARBS_GOAL] = value }
    suspend fun setFatGoal(value: Double) = context.dataStore.edit { it[UserSettingsKeys.FAT_GOAL] = value }
    suspend fun setHasCompletedOnboarding(value: Boolean) = context.dataStore.edit { it[UserSettingsKeys.HAS_COMPLETED_ONBOARDING] = value }
    suspend fun setHealthConnectEnabled(value: Boolean) = context.dataStore.edit { it[UserSettingsKeys.HEALTH_CONNECT_ENABLED] = value }
    suspend fun setWeightGoalMode(value: String) = context.dataStore.edit { it[UserSettingsKeys.WEIGHT_GOAL_MODE] = value }
    suspend fun setGoalExplanation(value: String) = context.dataStore.edit { it[UserSettingsKeys.GOAL_EXPLANATION] = value }
    suspend fun setWeightKg(value: Double) = context.dataStore.edit { it[UserSettingsKeys.WEIGHT_KG] = value }
    suspend fun setHeightCm(value: Double) = context.dataStore.edit { it[UserSettingsKeys.HEIGHT_CM] = value }
    suspend fun setAge(value: Int) = context.dataStore.edit { it[UserSettingsKeys.AGE] = value }
    suspend fun setGender(value: String) = context.dataStore.edit { it[UserSettingsKeys.GENDER] = value }
    suspend fun setActivityLevel(value: String) = context.dataStore.edit { it[UserSettingsKeys.ACTIVITY_LEVEL] = value }
    suspend fun setUserGoalText(value: String) = context.dataStore.edit { it[UserSettingsKeys.USER_GOAL_TEXT] = value }
    suspend fun setModelName(value: String) = context.dataStore.edit { it[UserSettingsKeys.MODEL_NAME] = value }

    suspend fun setOpenRouterApiKey(value: String) {
        securePrefs.saveString("openRouterApiKey", value)
        openRouterApiKeyState.value = value
    }

    suspend fun setSerperApiKey(value: String) {
        securePrefs.saveString("serperApiKey", value)
        serperApiKeyState.value = value
    }

    suspend fun setBlockRunWalletId(value: String) {
        securePrefs.saveString("blockRunWalletId", value)
        blockRunWalletIdState.value = value
    }

    suspend fun setCustomApiBaseUrl(value: String) = context.dataStore.edit { it[UserSettingsKeys.CUSTOM_API_BASE_URL] = value }
    suspend fun setBlockRunEnabled(value: Boolean) = context.dataStore.edit { it[UserSettingsKeys.IS_BLOCKRUN_ENABLED] = value }
    suspend fun setBlockRunProxyUrl(value: String) = context.dataStore.edit { it[UserSettingsKeys.BLOCKRUN_PROXY_URL] = value }
    suspend fun setHasShownBlockRunPrompt(value: Boolean) = context.dataStore.edit { it[UserSettingsKeys.HAS_SHOWN_BLOCKRUN_PROMPT] = value }
    suspend fun setLlmProvider(value: LLMProvider) = context.dataStore.edit { it[UserSettingsKeys.LLM_PROVIDER] = value.name
    }
}
