import Foundation

// MARK: - Generic JSON Support
enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) { self = .string(x); return }
        if let x = try? container.decode(Double.self) { self = .number(x); return }
        if let x = try? container.decode(Bool.self) { self = .bool(x); return }
        if let x = try? container.decode([String: JSONValue].self) { self = .object(x); return }
        if let x = try? container.decode([JSONValue].self) { self = .array(x); return }
        if container.decodeNil() { self = .null; return }
        throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONValue"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x): try container.encode(x)
        case .number(let x): try container.encode(x)
        case .bool(let x): try container.encode(x)
        case .object(let x): try container.encode(x)
        case .array(let x): try container.encode(x)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - OpenRouter API Models

struct OpenRouterRequest: Encodable {
    let model: String
    let messages: [Message]
    let responseFormat: ResponseFormat?
    let tools: [Tool]?
    let toolChoice: ToolChoice?
    let reasoning: Reasoning?
    
    init(model: String, messages: [Message], responseFormat: ResponseFormat? = nil, tools: [Tool]? = nil, toolChoice: ToolChoice? = nil, reasoning: Reasoning? = nil) {
        self.model = model
        self.messages = messages
        self.responseFormat = responseFormat
        self.tools = tools
        self.toolChoice = toolChoice
        self.reasoning = reasoning
    }
    
    enum CodingKeys: String, CodingKey {
        case model, messages, tools, reasoning
        case responseFormat = "response_format"
        case toolChoice = "tool_choice"
    }
    
    struct Reasoning: Encodable {
        let effort: String // "high", "medium", "low" (default high for some models)
    }
    
    struct Message: Encodable {
        let role: String
        let content: MessageContent?
        let toolCalls: [ToolCall]?
        let toolCallId: String?
        let name: String?

        enum CodingKeys: String, CodingKey {
            case role, content, name
            case toolCalls = "tool_calls"
            case toolCallId = "tool_call_id"
        }
        
        init(role: String, content: MessageContent? = nil, toolCalls: [ToolCall]? = nil, toolCallId: String? = nil, name: String? = nil) {
            self.role = role
            self.content = content
            self.toolCalls = toolCalls
            self.toolCallId = toolCallId
            self.name = name
        }
        
        // Convenience init for array of parts
        init(role: String, content: [ContentPart], toolCalls: [ToolCall]? = nil, toolCallId: String? = nil, name: String? = nil) {
            self.init(role: role, content: .parts(content), toolCalls: toolCalls, toolCallId: toolCallId, name: name)
        }
        
        // Convenience init for simple string
        init(role: String, content: String, toolCalls: [ToolCall]? = nil, toolCallId: String? = nil, name: String? = nil) {
            self.init(role: role, content: .string(content), toolCalls: toolCalls, toolCallId: toolCallId, name: name)
        }
    }
    
    enum MessageContent: Encodable {
        case string(String)
        case parts([ContentPart])
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let s): try container.encode(s)
            case .parts(let p): try container.encode(p)
            }
        }
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
    
    struct Tool: Encodable {
        let type: String
        let function: FunctionDefinition
    }

    struct FunctionDefinition: Encodable {
        let name: String
        let description: String
        let parameters: [String: JSONValue]
    }
    
    enum ToolChoice: Encodable {
        case auto
        case none
        case specific(String)
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .auto: try container.encode("auto")
            case .none: try container.encode("none")
            case .specific(let name):
                var keyedContainer = encoder.container(keyedBy: ToolChoiceKeys.self)
                try keyedContainer.encode("function", forKey: .type)
                try keyedContainer.encode(["name": name], forKey: .function)
            }
        }
        
        enum ToolChoiceKeys: String, CodingKey {
            case type, function
        }
    }
}

struct ToolCall: Codable {
    let id: String
    let type: String
    let function: FunctionCall
}

struct FunctionCall: Codable {
    let name: String
    let arguments: String
}

struct OpenRouterResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Decodable {
        let content: String?
        let toolCalls: [ToolCall]?
        
        enum CodingKeys: String, CodingKey {
            case content
            case toolCalls = "tool_calls"
        }
    }
}

struct OpenRouterErrorResponse: Decodable {
    let error: OpenRouterError
    
    struct OpenRouterError: Decodable {
        let message: String
        let code: Int?
    }
}
