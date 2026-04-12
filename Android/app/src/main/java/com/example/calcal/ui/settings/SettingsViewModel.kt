package com.example.calcal.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.calcal.data.preferences.UserSettings
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(private val userSettings: UserSettings) : ViewModel() {

    val calorieGoal = userSettings.calorieGoal.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 2200.0)
    val proteinGoal = userSettings.proteinGoal.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 120.0)
    val carbsGoal = userSettings.carbsGoal.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 250.0)
    val fatGoal = userSettings.fatGoal.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 70.0)
    val healthConnectEnabled = userSettings.healthConnectEnabled.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), false)
    val goalExplanation = userSettings.goalExplanation.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), "")
    val modelName = userSettings.modelName.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), "")

    fun setCalorieGoal(v: Double) = viewModelScope.launch { userSettings.setCalorieGoal(v) }
    fun setProteinGoal(v: Double) = viewModelScope.launch { userSettings.setProteinGoal(v) }
    fun setCarbsGoal(v: Double) = viewModelScope.launch { userSettings.setCarbsGoal(v) }
    fun setFatGoal(v: Double) = viewModelScope.launch { userSettings.setFatGoal(v) }
    fun setHealthConnectEnabled(v: Boolean) = viewModelScope.launch { userSettings.setHealthConnectEnabled(v) }
    fun setModelName(v: String) = viewModelScope.launch { userSettings.setModelName(v) }
}
