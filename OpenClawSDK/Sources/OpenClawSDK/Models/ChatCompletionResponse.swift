import Foundation

/// Response from the `/v1/chat/completions` endpoint (non-streaming).
struct ChatCompletionResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: TokenUsage?

    struct Choice: Decodable {
        let index: Int
        let message: ChoiceMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }

    struct ChoiceMessage: Decodable {
        let role: String
        let content: String
    }
}

/// Response from the `/v1/chat/completions` endpoint (streaming SSE chunks).
struct StreamChunkResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [StreamChoice]

    struct StreamChoice: Decodable {
        let index: Int
        let delta: Delta?
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, delta
            case finishReason = "finish_reason"
        }
    }

    struct Delta: Decodable {
        let role: String?
        let content: String?
    }
}

/// Token usage statistics returned by the Gateway.
public struct TokenUsage: Codable, Sendable {
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

/// Models list response from `/v1/models`.
struct ModelsResponse: Decodable {
    let data: [ModelInfo]
}

/// Information about a model/agent available on the Gateway.
public struct ModelInfo: Codable, Sendable, Identifiable {
    public let id: String
    public let object: String
    public let created: Int?
    public let ownedBy: String?

    enum CodingKeys: String, CodingKey {
        case id, object, created
        case ownedBy = "owned_by"
    }
}
