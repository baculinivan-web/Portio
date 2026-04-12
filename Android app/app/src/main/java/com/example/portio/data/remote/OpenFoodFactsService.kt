package com.example.portio.data.remote

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.Request
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class OpenFoodFactsService @Inject constructor(private val okHttpClient: OkHttpClient) {

    private val baseUrl = "https://world.openfoodfacts.org"
    private val userAgent = "Portio - Android - Version 1.0 - https://portio.app"
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    suspend fun searchProducts(query: String): List<OFFProduct> = withContext(Dispatchers.IO) {
        val encoded = java.net.URLEncoder.encode(query, "UTF-8")
        val url = "$baseUrl/cgi/search.pl?search_terms=$encoded&search_simple=1&action=process&json=1" +
                "&fields=product_name,brands,nutriments,serving_size,quantity,code"

        val request = Request.Builder()
            .url(url)
            .addHeader("User-Agent", userAgent)
            .build()

        val response = okHttpClient.newCall(request).execute()
        val body = response.body?.string() ?: throw Exception("Empty OFF response")

        if (!response.isSuccessful) throw Exception("OFF error: ${response.code}")

        json.decodeFromString<OFFSearchResult>(body).products
    }
}
