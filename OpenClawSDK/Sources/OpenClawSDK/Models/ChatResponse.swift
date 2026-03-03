import Foundation

/// The parsed response from an OpenClaw agent (non-streaming).
public struct ChatResponse: Sendable {
    /// Unique response ID from the Gateway.
    public let id: String

    /// The agent's response text.
    public let content: String

    /// Role of the responder (always "assistant").
    public let role: String

    /// Why the response ended (e.g., "stop", "length").
    public let finishReason: String?

    /// Token usage stats, if provided by the Gateway.
    public let usage: TokenUsage?
}

/// A single chunk from a streaming response.
public struct StreamChunk: Sendable {
    /// Unique response ID from the Gateway.
    public let id: String

    /// Incremental text content (may be nil for role-only chunks).
    public let content: String?

    /// Role (only present in the first chunk, typically "assistant").
    public let role: String?

    /// Finish reason (only present in the final chunk).
    public let finishReason: String?
}
