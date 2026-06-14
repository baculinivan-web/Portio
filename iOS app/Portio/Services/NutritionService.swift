import Foundation

// Custom, more descriptive errors
enum NutritionError: Error, LocalizedError {
    case missingAPIKey(String)
    case invalidAPIKey
    case badRequest
    case badResponse
    case unparsableJSON(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let providerName):
            return "\(providerName) API key is missing. Open Settings and enter the key again for this installation."
        case .invalidAPIKey:
            return "Invalid OpenRouter API key. Please check your key in Settings."
        case .badRequest:
            return "The request to the server was malformed."
        case .badResponse:
            return "The server returned an invalid response."
        case .unparsableJSON(let details):
            return "Could not parse the nutrition data from the AI. Details: \(details)"
        case .apiError(let message):
            return "OpenRouter API Error: \(message)"
        }
    }
}

// MARK: - Networking Service
class NutritionService {
    private let apiKey: String
    private let modelName: String
    private let serperService: SerperService
    private let apiURL: URL
    private let provider: UserSettings.LLMProvider
    private let offService = OpenFoodFactsService()
    nonisolated static var initialSystemPromptForTesting: String { initialSystemPrompt }
    nonisolated static func initialToolChoiceForTesting(hasImages: Bool) -> OpenRouterRequest.ToolChoice {
        initialToolChoice(hasImages: hasImages)
    }
    nonisolated static func toolChoiceForTesting(hasExecutedTools: Bool, hasImages: Bool) -> OpenRouterRequest.ToolChoice {
        toolChoice(hasExecutedTools: hasExecutedTools, hasImages: hasImages)
    }
    nonisolated static func canAcceptFinalResponseForTesting(hasExecutedTools: Bool, hasImages: Bool) -> Bool {
        canAcceptFinalResponse(hasExecutedTools: hasExecutedTools, hasImages: hasImages)
    }
    nonisolated static func extractManualToolCallForTesting(from content: String, hasExecutedTools: Bool) -> ToolCall? {
        extractManualToolCall(from: content, hasExecutedTools: hasExecutedTools)
    }
    nonisolated static func shouldSendNativeToolsForTesting(hasExecutedTools: Bool, hasImages: Bool) -> Bool {
        shouldSendNativeTools(hasExecutedTools: hasExecutedTools, hasImages: hasImages)
    }

    private enum ToolResult {
        case google(id: String, content: String, step: SearchStep)
        case off(id: String, content: String)
        case error(id: String, content: String)
    }

    nonisolated private static let initialSystemPrompt = """
        You are a highly accurate nutritional analysis expert.
        Analyze the food query and images provided by the user to identify each distinct food item.

        Your primary goal is reliable nutrition data. Use your internal nutrition knowledge for ordinary generic foods, and use tools when the item needs grounding.

        LANGUAGE & BRAND RULE: The query can be in ANY language (Russian, English, etc.). Brand names may be local/regional brands from any country — do NOT assume a foreign-sounding name maps to a well-known global brand. For example, "актимуно" is a Russian brand and is NOT the same as "Actimel". Always search for the exact name as given.

        FIRST-PASS DECISION RULE:
        - If the food is generic, unbranded, and you can estimate it reliably, output the final JSON immediately without tools.
        - If the item is branded, packaged, restaurant-made, regional, ambiguous, or uncertain, use tools before final JSON.

        CRITICAL SEARCH RULE: You MUST use tools for ANY of the following — no exceptions:
        - Any branded or packaged product (Oreo, Activia, Lay's, Snickers, Актимуно, etc.)
        - Any product with a recognizable brand name, even if you think you know the nutrition
        - Any restaurant or fast food item
        - Any product name that sounds like a brand (even if unfamiliar or in a foreign language)
        - Any query where the user specifies a quantity of a packaged item (e.g. "3 oreo", "2 актимуно")
        - When in doubt — always search, never guess

        Skip tools for completely generic, unbranded foods when reliable nutrition data is common knowledge (e.g. "apple", "boiled egg", "rice", "яблоко", "варёное яйцо").

        CRITICAL TOOL BATCHING RULE: Analyze the entire query first. If multiple items need searching (e.g. "Apple and Coke"), or if a single item requires multiple tools, you MUST emit ALL necessary tool calls in a SINGLE response turn. Do NOT wait for the result of one tool before calling the next. We can execute them in parallel.

        TOOL PRIORITY RULE:
        1. `openfoodfacts_search`: Use this FIRST for ALL branded/packaged products. The data is structured and highly reliable.
           CRITICAL: When using `openfoodfacts_search`, pass ONLY the brand and product name (e.g., "Coke Zero", "Snickers", "Актимуно"). DO NOT include weights, volumes, or packaging details (e.g., "0.33l", "50g", "box") in the search query, as this often causes the search to fail. The tool will return available sizes/quantities for you to select from.
        2. `google_search`: Use this if `openfoodfacts_search` returns no results, or for restaurant menu items ("Big Mac"), generic dishes ("Caesar Salad"), or specific queries requiring web synthesis.

        If native tool-calling is unavailable and you need external search, output ONLY one minified JSON object in this exact shape: {"name":"google_search","parameters":{"query":"search terms"}} or {"name":"openfoodfacts_search","parameters":{"query":"product name"}}. Do not wrap it in markdown or add explanations.

        After tool results are available, use those results in the final JSON. If no tools were needed, output final JSON from your internal nutrition knowledge and set "isSearchGrounded" to false.
        """

