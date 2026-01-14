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
        
        If the user query mentions a specific restaurant, brand, or a complex food item that you are not 100% sure about, you MUST use the `google_search` tool to find the most accurate and up-to-date nutritional information.
        
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
        - "calories": Double
        - "protein": Double
        - "carbs": Double
        - "fat": Double
        - "estimatedWeightGrams": Double
        - "caloriesPer100g": Double
        - "proteinPer100g": Double
        - "carbsPer100g": Double
        - "fatPer100g": Double
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
                    description: "Search Google for nutritional information of specific food items, brands, or restaurant menu items.",
                    parameters: [
                        "type": .string("object"),
                        "properties": .object([
                            "query": .object([
                                "type": .string("string"),
                                "description": .string("The search query, e.g., 'McDonalds Big Mac nutrition facts' or 'Chobani Greek Yogurt calories'.")
                            ])
                        ]),
                        "required": .array([.string("query")])
                    ]
                )
            )
        ]

        // Loop for tool calling
        for _ in 0...3 { // Limit to 3 iterations to avoid infinite loops
            let openRouterRequest = OpenRouterRequest(
                model: self.modelName,
                messages: messages,
                responseFormat: nil,
                tools: tools,
                toolChoice: .auto
            )
            
            request.httpBody = try JSONEncoder().encode(openRouterRequest)

            let (data, response) = try await URLSession.shared.data(for: request)
            
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
                        
                        let searchResult = try await serperService.search(query: searchQuery)
                        
                        messages.append(.init(
                            role: "tool",
                            content: [.text(searchResult)],
                            toolCallId: toolCall.id,
                            name: "google_search"
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
                    return foodArrayResponse.foods
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
        
        request.httpBody = try JSONEncoder().encode(openRouterRequest)

        let (data, response) = try await URLSession.shared.data(for: request)
        
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
}

struct GoalResponse: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let explanation: String
}
