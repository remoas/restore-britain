import Foundation

/// Request body for the `/v1/chat/completions` endpoint.
///
/// Matches the OpenAI-compatible format used by the OpenClaw Gateway.
/// The `model` field selects the agent: use `"openclaw:<agentId>"`.
/// The `user` field provides a stable session key for conversation persistence.
struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let stream: Bool
    let user: String?

    enum CodingKeys: String, CodingKey {
        case model, messages, stream, user
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)
        try container.encodeIfPresent(user, forKey: .user)
    }
}
