package com.example.portio.ui.tracker

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.portio.data.preferences.UserSettings
import com.example.portio.data.repository.FoodRepository
import com.example.portio.domain.model.FoodItem
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TrackerViewModel @Inject constructor(
    private val repository: FoodRepository,
    private val userSettings: UserSettings
) : ViewModel() {

    val todayItems: StateFlow<List<FoodItem>> = repository.getTodayItems()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val calorieGoal: StateFlow<Double> = userSettings.calorieGoal
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 2200.0)

    val proteinGoal: StateFlow<Double> = userSettings.proteinGoal
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 120.0)

    val carbsGoal: StateFlow<Double> = userSettings.carbsGoal
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 250.0)

    val fatGoal: StateFlow<Double> = userSettings.fatGoal
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 70.0)

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun addItem(query: String, images: List<ByteArray> = emptyList()) {
        viewModelScope.launch {
            _isLoading.value = true
            repository.addItem(
                query = query,
                images = images,
                onError = { _errorMessage.value = it }
            )
            _isLoading.value = false
        }
    }

    fun deleteItem(item: FoodItem) {
        viewModelScope.launch { repository.deleteItem(item) }
    }

    fun updateItem(item: FoodItem) {
        viewModelScope.launch { repository.updateItem(item) }
    }

    fun clearError() { _errorMessage.value = null }
}
