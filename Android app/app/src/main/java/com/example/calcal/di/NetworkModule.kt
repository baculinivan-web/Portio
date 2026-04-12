package com.example.calcal.di

import com.example.calcal.data.remote.NutritionService
import com.example.calcal.data.remote.OpenFoodFactsService
import com.example.calcal.data.remote.SerperService
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        })
        .build()

    @Provides
    @Singleton
    fun provideSerperService(client: OkHttpClient): SerperService = SerperService(client)

    @Provides
    @Singleton
    fun provideOpenFoodFactsService(client: OkHttpClient): OpenFoodFactsService = OpenFoodFactsService(client)

    @Provides
    @Singleton
    fun provideNutritionService(
        client: OkHttpClient,
        serperService: SerperService,
        offService: OpenFoodFactsService
    ): NutritionService = NutritionService(client, serperService, offService)
}
