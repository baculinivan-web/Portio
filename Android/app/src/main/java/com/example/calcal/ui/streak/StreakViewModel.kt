package com.example.calcal.ui.streak

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.calcal.data.local.FoodItemDao
import com.example.calcal.domain.util.StreakManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Calendar
import javax.inject.Inject

@HiltViewModel
class StreakViewModel @Inject constructor(
    private val dao: FoodItemDao,
    private val streakManager: StreakManager
) : ViewModel() {

    private val _currentStreak = MutableStateFlow(0)
    val currentStreak: StateFlow<Int> = _currentStreak.asStateFlow()

    // Map of dayStart (epoch ms) -> hasEntries
    private val _activityMap = MutableStateFlow<Map<Long, Boolean>>(emptyMap())
    val activityMap: StateFlow<Map<Long, Boolean>> = _activityMap.asStateFlow()

    init {
        viewModelScope.launch {
            _currentStreak.value = streakManager.calculateCurrentStreak()
            loadActivityMap()
        }
    }

    private suspend fun loadActivityMap() {
        val map = mutableMapOf<Long, Boolean>()
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)

        // Load last 90 days
        repeat(90) {
            val start = cal.timeInMillis
            val end = start + 24 * 60 * 60 * 1000L
            map[start] = dao.countForDay(start, end) > 0
            cal.add(Calendar.DAY_OF_MONTH, -1)
        }
        _activityMap.value = map
    }
}
