package com.example.calcal.data.remote

import android.util.Base64
import com.example.calcal.domain.model.FoodArrayResponse
import com.example.calcal.domain.model.GoalResponse
import com.example.calcal.domain.model.NutritionResponse
import com.example.calcal.domain.model.NutritionResponseWithSteps
import com.example.calcal.domain.model.SearchStep
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NutritionService @Inject constructor(
    private val okHttpClient: OkHttpClient,
    private val serperService: SerperService,
    private val offService: OpenFoodFactsService
) {
    private val apiUrl = "https://openrouter.ai/api/v1/chat/completions"
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    private val toolsJson = buildJsonArray {
        addJsonObject {
            put("type", "function")
            putJsonObject("function") {
                put("name", "google_search")
                put("description", "Search Google for nutritional information or standard portion/unit weights.")
                putJsonObject("parameters") {
                    put("type", "object")
                    putJsonObject("properties") {
                        putJsonObject("query") {
                            put("type", "string")
                            put("description", "The search query")
                        }
                    }
                    putJsonArray("required") { add("query") }
                }
            }
        }
        addJsonObject {
            put("type", "function")
            putJsonObject("function") {
                put("name", "openfoodfacts_search")
                put("description", "Search OpenFoodFacts for branded/packaged products.")
                putJsonObject("parameters") {
                    put("type", "object")
                    putJsonObject("properties") {
                        putJsonObject("query") {
                            put("type", "string")
                            put("description", "Product name or brand")
                        }
                    }
                    putJsonArray("required") { add("query") }
                }
            }
        }
    }

    suspend fun fetchNutrition(
        query: String,
        images: List<ByteArray> = emptyList(),
        apiKey: String,
        modelName: String,
        serperApiKey: String
    ): List<NutritionResponseWithSteps> {
        val initialSystemPrompt = buildInitialSystemPrompt()
        val finalSystemPrompt = buildFinalSystemPrompt()

        val userContentParts = buildJsonArray {
            addJsonObject {
                put("type", "text")
                put("text", "Analyze the food query: '$query'." +
                        if (images.isNotEmpty()) " The user has also provided images." else "")
            }
            images.forEach { imgBytes ->
                val b64 = Base64.encodeToString(imgBytes, Base64.NO_WRAP)
                addJsonObject {
                    put("type", "image_url")
                    putJsonObject("image_url") { put("url", "data:image/jpeg;base64,$b64") }
                }
            }
        }

        var messages = buildJsonArray {
            addJsonObject { put("role", "system"); put("content", initialSystemPrompt) }
            addJsonObject { put("role", "user"); put("content", userContentParts) }
        }

        var capturedSearchSteps = mutableListOf<SearchStep>()
        var didUseOFF = false
        var isAnalysisPass = false

        repeat(4) { // max 4 iterations
            val requestBody = buildJsonObject {
                put("model", modelName)
                put("messages", messages)
                if (!isAnalysisPass) {
                    put("tools", toolsJson)
                    put("tool_choice", "auto")
                }
                putJsonObject("reasoning") { put("effort", "low") }
            }

            val response = postJson(apiUrl, requestBody.toString(), apiKey)
            val responseObj = json.parseToJsonElement(response).jsonObject
            val choice = responseObj["choices"]?.jsonArray?.firstOrNull()?.jsonObject
                ?: throw Exception("No choices in response")

            val message = choice["message"]?.jsonObject ?: throw Exception("No message")
            val finishReason = choice["finish_reason"]?.jsonPrimitive?.contentOrNull

            // Append assistant message to history
            val updatedMessages = messages.toMutableList()
            updatedMessages.add(message)
            messages = JsonArray(updatedMessages)

            if (finishReason == "tool_calls") {
                val toolCalls = message["tool_calls"]?.jsonArray ?: return@repeat

                // Execute tool calls in parallel
                val toolResults = coroutineScope {
                    toolCalls.map { toolCallEl ->
                        async {
                            val toolCall = toolCallEl.jsonObject
                            val toolId = toolCall["id"]?.jsonPrimitive?.content ?: ""
                            val funcObj = toolCall["function"]?.jsonObject ?: return@async null
                            val funcName = funcObj["name"]?.jsonPrimitive?.content ?: ""
                            val argsStr = funcObj["arguments"]?.jsonPrimitive?.content ?: "{}"
                            val args = json.parseToJsonElement(argsStr).jsonObject
                            val q = args["query"]?.jsonPrimitive?.contentOrNull ?: ""

                            when (funcName) {
                                "google_search" -> {
                                    try {
                                        val step = serperService.searchStructured(q, serperApiKey)
                                        capturedSearchSteps.add(step)
                                        var result = ""
                                        step.answerBox?.let { result += "Answer: $it\n" }
                                        result += "Top results:\n"
                                        step.results.forEachIndexed { i, r -> result += "${i+1}. ${r.title}: ${r.snippet}\n" }
                                        Triple(toolId, result, "google")
                                    } catch (e: Exception) {
                                        Triple(toolId, "Error: ${e.message}", "error")
                                    }
                                }
                                "openfoodfacts_search" -> {
                                    try {
                                        val products = offService.searchProducts(q)
                                        didUseOFF = true
                                        val result = if (products.isEmpty()) {
                                            "No products found in OpenFoodFacts."
                                        } else {
                                            buildString {
                                                append("Found ${products.size} products. Top 3:\n")
                                                products.take(3).forEachIndexed { i, p ->
                                                    append("${i+1}. ${p.productName ?: "Unknown"} | ${p.brands ?: ""} | serving: ${p.servingSize ?: "?"}\n")
                                                    p.nutriments?.let { n ->
                                                        append("   Per 100g: ${n.energyKcal100g ?: 0} kcal, P:${n.proteins100g ?: 0}g, C:${n.carbohydrates100g ?: 0}g, F:${n.fat100g ?: 0}g\n")
                                                    }
                                                }
                                            }
                                        }
                                        Triple(toolId, result, "off")
                                    } catch (e: Exception) {
                                        Triple(toolId, "Error: ${e.message}", "error")
                                    }
                                }
                                else -> Triple(toolId, "Unknown tool", "error")
                            }
                        }
                    }.awaitAll().filterNotNull()
                }

                val resultsSummary = toolResults.joinToString("\n") { (_, content, type) ->
                    when (type) {
                        "google" -> "[Search Result]: $content"
                        "off" -> "[Branded Product Data]: $content"
                        else -> "[Tool Error]: $content"
                    }
                }

                val finalUserPrompt = "User's Original Query: \"$query\"\n\nGathered Information:\n$resultsSummary\n\nBased on the information above, provide the final nutritional analysis."

                messages = buildJsonArray {
                    addJsonObject { put("role", "system"); put("content", finalSystemPrompt) }
                    addJsonObject { put("role", "user"); put("content", finalUserPrompt) }
                }
                isAnalysisPass = true

            } else {
                // Final response — parse JSON
                var nutritionText = message["content"]?.jsonPrimitive?.contentOrNull
                    ?: throw Exception("No content in final response")

                val start = nutritionText.indexOf('{')
                val end = nutritionText.lastIndexOf('}')
                if (start >= 0 && end > start) nutritionText = nutritionText.substring(start, end + 1)

                val foodArray = json.decodeFromString<FoodArrayResponse>(nutritionText)
                var foods = foodArray.foods.toMutableList()

                // Attach search grounding info
                if (didUseOFF) {
                    foods = foods.map { food ->
                        val currentSource = food.dataSource
                        val newSource = when {
                            currentSource.isNullOrBlank() -> "OFF"
                            currentSource.contains("OFF") -> currentSource
                            else -> "$currentSource, OFF"
                        }
                        food.copy(
                            isSearchGrounded = true,
                            dataSource = newSource
                        )
                    }.toMutableList()
                } else if (capturedSearchSteps.isNotEmpty()) {
                    foods = foods.map { food ->
                        if (food.isSearchGrounded == true) food
                        else food.copy(isSearchGrounded = true)
                    }.toMutableList()
                }

                return foods.map { food ->
                    NutritionResponseWithSteps(
                        response = food,
                        searchSteps = if (food.isSearchGrounded == true) capturedSearchSteps else emptyList()
                    )
                }
            }
        }

        throw Exception("Max tool-call iterations reached")
    }

    suspend fun fetchAIGoals(
        userStats: String,
        userGoals: String,
        baselineTdee: Double,
        apiKey: String,
        modelName: String
    ): GoalResponse {
        val prompt = """
            Act as a nutrition planning expert. Based on the following user data, determine their daily nutritional goals.
            User Data: $userStats
            User's Personal Goals: "$userGoals"
            The user's calculated baseline TDEE is ${baselineTdee.toInt()} calories.
            
            CRITICAL: Your entire response must be ONLY a single, minified JSON object with keys:
            "calories", "protein", "carbs", "fat" (all Double), "explanation" (String).
        """.trimIndent()

        val requestBody = buildJsonObject {
            put("model", modelName)
            putJsonArray("messages") {
                addJsonObject { put("role", "user"); put("content", prompt) }
            }
        }

        val response = postJson(apiUrl, requestBody.toString(), apiKey)
        val responseObj = json.parseToJsonElement(response).jsonObject
        var goalText = responseObj["choices"]?.jsonArray?.firstOrNull()
            ?.jsonObject?.get("message")?.jsonObject?.get("content")?.jsonPrimitive?.content
            ?: throw Exception("No content in goal response")

        val start = goalText.indexOf('{')
        val end = goalText.lastIndexOf('}')
        if (start >= 0 && end > start) goalText = goalText.substring(start, end + 1)

        return json.decodeFromString(goalText)
    }

    private suspend fun postJson(url: String, body: String, apiKey: String): String = withContext(Dispatchers.IO) {
        val request = Request.Builder()
            .url(url)
            .post(body.toRequestBody("application/json".toMediaType()))
            .addHeader("Authorization", "Bearer $apiKey")
            .addHeader("Content-Type", "application/json")
            .addHeader("HTTP-Referer", "https://calcal.app")
            .addHeader("X-Title", "CalCal")
            .build()

        val response = okHttpClient.newCall(request).execute()
        val responseBody = response.body?.string() ?: throw Exception("Empty response")
        if (!response.isSuccessful) throw Exception("API error ${response.code}: $responseBody")
        responseBody
    }

    private fun buildInitialSystemPrompt() = """
        You are a highly accurate nutritional analysis expert.
        Analyze the food query and images provided by the user to identify each distinct food item.
        
        LANGUAGE & BRAND RULE: The query can be in ANY language (Russian, English, etc.). Brand names may be local/regional brands from any country — do NOT assume a foreign-sounding name maps to a well-known global brand. For example, "актимуно" is a Russian brand and is NOT the same as "Actimel". Always search for the exact name as given.
        
        CRITICAL SEARCH RULE: You MUST use tools for ANY of the following — no exceptions:
        - Any branded or packaged product (Oreo, Activia, Lay's, Snickers, Актимуно, etc.)
        - Any product with a recognizable brand name, even if you think you know the nutrition
        - Any restaurant or fast food item
        - Any product name that sounds like a brand (even if unfamiliar or in a foreign language)
        - Any query where the user specifies a quantity of a packaged item (e.g. "3 oreo", "2 актимуно")
        - When in doubt — always search, never guess
        
        Only skip tools for completely generic, unbranded whole foods (e.g. "apple", "boiled egg", "rice", "яблоко", "варёное яйцо").
        
        CRITICAL TOOL BATCHING RULE: Emit ALL necessary tool calls in a SINGLE response turn. Execute them in parallel.
        
        TOOL PRIORITY RULE:
        1. openfoodfacts_search: Use FIRST for ALL branded/packaged products. Pass ONLY brand and product name, no weights or quantities.
        2. google_search: Use if OFF returns no results, or for restaurant items/generic dishes.
        
        Do not output JSON yet. Focus on gathering data.
    """.trimIndent()

    private fun buildFinalSystemPrompt() = """
        You are a highly accurate nutritional analysis expert.
        
        Analyze the tool results and original query. For branded items without specified weight, use the standard serving size from tools.
        
        If you used a tool, set "isSearchGrounded" to true for that item.
        Set "dataSource" to "OFF" if data came from OpenFoodFacts, "Google" if from Google Search, or null if from internal knowledge.
        
        Your final response MUST be ONLY a single minified JSON object:
        {"foods": [{"identifiedFood": String, "cleanFoodName": String, "calories": Double, "protein": Double, "carbs": Double, "fat": Double, "estimatedWeightGrams": Double, "caloriesPer100g": Double, "proteinPer100g": Double, "carbsPer100g": Double, "fatPer100g": Double, "isSearchGrounded": Boolean, "dataSource": String|null}]}
        
        identifiedFood and cleanFoodName MUST be in the same language as the input query.
    """.trimIndent()
}
