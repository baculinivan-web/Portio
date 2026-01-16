import Foundation

// Custom, more descriptive errors
enum NutritionError: Error, LocalizedError {
    case invalidAPIKey
    case badRequest
    case badResponse
    case unparsableJSON(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid OpenRouter API Key. Please check your key in Gemini-Info.plist."
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
    private let apiURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let serperService = SerperService()
    private let offService = OpenFoodFactsService()

    init() {
        guard let apiKey = APIKeyManager.getOpenRouterAPIKey() else {
            fatalError("OpenRouter API Key not found. Please add it to Gemini-Info.plist")
        }
        self.apiKey = apiKey
        
        guard let modelName = APIKeyManager.getModelName() else {
             fatalError("Model Name not found. Please add MODEL_NAME to Gemini-Info.plist")
        }
        self.modelName = modelName
    }

    func fetchNutrition(for query: String, images: [Data] = []) async throws -> [NutritionResponse] {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add HTTP Referer (required by OpenRouter for some tiers, good practice)
        request.addValue("https://calcal.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("CalCal", forHTTPHeaderField: "X-Title")

        var systemPrompt = """
        You are a highly accurate nutritional analysis expert.
        Analyze the food query and images provided by the user to identify each distinct food item and return its nutritional information.
        
        If the user query mentions a specific restaurant, brand, or a complex food item that you are not 100% sure about, you MUST use available tools to find the most accurate and up-to-date nutritional information.
        
        TOOL PRIORITY RULE:
        1. `openfoodfacts_search`: Use this FIRST for any branded, packaged, or barcoded product query (e.g., "Nutella", "Chobani", "Oreo"). The data is structured and highly reliable.
           CRITICAL: When using `openfoodfacts_search`, pass ONLY the brand and product name (e.g., "Coke Zero", "Snickers", "Сырок Ростагроэкспорт"). DO NOT include weights, volumes, or packaging details (e.g., "0.33l", "50g", "box") in the search query, as this often causes the search to fail. The tool will return available sizes/quantities for you to select from.
        2. `google_search`: Use this if `openfoodfacts_search` returns no results, or for restaurant menu items ("Big Mac"), generic dishes ("Caesar Salad"), or specific queries requiring web synthesis.
        
        CRITICAL PORTION ESTIMATION RULE: For branded or packaged items, if the user does not specify a weight, you MUST use the serving size or unit weight returned by the tools. NEVER default to 100g if the standard unit weight is different.
        
        CRITICAL SEARCH LANGUAGE RULE: Always perform searches in the SAME language as the user's input query to ensure the most relevant local results.
        
        CRITICAL: If you used a tool to find information for a food item, you MUST set the "isSearchGrounded" key to true for that item in your JSON response.
        
        CRITICAL: Your final response MUST be ONLY a single, minified JSON object with the "foods" array.
        """
        
        var userPrompt = "Analyze the food query: '\(query)'."
        
        if !images.isEmpty {
            userPrompt += " The user has also provided images of the food. Use them to identify the food and estimate portions."
        }
        
        userPrompt += """
        
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
        
        var contentParts: [OpenRouterRequest.ContentPart] = [.text(userPrompt)]
        
        for imageData in images {
            let base64 = imageData.base64EncodedString()
            let url = "data:image/jpeg;base64,\(base64)"
            contentParts.append(.imageUrl(url))
        }
        
        var messages: [OpenRouterRequest.Message] = [
            .init(role: "system", content: [.text(systemPrompt)]),
            .init(role: "user", content: contentParts)
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

        // Loop for tool calling
        for _ in 0...3 { // Limit to 3 iterations to avoid infinite loops
            #if DEBUG
            print("\n--- OPENROUTER REQUEST ---")
            print("Model: \(self.modelName)")
            for (index, msg) in messages.enumerated() {
                print("Message [\(index)] (\(msg.role)):")
                if let content = msg.content {
                    for part in content {
                        switch part {
                        case .text(let text):
                            print("  Text: \(text)")
                        case .imageUrl(let url):
                            if url.hasPrefix("data:image") {
                                print("  Image: [Base64 Data Truncated]")
                            } else {
                                print("  Image URL: \(url)")
                            }
                        }
                    }
                }
                if let toolCalls = msg.toolCalls {
                    for tc in toolCalls {
                        print("  Tool Call: \(tc.function.name)(\(tc.function.arguments))")
                    }
                }
                if let tcId = msg.toolCallId {
                    print("  Tool Call ID: \(tcId)")
                }
            }
            #endif

            let openRouterRequest = OpenRouterRequest(
                model: self.modelName,
                messages: messages,
                responseFormat: nil,
                tools: tools,
                toolChoice: .auto
            )
            
            request.httpBody = try JSONEncoder().encode(openRouterRequest)

            let (data, response) = try await URLSession.shared.data(for: request)
            
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("\n--- OPENROUTER RESPONSE ---")
                print(responseString)
                print("---------------------------\n")
            }
            #endif
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if let httpResponse = response as? HTTPURLResponse {
                     print("--- NETWORKING ERROR (fetchNutrition) ---")
                     print("Status Code: \(httpResponse.statusCode)")
                     print("Response Body: \(String(data: data, encoding: .utf8) ?? "Unable to print body")")
                     
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
            
            let message = choice.message
            
            // Add the assistant's message to the history
            messages.append(.init(
                role: "assistant",
                content: message.content != nil ? [.text(message.content!)] : nil,
                toolCalls: message.toolCalls
            ))

            if choice.finishReason == "tool_calls", let toolCalls = message.toolCalls {
                for toolCall in toolCalls {
                    if toolCall.function.name == "google_search" {
                        guard let argsData = toolCall.function.arguments.data(using: .utf8),
                              let args = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any],
                              let searchQuery = args["query"] as? String else {
                            continue
                        }
                        
                        let searchStep = try await serperService.searchStructured(query: searchQuery)
                        capturedSearchSteps.append(searchStep)
                        
                        // Convert back to string for the AI
                        var resultString = ""
                        if let answer = searchStep.answerBox {
                            resultString += "Answer: \(answer)\n"
                        }
                        resultString += "Top results (4):\n"
                        for (i, res) in searchStep.results.enumerated() {
                            resultString += "\(i+1). \(res.title): \(res.snippet)\n"
                        }
                        
                        messages.append(.init(
                            role: "tool",
                            content: [.text(resultString)],
                            toolCallId: toolCall.id,
                            name: "google_search"
                        ))
                    } else if toolCall.function.name == "openfoodfacts_search" {
                        guard let argsData = toolCall.function.arguments.data(using: .utf8),
                              let args = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any],
                              let searchQuery = args["query"] as? String else {
                            continue
                        }
                        
                        var resultString = ""
                        do {
                            let products = try await offService.searchProducts(query: searchQuery)
                            
                            if products.isEmpty {
                                resultString = "No products found in OpenFoodFacts database."
                            } else {
                                resultString = "Found \(products.count) products. Top 3 relevant results:\n"
                                for (i, product) in products.prefix(3).enumerated() {
                                    resultString += "\(i+1). Name: \(product.productName ?? "Unknown") | Brand: \(product.brands ?? "Unknown") | Serving: \(product.servingSize ?? "Unknown")\n"
                                    if let nuts = product.nutriments {
                                        resultString += "   Per 100g: \(nuts.energyKcal100g ?? 0) kcal, P: \(nuts.proteins100g ?? 0)g, C: \(nuts.carbohydrates100g ?? 0)g, F: \(nuts.fat100g ?? 0)g\n"
                                    }
                                }
                            }
                        } catch {
                            resultString = "Error searching OpenFoodFacts: \(error.localizedDescription)"
                        }
                        
                        messages.append(.init(
                            role: "tool",
                            content: [.text(resultString)],
                            toolCallId: toolCall.id,
                            name: "openfoodfacts_search"
                        ))
                    }
                }
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
                    
                    return foods
                } catch let decodingError {
                    throw NutritionError.unparsableJSON(decodingError.localizedDescription)
                }
            }
        }
        
        throw NutritionError.badResponse
    }
    
    func fetchAIGoals(userStats: String, userGoals: String, baselineTDEE: Double) async throws -> GoalResponse {
         var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("https://calcal.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("CalCal", forHTTPHeaderField: "X-Title")

        let prompt = """
        Act as a nutrition planning expert. Based on the following user data, determine their daily nutritional goals.
        User Data: \(userStats)
        User's Personal Goals: "\(userGoals)"
        The user's calculated baseline TDEE (Total Daily Energy Expenditure) for maintenance is \(String(format: "%.0f", baselineTDEE)) calories. Use this as a starting point.

        CRITICAL: Your entire response must be ONLY a single, minified JSON object. Do not include any other text, explanations, or markdown formatting.
        The JSON object must have these exact keys and value types:
        - "calories": Double
        - "protein": Double
        - "carbs": Double
        - "fat": Double
        - "explanation": String
        
        In the "explanation" string, you MUST do the following:
        1.  Start by explaining how you adjusted the baseline TDEE to arrive at the new calorie goal, explicitly referencing the user's personal goal. (e.g., "To help you achieve your goal of losing weight, I've applied a 20% calorie deficit to your baseline TDEE of \(String(format: "%.0f", baselineTDEE)) kcal, resulting in a target of...").
        2.  Briefly explain the macronutrient split (e.g., "This high-protein diet will support muscle growth...").
        3.  Provide a simple, sample one-day meal plan (e.g., Breakfast, Lunch, Dinner, Snacks) with specific food examples that would help the user meet these new targets.
        """

        let openRouterRequest = OpenRouterRequest(
            model: self.modelName,
            messages: [.init(role: "user", content: [.text(prompt)])],
            responseFormat: nil 
        )
        
        #if DEBUG
        print("\n--- OPENROUTER REQUEST (fetchAIGoals) ---")
        print("Model: \(self.modelName)")
        print("Prompt: \(prompt)")
        #endif

        request.httpBody = try JSONEncoder().encode(openRouterRequest)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        #if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            print("\n--- OPENROUTER RESPONSE (fetchAIGoals) ---")
            print(responseString)
            print("---------------------------\n")
        }
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse {
                print("--- NETWORKING ERROR (AIGoals) ---")
                print("Status Code: \(httpResponse.statusCode)")
                print("Response Body: \(String(data: data, encoding: .utf8) ?? "Unable to print body")")
                
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
    let dataSource: String?
    var searchSteps: [SearchStep]?
}

struct GoalResponse: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let explanation: String
}
