package com.example.portio.data.remote

import android.util.Base64
import com.example.portio.data.preferences.UserSettings
import com.example.portio.domain.model.FoodArrayResponse
import com.example.portio.domain.model.GoalResponse
import com.example.portio.domain.model.NutritionResponse
import com.example.portio.domain.model.NutritionResponseWithSteps
import com.example.portio.domain.model.SearchStep
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
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NutritionService @Inject constructor(
    private val okHttpClient: OkHttpClient,
    private val serperService: SerperService,
    private val offService: OpenFoodFactsService
) {
    private data class ToolExecutionResult(
        val toolId: String,
        val content: String,
        val type: String,
        val searchStep: SearchStep? = null,
        val usedOff: Boolean = false
    )

    private val defaultApiUrl = "https://openrouter.ai/api/v1/chat/completions"
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    /** Resolves the chat completions URL from a base URL or falls back to OpenRouter. */
    private fun resolveApiUrl(customBaseUrl: String): String {
        if (customBaseUrl.isBlank()) return defaultApiUrl
        val base = customBaseUrl.trimEnd('/')
        return if (base.endsWith("/chat/completions")) base else "$base/chat/completions"
    }

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
        serperApiKey: String,
        customApiBaseUrl: String = "",
        llmProvider: UserSettings.LLMProvider = UserSettings.LLMProvider.OPEN_ROUTER,
        blockRunWalletId: String = "",
        blockRunProxyUrl: String = ""
    ): List<NutritionResponseWithSteps> {
        val apiUrl = if (llmProvider == UserSettings.LLMProvider.BLOCKRUN) {
            val base = blockRunProxyUrl.trimEnd('/')
            if (base.endsWith("/chat/completions")) base else "$base/chat/completions"
        } else {
            resolveApiUrl(customApiBaseUrl)
        }

        val actualApiKey = if (llmProvider == UserSettings.LLMProvider.BLOCKRUN) {
            blockRunWalletId.ifBlank { throw Exception("BlockRun wallet key is required") }
        } else {
            apiKey
        }

        val actualModel = if (llmProvider == UserSettings.LLMProvider.BLOCKRUN && modelName.isBlank()) "nvidia/mistral-small-4-119b" else modelName

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

        val capturedSearchSteps = mutableListOf<SearchStep>()
        var didUseOFF = false
        var isAnalysisPass = false

        repeat(4) { // max 4 iterations
            val requestBody = buildJsonObject {
                put("model", actualModel)
                put("messages", messages)
                if (!isAnalysisPass) {
                    put("tools", toolsJson)
                    put("tool_choice", "auto")
                }
                putJsonObject("reasoning") { put("effort", "low") }
            }

            val response = postJson(
                url = apiUrl,
                body = requestBody.toString(),
                apiKey = actualApiKey,
                includeOpenRouterHeaders = llmProvider == UserSettings.LLMProvider.OPEN_ROUTER
            )
            val responseObj = json.parseToJsonElement(response).jsonObject
            val choice = responseObj["choices"]?.jsonArray?.firstOrNull()?.jsonObject
                ?: throw Exception("No choices in response")

            var message = choice["message"]?.jsonObject ?: throw Exception("No message")
            var finishReason = choice["finish_reason"]?.jsonPrimitive?.contentOrNull

            // Check if the model returned a tool call in the 'content' field instead of 'tool_calls'
            val content = message["content"]?.jsonPrimitive?.contentOrNull
            if ((message["tool_calls"] == null || message["tool_calls"]?.jsonArray?.isEmpty() == true) &&
                content != null && content.contains("\"name\":") && content.contains("\"parameters\":")) {

                val start = content.indexOf('{')
                val end = content.lastIndexOf('}')
                if (start >= 0 && end > start) {
                    val tcStr = content.substring(start, end + 1)
                    try {
                        val tcJson = json.parseToJsonElement(tcStr).jsonObject
                        val funcName = tcJson["name"]?.jsonPrimitive?.contentOrNull
                        if (funcName != null) {
                            val params = tcJson["parameters"]?.jsonObject ?: buildJsonObject {}
                            val manualToolCall = buildJsonObject {
                                put("id", "call_manual_${UUID.randomUUID().toString().take(8)}")
                                put("type", "function")
                                putJsonObject("function") {
                                    put("name", funcName)
                                    put("arguments", params.toString())
                                }
                            }
                            val updatedMessage = message.toMutableMap()
                            updatedMessage["tool_calls"] = buildJsonArray { add(manualToolCall) }
                            message = JsonObject(updatedMessage)
                            finishReason = "tool_calls"
                        }
                    } catch (e: Exception) {
                        // Ignore parsing error for manual tool call detection
                    }
                }
            }

            // Append assistant message to history
            val updatedMessages = messages.toMutableList()
            // Some models return empty tool_calls array, we should normalize it to null/omitted for history
            val messageToStore = if (message["tool_calls"]?.jsonArray?.isEmpty() == true) {
                val map = message.toMutableMap()
                map.remove("tool_calls")
                JsonObject(map)
            } else {
                message
            }
            updatedMessages.add(messageToStore)
            messages = JsonArray(updatedMessages)

            if (finishReason == "tool_calls" && message["tool_calls"]?.jsonArray?.isNotEmpty() == true) {
                val toolCalls = message["tool_calls"]?.jsonArray ?: return@repeat

                // Execute tool calls in parallel; each task returns immutable metadata.
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
                                        var result = ""
                                        step.answerBox?.let { result += "Answer: $it\n" }
                                        result += "Top results:\n"
                                        step.results.forEachIndexed { i, r -> result += "${i+1}. ${r.title}: ${r.snippet}\n" }
                                        ToolExecutionResult(toolId, result, "google", step, usedOff = false)
                                    } catch (e: Exception) {
                                        ToolExecutionResult(toolId, "Error: ${e.message}", "error")
                                    }
                                }
                                "openfoodfacts_search" -> {
                                    try {
                                        val products = offService.searchProducts(q)
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
                                        ToolExecutionResult(toolId, result, "off", usedOff = true)
                                    } catch (e: Exception) {
                                        ToolExecutionResult(toolId, "Error: ${e.message}", "error")
                                    }
                                }
                                else -> ToolExecutionResult(toolId, "Unknown tool", "error")
                            }
                        }
                    }.awaitAll().filterNotNull()
                }
                capturedSearchSteps.addAll(toolResults.mapNotNull { it.searchStep })
                didUseOFF = didUseOFF || toolResults.any { it.usedOff }

                val resultsSummary = toolResults.joinToString("\n") { result ->
                    when (result.type) {
                        "google" -> "[Search Result]: ${result.content}"
                        "off" -> "[Branded Product Data]: ${result.content}"
                        else -> "[Tool Error]: ${result.content}"
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
        modelName: String,
        customApiBaseUrl: String = "",
        llmProvider: UserSettings.LLMProvider = UserSettings.LLMProvider.OPEN_ROUTER,
        blockRunWalletId: String = "",
        blockRunProxyUrl: String = ""
    ): GoalResponse {
        val apiUrl = if (llmProvider == UserSettings.LLMProvider.BLOCKRUN) {
            val base = blockRunProxyUrl.trimEnd('/')
            if (base.endsWith("/chat/completions")) base else "$base/chat/completions"
        } else {
            resolveApiUrl(customApiBaseUrl)
        }

        val actualApiKey = if (llmProvider == UserSettings.LLMProvider.BLOCKRUN) {
            blockRunWalletId.ifBlank { throw Exception("BlockRun wallet key is required") }
        } else {
            apiKey
        }

        val actualModel = if (llmProvider == UserSettings.LLMProvider.BLOCKRUN && modelName.isBlank()) "nvidia/mistral-small-4-119b" else modelName

        val prompt = """
            Act as a nutrition planning expert. Based on the following user data, determine their daily nutritional goals.
            User Data: $userStats
            User's Personal Goals: "$userGoals"
            The user's calculated baseline TDEE is ${baselineTdee.toInt()} calories.

            CRITICAL: Your entire response must be ONLY a single, minified JSON object with keys:
            "calories", "protein", "carbs", "fat" (all Double), "explanation" (String).
        """.trimIndent()

        val requestBody = buildJsonObject {
            put("model", actualModel)
            putJsonArray("messages") {
                addJsonObject { put("role", "user"); put("content", prompt) }
            }
        }

        val response = postJson(
            url = apiUrl,
            body = requestBody.toString(),
            apiKey = actualApiKey,
            includeOpenRouterHeaders = llmProvider == UserSettings.LLMProvider.OPEN_ROUTER
        )
        val responseObj = json.parseToJsonElement(response).jsonObject
        var goalText = responseObj["choices"]?.jsonArray?.firstOrNull()
            ?.jsonObject?.get("message")?.jsonObject?.get("content")?.jsonPrimitive?.content
            ?: throw Exception("No content in goal response")

        val start = goalText.indexOf('{')
        val end = goalText.lastIndexOf('}')
        if (start >= 0 && end > start) goalText = goalText.substring(start, end + 1)

        return json.decodeFromString(goalText)
    }

    private suspend fun postJson(
        url: String,
        body: String,
        apiKey: String,
        includeOpenRouterHeaders: Boolean
    ): String = withContext(Dispatchers.IO) {
        val requestBuilder = Request.Builder()
            .url(url)
            .post(body.toRequestBody("application/json".toMediaType()))
            .addHeader("Authorization", "Bearer $apiKey")
            .addHeader("Content-Type", "application/json")

        if (includeOpenRouterHeaders) {
            requestBuilder
                .addHeader("HTTP-Referer", "https://portio.app")
                .addHeader("X-Title", "Portio")
        }

        val request = requestBuilder.build()

        val response = okHttpClient.newCall(request).execute()
        val responseBody = response.body?.string() ?: throw Exception("Empty response")
        if (!response.isSuccessful) throw Exception("API error ${response.code}: $responseBody")
        responseBody
    }

    private fun buildInitialSystemPrompt() = """
        You are a highly accurate nutritional analysis expert.
        Analyze the food query and images provided by the user to identify each distinct food item.

        CRITICAL: If the query contains generic, unbranded whole foods (e.g. "apple", "boiled egg", "rice", "яблоко", "варёное яйцо") and you have enough information to provide nutritional data, you MUST output the final JSON immediately.

        Otherwise, if you need more information for branded products, restaurant items, or specific queries, you MUST use the provided tools.

        LANGUAGE & BRAND RULE: The query can be in ANY language (Russian, English, etc.). Brand names may be local/regional brands from any country — do NOT assume a foreign-sounding name maps to a well-known global brand. For example, "актимуно" is a Russian brand and is NOT the same as "Actimel". Always search for the exact name as given.

        CRITICAL SEARCH RULE: You MUST use tools for ANY of the following — no exceptions:
        - Any branded or packaged product (Oreo, Activia, Lay's, Snickers, Актимуно, etc.)
        - Any product with a recognizable brand name, even if you think you know the nutrition
        - Any restaurant or fast food item
        - Any product name that sounds like a brand (even if unfamiliar or in a foreign language)
        - Any query where the user specifies a quantity of a packaged item (e.g. "3 oreo", "2 актимуно")
        - When in doubt — always search, never guess

        CRITICAL TOOL BATCHING RULE: Emit ALL necessary tool calls in a SINGLE response turn. Execute them in parallel.

        TOOL PRIORITY RULE:
        1. openfoodfacts_search: Use FIRST for ALL branded/packaged products. Pass ONLY brand and product name, no weights or quantities.
        2. google_search: Use if OFF returns no results, or for restaurant items/generic dishes.

        IF YOU ARE OUTPUTTING THE FINAL JSON:
        - It MUST be a single, minified JSON object with the "foods" array.
        - Each food item MUST have these exact keys: "identifiedFood", "cleanFoodName", "calories", "protein", "carbs", "fat", "estimatedWeightGrams", "caloriesPer100g", "proteinPer100g", "carbsPer100g", "fatPer100g", "isSearchGrounded" (boolean).
        - Set "isSearchGrounded" to true ONLY if you used a tool.
        - DO NOT include any text before or after the JSON.

        SCHEMA: {"foods": [{"identifiedFood": String, "cleanFoodName": String, "calories": Double, "protein": Double, "carbs": Double, "fat": Double, "estimatedWeightGrams": Double, "caloriesPer100g": Double, "proteinPer100g": Double, "carbsPer100g": Double, "fatPer100g": Double, "isSearchGrounded": Boolean, "dataSource": String|null}]}
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
