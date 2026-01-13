import Foundation

enum APIKeyManager {
    static func getAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "Gemini-Info", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil) as? [String: Any],
              let apiKey = plist["API_KEY"] as? String,
              apiKey != "YOUR_API_KEY_HERE" else {
            return nil
        }
        return apiKey
    }
}
