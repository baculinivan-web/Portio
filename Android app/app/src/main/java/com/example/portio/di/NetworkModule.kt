package com.example.portio.di

import com.example.portio.data.remote.NutritionService
import com.example.portio.data.remote.OpenFoodFactsService
import com.example.portio.data.remote.SerperService
import com.example.portio.BuildConfig
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
    fun provideOkHttpClient(): OkHttpClient {
        val builder = OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)

        if (BuildConfig.DEBUG) {
            builder.addInterceptor(HttpLoggingInterceptor().apply {
                redactHeader("Authorization")
                redactHeader("X-API-KEY")
                level = HttpLoggingInterceptor.Level.BASIC
            })
        }

        return builder.build()
    }

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
