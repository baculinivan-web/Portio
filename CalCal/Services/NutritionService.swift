import Foundation

// Custom, more descriptive errors
enum NutritionError: Error, LocalizedError {
    case invalidAPIKey
    case badRequest
    case badResponse
    case unparsableJSON(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API Key. Please check your key in Gemini-Info.plist and ensure it is enabled in your Google AI Studio project."
        case .badRequest:
            return "The request to the server was malformed."
        case .badResponse:
            return "The server returned an invalid response."
        case .unparsableJSON(let details):
            return "Could not parse the nutrition data from the AI. Details: \(details)"
        }
    }
}

// MARK: - Networking Service
class NutritionService {
    private let apiKey: String
    private let apiURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")!

    init() {
        guard let apiKey = APIKeyManager.getAPIKey() else {
            fatalError("API Key not found. Please add it to Gemini-Info.plist")
        }
        self.apiKey = apiKey
    }

    func fetchNutrition(for query: String) async throws -> [NutritionResponse] {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = """
        Analyze the food query: '\(query)'. Your task is to identify each distinct food item and return its nutritional information.
        CRITICAL: Your entire response must be ONLY a single, minified JSON object. Do not include backticks, the word 'json', or any other text before or after the JSON object.
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
        
        let requestBody = GeminiRequest(contents: [.init(parts: [.init(text: prompt)])])
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 400 || httpResponse.statusCode == 403) {
                throw NutritionError.invalidAPIKey
            }
            throw NutritionError.badResponse
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard var nutritionJSONText = geminiResponse.candidates.first?.content.parts.first?.text else {
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
    
    func fetchAIGoals(userStats: String, userGoals: String, baselineTDEE: Double) async throws -> GoalResponse {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

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

        let requestBody = GeminiRequest(contents: [.init(parts: [.init(text: prompt)])])
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse {
                print("--- NETWORKING ERROR (AIGoals) ---")
                print("Status Code: \(httpResponse.statusCode)")
                print("Response Body: \(String(data: data, encoding: .utf8) ?? "Unable to print body")")
                print("-------------------------------------")
                if httpResponse.statusCode == 400 || httpResponse.statusCode == 403 {
                    throw NutritionError.invalidAPIKey
                }
            }
            throw NutritionError.badResponse
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard var goalJSONText = geminiResponse.candidates.first?.content.parts.first?.text else {
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

// MARK: - Codable Structs for API

struct GeminiRequest: Codable {
    let contents: [Content]
}
struct Content: Codable {
    let parts: [Part]
}
struct Part: Codable {
    let text: String
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
}
struct Candidate: Codable {
    let content: Content
}

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