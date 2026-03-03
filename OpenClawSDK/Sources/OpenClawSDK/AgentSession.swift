import Foundation

/// Manages a persistent conversation session with an OpenClaw agent.
///
/// Tracks message history and uses a stable session ID so the agent
/// retains context across multiple requests.
///
/// Usage:
/// ```swift
/// let client = OpenClawClient(gatewayURL: url, token: token)
/// let session = AgentSession(client: client, agentId: "larry-agent")
///
/// let response1 = try await session.send("Set up a fitness campaign targeting 18-25 year olds")
/// let response2 = try await session.send("Now research my top 3 competitors")
/// // response2 has full context from response1
/// ```
public final class AgentSession: @unchecked Sendable {
    private let client: OpenClawClient
    public let agentId: String
    public let sessionId: String

    /// Full conversation history.
    private var messages: [ChatMessage] = []
    private let lock = NSLock()

    public init(
        client: OpenClawClient,
        agentId: String,
        sessionId: String = UUID().uuidString,
        systemPrompt: String? = nil
    ) {
        self.client = client
        self.agentId = agentId
        self.sessionId = sessionId

        if let systemPrompt {
            messages.append(ChatMessage(role: .system, content: systemPrompt))
        }
    }

    /// Send a message and get the full response. Appends both the user message
    /// and agent response to the conversation history.
    public func send(_ message: String) async throws -> ChatResponse {
        lock.lock()
        let currentHistory = messages
        lock.unlock()

        let response = try await client.send(
            message,
            agentId: agentId,
            sessionId: sessionId,
            history: currentHistory
        )

        lock.lock()
        messages.append(ChatMessage(role: .user, content: message))
        messages.append(ChatMessage(role: .assistant, content: response.content))
        lock.unlock()

        return response
    }

    /// Send a message and stream the response. The full response is appended
    /// to history after the stream completes.
    public func stream(_ message: String) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        lock.lock()
        let currentHistory = messages
        lock.unlock()

        let rawStream = try await client.stream(
            message,
            agentId: agentId,
            sessionId: sessionId,
            history: currentHistory
        )

        // Wrap the stream to accumulate the full response for history
        return AsyncThrowingStream { continuation in
            Task { [weak self] in
                var accumulated = ""
                do {
                    for try await chunk in rawStream {
                        if let content = chunk.content {
                            accumulated += content
                        }
                        continuation.yield(chunk)
                    }

                    // Append to history after stream completes
                    if let self {
                        self.lock.lock()
                        self.messages.append(ChatMessage(role: .user, content: message))
                        self.messages.append(ChatMessage(role: .assistant, content: accumulated))
                        self.lock.unlock()
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// The current conversation history.
    public var history: [ChatMessage] {
        lock.lock()
        defer { lock.unlock() }
        return messages
    }

    /// Clear the conversation history, optionally keeping the system prompt.
    public func reset(keepSystemPrompt: Bool = true) {
        lock.lock()
        if keepSystemPrompt, let first = messages.first, first.role == .system {
            messages = [first]
        } else {
            messages = []
        }
        lock.unlock()
    }
}
