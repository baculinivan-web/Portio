package com.example.portio.ui.statistics

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.portio.data.local.FoodItemDao
import com.example.portio.domain.model.FoodItem
import com.example.portio.domain.model.toDomain
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import java.util.Calendar
import javax.inject.Inject

data class DayStats(val dayLabel: String, val calories: Double, val protein: Double, val carbs: Double, val fat: Double)

@HiltViewModel
class StatisticsViewModel @Inject constructor(private val dao: FoodItemDao) : ViewModel() {

    val todayItems: StateFlow<List<FoodItem>> = run {
        val (start, end) = todayRange()
        dao.getItemsForDay(start, end).map { list -> list.map { it.toDomain() } }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    }

    val last7Days: StateFlow<List<DayStats>> = flow {
        val stats = (6 downTo 0).map { daysAgo ->
            val cal = Calendar.getInstance()
            cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
            cal.add(Calendar.DAY_OF_MONTH, -daysAgo)
            val start = cal.timeInMillis
            val end = start + 24 * 60 * 60 * 1000L
            val items = dao.getItemsForDay(start, end).first().map { it.toDomain() }
            val label = if (daysAgo == 0) "Today" else "-${daysAgo}d"
            DayStats(
                dayLabel = label,
                calories = items.sumOf { it.calories },
                protein = items.sumOf { it.protein },
                carbs = items.sumOf { it.carbs },
                fat = items.sumOf { it.fat }
            )
        }
        emit(stats)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private fun todayRange(): Pair<Long, Long> {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
        val start = cal.timeInMillis
        return start to (start + 24 * 60 * 60 * 1000L)
    }
}