    nonisolated private static func initialToolChoice(hasImages _: Bool) -> OpenRouterRequest.ToolChoice {
        .auto
    }

    nonisolated private static func toolChoice(hasExecutedTools: Bool, hasImages: Bool) -> OpenRouterRequest.ToolChoice {
        hasExecutedTools ? .none : initialToolChoice(hasImages: hasImages)
    }

    nonisolated private static func shouldSendNativeTools(hasExecutedTools: Bool, hasImages: Bool) -> Bool {
        hasExecutedTools || !hasImages
    }

    nonisolated private static func canAcceptFinalResponse(hasExecutedTools _: Bool, hasImages _: Bool) -> Bool {
        true
    }

    init(apiKey: String, modelName: String, serperApiKey: String, customBaseURL: String? = nil, provider: UserSettings.LLMProvider = .openRouter) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.serperService = SerperService(apiKey: serperApiKey)
        self.provider = provider

        if provider == .blockRun {
            let base = UserSettings.blockRunProxyUrl.trimmingCharacters(in: .init(charactersIn: "/"))
            let fullURL = base.hasSuffix("/chat/completions") ? base : "\(base)/chat/completions"
            self.apiURL = URL(string: fullURL) ?? URL(string: "https://api.blockrun.ai/v1/chat/completions")!
        } else if let customBaseURL = customBaseURL, !customBaseURL.isEmpty {
            let base = customBaseURL.trimmingCharacters(in: .init(charactersIn: "/"))
            let fullURL = base.hasSuffix("/chat/completions") ? base : "\(base)/chat/completions"
            self.apiURL = URL(string: fullURL) ?? URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        } else {
            self.apiURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        }
    }

    nonisolated static func extractManualToolCall(from content: String) -> ToolCall? {
        extractManualToolCall(from: content, hasExecutedTools: false)
    }

    nonisolated private static func extractManualToolCall(from content: String, hasExecutedTools: Bool) -> ToolCall? {
        guard !hasExecutedTools else { return nil }

        struct ManualToolCallEnvelope: Decodable {
            let name: String
            let parameters: [String: JSONValue]

            private enum CodingKeys: String, CodingKey {
                case name
                case parameters
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let keys = Set(container.allKeys.map(\.stringValue))
                guard keys == ["name", "parameters"] else {
                    throw DecodingError.dataCorrupted(
                        .init(codingPath: decoder.codingPath, debugDescription: "Unexpected manual tool call shape")
                    )
                }

                name = try container.decode(String.self, forKey: .name)
                parameters = try container.decode([String: JSONValue].self, forKey: .parameters)
            }
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "{", trimmed.last == "}" else { return nil }

        let decoder = JSONDecoder()
        guard let envelope = try? decoder.decode(ManualToolCallEnvelope.self, from: Data(trimmed.utf8)),
              ["google_search", "openfoodfacts_search"].contains(envelope.name) else {
            return nil
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let argumentData = try? encoder.encode(envelope.parameters),
              let argumentString = String(data: argumentData, encoding: .utf8) else {
            return nil
        }

        return ToolCall(
            id: "call_manual_\(UUID().uuidString.prefix(8))",
            type: "function",
            function: .init(name: envelope.name, arguments: argumentString)
        )
    }

    private func executeToolCalls(_ toolCalls: [ToolCall]) async -> [ToolResult] {
        await withTaskGroup(of: ToolResult.self) { group in
            for toolCall in toolCalls {
                group.addTask {
                    guard let argsData = toolCall.function.arguments.data(using: .utf8),
                          let args = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any],
                          let searchQuery = args["query"] as? String else {
                        return .error(id: toolCall.id, content: "Error: Invalid arguments")
                    }

                    switch toolCall.function.name {
                    case "google_search":
                        return await self.executeGoogleSearch(id: toolCall.id, query: searchQuery)
                    case "openfoodfacts_search":
                        return await self.executeOpenFoodFactsSearch(id: toolCall.id, query: searchQuery)
                    default:
                        return .error(id: toolCall.id, content: "Error: Unknown tool")
                    }
                }
            }

            var results: [ToolResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    private func executeGoogleSearch(id: String, query: String) async -> ToolResult {
        do {
            let searchStep = try await serperService.searchStructured(query: query)
            var resultString = ""
            if let answer = searchStep.answerBox {
                resultString += "Answer: \(answer)\n"
            }
            resultString += "Top results (4):\n"
            for (i, res) in searchStep.results.enumerated() {
                resultString += "\(i + 1). \(res.title): \(res.snippet)\n"
            }
            return .google(id: id, content: resultString, step: searchStep)
        } catch {
            return .error(id: id, content: "Google Search error: \(error.localizedDescription)")
        }
    }

    private func executeOpenFoodFactsSearch(id: String, query: String) async -> ToolResult {
        do {
            let products = try await offService.searchProducts(query: query)
            var resultString = ""
            if products.isEmpty {
                resultString = "No products found in OpenFoodFacts database."
            } else {
                resultString = "Found \(products.count) products. Top 3 relevant results:\n"
                for (i, product) in products.prefix(3).enumerated() {
                    resultString += "\(i + 1). Name: \(product.productName ?? "Unknown") | Brand: \(product.brands ?? "Unknown") | Serving: \(product.servingSize ?? "Unknown")\n"
                    if let nuts = product.nutriments {
                        resultString += "   Per 100g: \(nuts.energyKcal100g ?? 0) kcal, P: \(nuts.proteins100g ?? 0)g, C: \(nuts.carbohydrates100g ?? 0)g, F: \(nuts.fat100g ?? 0)g\n"
                    }
                }
            }
            return .off(id: id, content: resultString)
        } catch {
            return .error(id: id, content: "OpenFoodFacts error: \(error.localizedDescription)")
        }
    }

    private func summarizeToolResults(_ results: [ToolResult], capturedSearchSteps: inout [SearchStep], didUseOFF: inout Bool) -> String {
        var resultsSummary = ""
        for result in results {
            switch result {
            case .google(_, let content, let step):
                capturedSearchSteps.append(step)
                resultsSummary += "\n[Search Result]: \(content)\n"
            case .off(_, let content):
                didUseOFF = true
                resultsSummary += "\n[Branded Product Data]: \(content)\n"
            case .error(_, let content):
                resultsSummary += "\n[Tool Error]: \(content)\n"
            }
        }
        return resultsSummary
    }

    func fetchNutrition(for query: String, images: [Data] = []) async throws -> [NutritionResponse] {
        try validateProviderCredentials()

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"

        // BlockRun (ClawRouter) uses either 'x402' for local-only auth or the wallet ID for signed requests.
        // We'll use the wallet ID if provided, otherwise x402.
        if UserSettings.llmProvider == .blockRun {
            let authKey = UserSettings.blockRunWalletId.isEmpty ? "x402" : UserSettings.blockRunWalletId
            request.addValue("Bearer \(authKey)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add HTTP Referer (required by OpenRouter for some tiers, good practice)
        request.addValue("https://portio.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Portio", forHTTPHeaderField: "X-Title")

        let initialSystemPrompt = Self.initialSystemPrompt

        let finalSystemPrompt = """
        You are a highly accurate nutritional analysis expert.

        CRITICAL: Analyze the tool results provided in the conversation history and the original user query.

        CRITICAL PORTION ESTIMATION RULE: For branded or packaged items, if the user does not specify a weight, you MUST use the serving size or unit weight returned by the tools. NEVER default to 100g if the standard unit weight is different.

        CRITICAL: If you used a tool to find information for a food item, you MUST set the "isSearchGrounded" key to true for that item in your JSON response.

        CRITICAL: Your final response MUST be ONLY a single, minified JSON object with the "foods" array.

        The JSON object must have a single key "foods" which is an array of objects. Each object in the array must have these exact keys and value types:
        - "identifiedFood": String (A descriptive name, e.g., "1 large apple")
        - "cleanFoodName": String (A simple, clean name for the food, e.g., "Apple" or "Beef Patty". This should not include quantities or weights.)
        - "calories": Double (for the estimated portion weight)
        - "protein": Double (for the estimated portion weight)
        - "carbs": Double (for the estimated portion weight)
        - "fat": Double (for the estimated portion weight)
        - "estimatedWeightGrams": Double (The realistic weight of the portion. For branded items without weight specified, use the weight of ONE standard package/unit. Use search if unknown.)
        - "caloriesPer100g": Double
        - "proteinPer100g": Double
        - "carbsPer100g": Double
        - "fatPer100g": Double
        - "isSearchGrounded": Boolean
        - "dataSource": String (Optional: "OFF" for OpenFoodFacts, "Google" for Google Search, or null/omitted for internal knowledge)
        If the query is "an apple and a banana", you must return two separate objects in the "foods" array. If the query is "a glass of milk", return one object in the array.
        CRITICAL: The `identifiedFood` and `cleanFoodName` strings in your JSON response MUST be in the same language as the input query.
        """

        var userPrompt = "Analyze the food query: '\(query)'."

        if !images.isEmpty {
            userPrompt += " The user has also provided images of the food. Use them to identify the food and estimate portions."
        }

        var contentParts: [OpenRouterRequest.ContentPart] = [.text(userPrompt)]

        for imageData in images {
            let base64 = imageData.base64EncodedString()
            let url = "data:image/jpeg;base64,\(base64)"
            contentParts.append(.imageUrl(url))
        }

        let systemPrompt = "\(initialSystemPrompt)\n\n\(finalSystemPrompt)"

        var messages: [OpenRouterRequest.Message] = [
            .init(role: "system", content: .string(systemPrompt)),
            .init(role: "user", content: .parts(contentParts))
        ]

        let tools: [OpenRouterRequest.Tool] = [
            .init(
                type: "function",
                function: .init(
                    name: "google_search",
                    description: "Search Google for nutritional information or standard portion/unit weights of specific food items, brands, or restaurant menu items.",
                    parameters: [
                        "type": .string("object"),
                        "properties": .object([
                            "query": .object([
                                "type": .string("string"),
                                "description": .string("The search query, e.g., 'McDonalds Big Mac nutrition facts', 'weight of one Snickers bar', or 'Сырок Ростагроэкспорт вес 1 шт'.")
                            ])
                        ]),
                        "required": .array([.string("query")])
                    ]
                )
            ),
            .init(
                type: "function",
                function: .init(
                    name: "openfoodfacts_search",
                    description: "Search OpenFoodFacts database for branded, packaged products to get precise nutritional data and serving sizes.",
                    parameters: [
                        "type": .string("object"),
                        "properties": .object([
                            "query": .object([
                                "type": .string("string"),
                                "description": .string("The product name or brand to search for, e.g., 'Nutella', 'Coca Cola', 'Oreo'.")
                            ])
                        ]),
                        "required": .array([.string("query")])
                    ]
                )
            )
        ]

        var capturedSearchSteps: [SearchStep] = []
        var didUseOFF = false
        var hasExecutedTools = false

        // Loop for tool calling
        for _ in 0...3 { // Limit to 3 iterations to avoid infinite loops
            NutritionDiagnostics.log("OpenRouter request model=\(self.modelName), hasExecutedTools=\(hasExecutedTools), messageCount=\(messages.count)")

            let openRouterRequest = OpenRouterRequest(
                model: self.modelName,
                messages: messages,
                responseFormat: nil,
                tools: Self.shouldSendNativeTools(hasExecutedTools: hasExecutedTools, hasImages: !images.isEmpty) ? tools : nil,
                toolChoice: Self.toolChoice(hasExecutedTools: hasExecutedTools, hasImages: !images.isEmpty),
                reasoning: .init(effort: "low") // Optimize for speed
            )

            request.httpBody = try JSONEncoder().encode(openRouterRequest)

            let (data, response) = try await URLSession.shared.data(for: request)

            NutritionDiagnostics.log("OpenRouter response bytes=\(data.count)")

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if let httpResponse = response as? HTTPURLResponse {
                     NutritionDiagnostics.log("fetchNutrition failed status=\(httpResponse.statusCode), bytes=\(data.count)")

                     if let errorResponse = try? JSONDecoder().decode(OpenRouterErrorResponse.self, from: data) {
                        throw NutritionError.apiError(errorResponse.error.message)
                     }

                     if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        throw NutritionError.invalidAPIKey
                     }
                }
                throw NutritionError.badResponse
            }

            let openRouterResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
            guard let choice = openRouterResponse.choices.first else {
                throw NutritionError.badResponse
            }

            var message = choice.message

            // Check if the model returned a tool call in the 'content' field instead of 'tool_calls'
            if (message.toolCalls == nil || message.toolCalls?.isEmpty == true),
               let content = message.content,
               let manualToolCall = Self.extractManualToolCall(from: content, hasExecutedTools: hasExecutedTools) {
                message.toolCalls = [manualToolCall]
            }

            // Add the assistant's message to the history
            messages.append(.init(
                role: "assistant",
                content: message.content != nil ? .string(message.content!) : nil,
                toolCalls: (message.toolCalls?.isEmpty == true) ? nil : message.toolCalls
            ))

            let canExecuteToolCalls = !hasExecutedTools
            if canExecuteToolCalls,
               (choice.finishReason == "tool_calls" || (message.toolCalls != nil && !message.toolCalls!.isEmpty)),
               let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                let results = await executeToolCalls(toolCalls)
                let resultsSummary = summarizeToolResults(results, capturedSearchSteps: &capturedSearchSteps, didUseOFF: &didUseOFF)
                messages = [
                    .init(role: "system", content: .string(finalSystemPrompt)),
                    .init(
                        role: "user",
                        content: .string("""
                        Original food query: "\(query)"

                        Gathered search data:
                        \(resultsSummary)

                        Use the gathered data above and return the final nutrition JSON now. Do not call any tools again.
                        """)
                    )
                ]
                hasExecutedTools = true

                // Continue the loop to get the next response from the LLM
                continue
            } else {
                // Final response
                guard var nutritionJSONText = message.content else {
                    throw NutritionError.badResponse
                }

                if let jsonStartIndex = nutritionJSONText.firstIndex(of: "{"),
                   let jsonEndIndex = nutritionJSONText.lastIndex(of: "}") {
                    nutritionJSONText = String(nutritionJSONText[jsonStartIndex...jsonEndIndex])
                }

                do {
                    let foodArrayResponse = try JSONDecoder().decode(FoodArrayResponse.self, from: Data(nutritionJSONText.utf8))
                    var foods = foodArrayResponse.foods

                    // Attach search steps to any item that is grounded
                    if !capturedSearchSteps.isEmpty {
                        for i in 0..<foods.count {
                            if foods[i].isSearchGrounded == true {
                                foods[i].searchSteps = capturedSearchSteps
                            }
                        }
                    }

                    // Enforce OFF data source if tool was used
                    if didUseOFF {
                        for i in 0..<foods.count {
                            if foods[i].isSearchGrounded == true {
                                // If already has "Google", append "OFF", else set to "OFF"
                                if let currentSource = foods[i].dataSource, !currentSource.contains("OFF") {
                                    foods[i].dataSource = "\(currentSource), OFF"
                                } else if foods[i].dataSource == nil {
                                    foods[i].dataSource = "OFF"
                                }
                            }
                        }
                    }

                    return foods
                } catch let decodingError {
                    throw NutritionError.unparsableJSON(decodingError.localizedDescription)
                }
            }
        }

        throw NutritionError.badResponse
    }

    func fetchAIGoals(userStats: String, userGoals: String, baselineTdee: Double) async throws -> GoalResponse {
        try validateProviderCredentials()

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"

        if UserSettings.llmProvider == .blockRun {
            let authKey = UserSettings.blockRunWalletId.isEmpty ? "x402" : UserSettings.blockRunWalletId
            request.addValue("Bearer \(authKey)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("https://portio.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Portio", forHTTPHeaderField: "X-Title")

        let prompt = """
        Act as a nutrition planning expert. Based on the following user data, determine their daily nutritional goals.
        User Data: \(userStats)
        User's Personal Goals: "\(userGoals)"
        The user's calculated baseline TDEE (Total Daily Energy Expenditure) for maintenance is \(String(format: "%.0f", baselineTdee)) calories. Use this as a starting point.

        CRITICAL: Your entire response must be ONLY a single, minified JSON object. Do not include any other text, explanations, or markdown formatting.
        The JSON object must have these exact keys and value types:
        - "calories": Double
        - "protein": Double
        - "carbs": Double
        - "fat": Double
        - "explanation": String

        In the "explanation" string, you MUST do the following:
        1.  Start by explaining how you adjusted the baseline TDEE to arrive at the new calorie goal, explicitly referencing the user's personal goal. (e.g., "To help you achieve your goal of losing weight, I've applied a 20% calorie deficit to your baseline TDEE of \(String(format: "%.0f", baselineTdee)) kcal, resulting in a target of...").
        2.  Briefly explain the macronutrient split (e.g., "This high-protein diet will support muscle growth...").
        3.  Provide a simple, sample one-day meal plan (e.g., Breakfast, Lunch, Dinner, Snacks) with specific food examples that would help the user meet these new targets.
        """

        let openRouterRequest = OpenRouterRequest(
            model: self.modelName,
            messages: [.init(role: "user", content: .string(prompt))],
            responseFormat: nil
        )

        NutritionDiagnostics.log("OpenRouter goals request model=\(self.modelName)")

        request.httpBody = try JSONEncoder().encode(openRouterRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        NutritionDiagnostics.log("OpenRouter goals response bytes=\(data.count)")

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse {
                NutritionDiagnostics.log("fetchAIGoals failed status=\(httpResponse.statusCode), bytes=\(data.count)")

                if let errorResponse = try? JSONDecoder().decode(OpenRouterErrorResponse.self, from: data) {
                    throw NutritionError.apiError(errorResponse.error.message)
                }

                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw NutritionError.invalidAPIKey
                }
            }
            throw NutritionError.badResponse
        }

        let openRouterResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard var goalJSONText = openRouterResponse.choices.first?.message.content else {
            throw NutritionError.badResponse
        }

        if let jsonStartIndex = goalJSONText.firstIndex(of: "{"),
           let jsonEndIndex = goalJSONText.lastIndex(of: "}") {
            goalJSONText = String(goalJSONText[jsonStartIndex...jsonEndIndex])
        }

        do {
            return try JSONDecoder().decode(GoalResponse.self, from: Data(goalJSONText.utf8))
        } catch let decodingError {
            throw NutritionError.unparsableJSON(decodingError.localizedDescription)
        }
    }

    private func validateProviderCredentials() throws {
        let trimmedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        switch provider {
        case .openRouter:
            guard !trimmedApiKey.isEmpty else {
                throw NutritionError.missingAPIKey("OpenRouter")
            }
        case .custom:
            guard !trimmedApiKey.isEmpty else {
                throw NutritionError.missingAPIKey("Custom provider")
            }
        case .blockRun:
            return
        }
    }
}

private enum NutritionDiagnostics {
    private static let isEnabled = false

    static func log(_ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        #if DEBUG
        print("[NutritionService] \(message())")
        #endif
    }
}

// MARK: - Codable Structs for Domain Models

// This is the new top-level response for food queries
struct FoodArrayResponse: Codable {
    let foods: [NutritionResponse]
}

struct NutritionResponse: Codable {
    let identifiedFood: String
    let cleanFoodName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let estimatedWeightGrams: Double
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let isSearchGrounded: Bool?
    var dataSource: String?
    var searchSteps: [SearchStep]?
}

struct GoalResponse: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let explanation: String
}
