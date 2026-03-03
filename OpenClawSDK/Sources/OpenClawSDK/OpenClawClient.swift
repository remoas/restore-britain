import Foundation

/// Swift client for the OpenClaw Gateway HTTP API.
///
/// Connects to a self-hosted OpenClaw instance and interacts with agents
/// via the OpenAI-compatible `/v1/chat/completions` endpoint.
///
/// Usage:
/// ```swift
/// let client = OpenClawClient(
///     gatewayURL: URL(string: "http://localhost:18789")!,
///     token: "your-gateway-token"
/// )
///
/// let response = try await client.send("Research fitness competitors on TikTok", agentId: "larry-agent")
/// print(response.content)
/// ```
public final class OpenClawClient: Sendable {
    /// The base URL of the OpenClaw Gateway (e.g., `http://localhost:18789`).
    public let gatewayURL: URL

    /// Bearer token for Gateway authentication.
    private let token: String

    /// URLSession for HTTP requests.
    private let session: URLSession

    /// Default timeout for non-streaming requests (seconds).
    public static let defaultTimeout: TimeInterval = 120

    public init(
        gatewayURL: URL,
        token: String,
        session: URLSession? = nil
    ) {
        self.gatewayURL = gatewayURL
        self.token = token

        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = Self.defaultTimeout
            self.session = URLSession(configuration: config)
        }
    }

    // MARK: - Health Check

    /// Verify the Gateway is reachable and the token is valid.
    /// Returns `true` if the Gateway responds successfully.
    public func healthCheck() async throws -> Bool {
        // Hit the root endpoint — a valid token should not get a 401
        var request = makeRequest(path: "/v1/models", method: "GET")
        request.timeoutInterval = 10

        let (_, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw OpenClawSDKError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return true
        case 401:
            throw OpenClawSDKError.unauthorized
        case 429:
            throw OpenClawSDKError.rateLimited
        default:
            throw OpenClawSDKError.httpError(statusCode: http.statusCode)
        }
    }

    // MARK: - Chat Completions (Non-Streaming)

    /// Send a message to an OpenClaw agent and get the full response.
    ///
    /// - Parameters:
    ///   - message: The user message to send.
    ///   - agentId: The OpenClaw agent ID (used as `openclaw:<agentId>` in the model field).
    ///   - sessionId: Optional stable session ID for conversation persistence.
    ///                 Maps to the `user` field in the request.
    ///   - history: Optional prior messages for context.
    /// - Returns: The agent's response.
    public func send(
        _ message: String,
        agentId: String,
        sessionId: String? = nil,
        history: [ChatMessage] = []
    ) async throws -> ChatResponse {
        var messages = history
        messages.append(ChatMessage(role: .user, content: message))

        let body = ChatCompletionRequest(
            model: "openclaw:\(agentId)",
            messages: messages,
            stream: false,
            user: sessionId
        )

        let request = try makeJSONRequest(path: "/v1/chat/completions", body: body)
        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let choice = decoded.choices.first else {
            throw OpenClawSDKError.emptyResponse
        }

        return ChatResponse(
            id: decoded.id,
            content: choice.message.content,
            role: choice.message.role,
            finishReason: choice.finishReason,
            usage: decoded.usage
        )
    }

    // MARK: - Chat Completions (Streaming)

    /// Send a message to an OpenClaw agent and stream the response as it generates.
    ///
    /// Returns an `AsyncThrowingStream` of `StreamChunk` values.
    public func stream(
        _ message: String,
        agentId: String,
        sessionId: String? = nil,
        history: [ChatMessage] = []
    ) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        var messages = history
        messages.append(ChatMessage(role: .user, content: message))

        let body = ChatCompletionRequest(
            model: "openclaw:\(agentId)",
            messages: messages,
            stream: true,
            user: sessionId
        )

        let request = try makeJSONRequest(path: "/v1/chat/completions", body: body)
        let (bytes, response) = try await session.bytes(for: request)

        try validateResponse(response)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        // SSE format: "data: {...}" or "data: [DONE]"
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))

                        if payload == "[DONE]" {
                            continuation.finish()
                            return
                        }

                        guard let jsonData = payload.data(using: .utf8) else { continue }

                        let chunk = try JSONDecoder().decode(StreamChunkResponse.self, from: jsonData)

                        if let delta = chunk.choices.first?.delta {
                            continuation.yield(StreamChunk(
                                id: chunk.id,
                                content: delta.content,
                                role: delta.role,
                                finishReason: chunk.choices.first?.finishReason
                            ))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - List Models/Agents

    /// List available models and agents on the Gateway.
    public func listModels() async throws -> [ModelInfo] {
        let request = makeRequest(path: "/v1/models", method: "GET")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
        return decoded.data
    }

    // MARK: - Internal Helpers

    private func makeRequest(path: String, method: String) -> URLRequest {
        let url = gatewayURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func makeJSONRequest<T: Encodable>(path: String, body: T) throws -> URLRequest {
        var request = makeRequest(path: path, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw OpenClawSDKError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw OpenClawSDKError.unauthorized
        case 404:
            throw OpenClawSDKError.endpointNotEnabled
        case 429:
            throw OpenClawSDKError.rateLimited
        default:
            throw OpenClawSDKError.httpError(statusCode: http.statusCode)
        }
    }
}
