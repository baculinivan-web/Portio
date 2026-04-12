package com.example.portio.data.remote

import com.example.portio.domain.model.SearchResult
import com.example.portio.domain.model.SearchStep
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SerperService @Inject constructor(private val okHttpClient: OkHttpClient) {

    private val apiUrl = "https://google.serper.dev/search"

    suspend fun searchStructured(query: String, apiKey: String): SearchStep = withContext(Dispatchers.IO) {
        val body = buildJsonObject { put("q", query) }.toString()
            .toRequestBody("application/json".toMediaType())

        val request = Request.Builder()
            .url(apiUrl)
            .post(body)
            .addHeader("X-API-KEY", apiKey)
            .addHeader("Content-Type", "application/json")
            .build()

        val response = okHttpClient.newCall(request).execute()
        val responseBody = response.body?.string() ?: throw Exception("Empty Serper response")

        if (!response.isSuccessful) {
            if (response.code == 403) throw Exception("Invalid Serper API key")
            throw Exception("Serper error: ${response.code}")
        }

        val json = Json.parseToJsonElement(responseBody).jsonObject
        val results = mutableListOf<SearchResult>()
        var answerBox: String? = null

        json["answerBox"]?.jsonObject?.let { ab ->
            answerBox = ab["answer"]?.jsonPrimitive?.contentOrNull
                ?: ab["snippet"]?.jsonPrimitive?.contentOrNull
        }

        json["organic"]?.jsonArray?.take(4)?.forEach { item ->
            val obj = item.jsonObject
            val title = obj["title"]?.jsonPrimitive?.contentOrNull ?: return@forEach
            val link = obj["link"]?.jsonPrimitive?.contentOrNull ?: return@forEach
            val snippet = obj["snippet"]?.jsonPrimitive?.contentOrNull ?: return@forEach
            results.add(SearchResult(title, link, snippet))
        }

        SearchStep(query = query, results = results, answerBox = answerBox)
    }
}
