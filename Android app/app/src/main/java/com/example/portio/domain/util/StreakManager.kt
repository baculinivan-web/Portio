package com.example.portio.domain.util

import com.example.portio.data.local.FoodItemDao
import java.util.Calendar
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class StreakManager @Inject constructor(private val dao: FoodItemDao) {

    /**
     * Calculates the current streak of consecutive days with at least one food item logged.
     * Streak is alive if there are entries today OR yesterday (mirrors iOS logic).
     */
    suspend fun calculateCurrentStreak(): Int {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
        val startOfToday = cal.timeInMillis

        val hasToday = hasEntries(startOfToday)
        cal.add(Calendar.DAY_OF_MONTH, -1)
        val startOfYesterday = cal.timeInMillis
        val hasYesterday = hasEntries(startOfYesterday)

        if (!hasToday && !hasYesterday) return 0

        var checkDate = if (hasToday) startOfToday else startOfYesterday
        var streak = 0

        while (true) {
            if (hasEntries(checkDate)) {
                streak++
                val prev = Calendar.getInstance().apply {
                    timeInMillis = checkDate
                    add(Calendar.DAY_OF_MONTH, -1)
                }
                checkDate = prev.timeInMillis
            } else {
                break
            }
        }

        return streak
    }

    private suspend fun hasEntries(startOfDay: Long): Boolean {
        val endOfDay = startOfDay + 24 * 60 * 60 * 1000L
        return dao.countForDay(startOfDay, endOfDay) > 0
    }
}
