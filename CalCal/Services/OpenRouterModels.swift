import Foundation

struct OpenRouterConstants {
    static let defaultModel = "nvidia/nemotron-3-nano-30b-a3b:free"
}

struct OpenRouterRequest: Encodable {
    let model: String
    let messages: [Message]
    let responseFormat: ResponseFormat?
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case responseFormat = "response_format"
    }
    
    struct Message: Encodable {
        let role: String
        let content: [ContentPart]
    }
    
    enum ContentPart: Encodable {
        case text(String)
        case imageUrl(String)
        
        enum CodingKeys: String, CodingKey {
            case type, text, image_url
        }
        
        struct ImageUrl: Encodable {
            let url: String
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .text)
            case .imageUrl(let url):
                try container.encode("image_url", forKey: .type)
                try container.encode(ImageUrl(url: url), forKey: .image_url)
            }
        }
    }
    
    struct ResponseFormat: Encodable {
        let type: String
    }
}

struct OpenRouterResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String?
    }
}
