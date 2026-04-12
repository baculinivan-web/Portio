package com.example.portio.data.preferences

import android.content.Context
import com.example.portio.BuildConfig
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
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
}

@Singleton
class UserSettings @Inject constructor(@ApplicationContext private val context: Context) {

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
    val openRouterApiKey: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.OPENROUTER_API_KEY] ?: "" }
    val serperApiKey: Flow<String> = context.dataStore.data.map { it[UserSettingsKeys.SERPER_API_KEY] ?: "" }

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
    suspend fun setOpenRouterApiKey(value: String) = context.dataStore.edit { it[UserSettingsKeys.OPENROUTER_API_KEY] = value }
    suspend fun setSerperApiKey(value: String) = context.dataStore.edit { it[UserSettingsKeys.SERPER_API_KEY] = value }
}
