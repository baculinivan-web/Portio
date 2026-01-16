import Foundation

enum OpenFoodFactsError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noResults
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL for OpenFoodFacts API."
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError(let error): return "Failed to decode OpenFoodFacts response: \(error.localizedDescription)"
        case .noResults: return "No products found."
        case .apiError(let msg): return "OpenFoodFacts API Error: \(msg)"
        }
    }
}

class OpenFoodFactsService {
    private let baseURL = "https://world.openfoodfacts.org"
    private let userAgent = "CalCal - iOS - Version 1.0 - https://calcal.app" // Identify our app

    func searchProducts(query: String) async throws -> [OFFProduct] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&fields=product_name,brands,nutriments,serving_size,quantity,code") else {
            throw OpenFoodFactsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenFoodFactsError.apiError("Server returned \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        do {
            let result = try JSONDecoder().decode(OFFSearchResult.self, from: data)
            return result.products
        } catch {
            throw OpenFoodFactsError.decodingError(error)
        }
    }
}

// MARK: - Models

struct OFFSearchResult: Codable {
    let count: Int
    let page: Int
    let products: [OFFProduct]
}

struct OFFProduct: Codable {
    let code: String
    let productName: String?
    let brands: String?
    let quantity: String? // e.g. "300 g"
    let servingSize: String? // e.g. "30 g"
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case quantity
        case servingSize = "serving_size"
        case nutriments
    }
}

struct OFFNutriments: Codable {
    // 100g values
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}
