import Foundation

/// A single message in a chat conversation.
public struct ChatMessage: Codable, Sendable {
    public let role: Role
    public let content: String

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

/// Message roles in the OpenAI-compatible API.
public enum Role: String, Codable, Sendable {
    case system
    case user
    case assistant
}
