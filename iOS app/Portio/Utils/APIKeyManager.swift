import Foundation

enum APIKeyManager {
    static func getAPIKey() -> String? {
        return get(key: "API_KEY")
    }
    
    static func getOpenRouterAPIKey() -> String? {
        return get(key: "OPENROUTER_API_KEY")
    }
    
    static func getSerperAPIKey() -> String? {
        return get(key: "SERPER_API_KEY", placeholder: "YOUR_SERPER_API_KEY_HERE")
    }
    
    static func getModelName() -> String? {
        // Default to nil if not set or placeholder
        return get(key: "MODEL_NAME", placeholder: "YOUR_MODEL_NAME_HERE")
    }
    
    private static func get(key: String, placeholder: String = "YOUR_API_KEY_HERE") -> String? {
        guard let path = Bundle.main.path(forResource: "Gemini-Info", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil) as? [String: Any],
              let value = plist[key] as? String,
              value != placeholder else {
            return nil
        }
        return value
    }
}
