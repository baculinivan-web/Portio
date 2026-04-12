package com.example.calcal.data.local

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface FoodItemDao {

    @Query("SELECT * FROM food_items WHERE dateEaten >= :start AND dateEaten < :end ORDER BY dateEaten DESC")
    fun getItemsForDay(start: Long, end: Long): Flow<List<FoodItemEntity>>

    @Query("SELECT * FROM food_items ORDER BY dateEaten DESC")
    fun getAllItems(): Flow<List<FoodItemEntity>>

    @Query("SELECT * FROM food_items WHERE id = :id")
    suspend fun getById(id: String): FoodItemEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(item: FoodItemEntity)

    @Update
    suspend fun update(item: FoodItemEntity)

    @Delete
    suspend fun delete(item: FoodItemEntity)

    @Query("SELECT COUNT(*) FROM food_items WHERE dateEaten >= :start AND dateEaten < :end")
    suspend fun countForDay(start: Long, end: Long): Int
}
