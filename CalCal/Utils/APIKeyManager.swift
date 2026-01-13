import Foundation

enum APIKeyManager {
    static func getAPIKey() -> String? {
        return get(key: "API_KEY")
    }
    
    static func getOpenRouterAPIKey() -> String? {
        return get(key: "OPENROUTER_API_KEY")
    }
    
    private static func get(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Gemini-Info", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil) as? [String: Any],
              let apiKey = plist[key] as? String,
              apiKey != "YOUR_API_KEY_HERE" else {
            return nil
        }
        return apiKey
    }
}
