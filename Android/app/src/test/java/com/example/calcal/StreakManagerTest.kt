package com.example.calcal

import com.example.calcal.data.local.FoodItemDao
import com.example.calcal.data.local.FoodItemEntity
import com.example.calcal.domain.util.StreakManager
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test
import java.util.Calendar

class StreakManagerTest {

    // Fake DAO that returns counts based on a set of "active" day start timestamps
    private fun fakeDao(activeDays: Set<Long>): FoodItemDao = object : FoodItemDao {
        override fun getItemsForDay(start: Long, end: Long): Flow<List<FoodItemEntity>> = flowOf(emptyList())
        override fun getAllItems(): Flow<List<FoodItemEntity>> = flowOf(emptyList())
        override suspend fun getById(id: String): FoodItemEntity? = null
        override suspend fun insert(item: FoodItemEntity) {}
        override suspend fun update(item: FoodItemEntity) {}
        override suspend fun delete(item: FoodItemEntity) {}
        override suspend fun countForDay(start: Long, end: Long): Int =
            if (activeDays.any { it >= start && it < end }) 1 else 0
    }

    private fun startOfDay(daysAgo: Int): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
        cal.add(Calendar.DAY_OF_MONTH, -daysAgo)
        return cal.timeInMillis
    }

    @Test
    fun `streak is 0 when no entries today or yesterday`() = runTest {
        val dao = fakeDao(setOf(startOfDay(5), startOfDay(6)))
        val manager = StreakManager(dao)
        assertEquals(0, manager.calculateCurrentStreak())
    }

    @Test
    fun `streak is 1 when only today has entries`() = runTest {
        val dao = fakeDao(setOf(startOfDay(0)))
        val manager = StreakManager(dao)
        assertEquals(1, manager.calculateCurrentStreak())
    }

    @Test
    fun `streak is 1 when only yesterday has entries`() = runTest {
        val dao = fakeDao(setOf(startOfDay(1)))
        val manager = StreakManager(dao)
        assertEquals(1, manager.calculateCurrentStreak())
    }

    @Test
    fun `streak counts consecutive days correctly`() = runTest {
        // today, yesterday, 2 days ago — streak = 3
        val dao = fakeDao(setOf(startOfDay(0), startOfDay(1), startOfDay(2)))
        val manager = StreakManager(dao)
        assertEquals(3, manager.calculateCurrentStreak())
    }

    @Test
    fun `streak stops at gap`() = runTest {
        // today and 2 days ago but NOT yesterday — streak = 1
        val dao = fakeDao(setOf(startOfDay(0), startOfDay(2)))
        val manager = StreakManager(dao)
        assertEquals(1, manager.calculateCurrentStreak())
    }

    @Test
    fun `streak from yesterday with gap before`() = runTest {
        // yesterday and 2 days ago but not today — streak = 2
        val dao = fakeDao(setOf(startOfDay(1), startOfDay(2)))
        val manager = StreakManager(dao)
        assertEquals(2, manager.calculateCurrentStreak())
    }
}
