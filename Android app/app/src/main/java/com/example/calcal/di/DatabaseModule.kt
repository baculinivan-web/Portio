package com.example.calcal.di

import android.content.Context
import androidx.room.Room
import com.example.calcal.data.local.AppDatabase
import com.example.calcal.data.local.FoodItemDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase =
        AppDatabase.getInstance(context)

    @Provides
    fun provideFoodItemDao(db: AppDatabase): FoodItemDao = db.foodItemDao()
}
