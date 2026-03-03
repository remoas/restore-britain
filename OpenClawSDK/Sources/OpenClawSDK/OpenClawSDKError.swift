import Foundation

/// Errors that can occur when communicating with the OpenClaw Gateway.
public enum OpenClawSDKError: LocalizedError, Sendable {
    /// The Gateway rejected the bearer token (HTTP 401).
    case unauthorized

    /// The endpoint returned 404 — likely `/v1/chat/completions` is not enabled.
    /// The user needs to set `gateway.http.endpoints.chatCompletions.enabled: true`
    /// in their `~/.openclaw/openclaw.json`.
    case endpointNotEnabled

    /// Too many requests or too many auth failures (HTTP 429).
    case rateLimited

    /// The Gateway returned a non-success HTTP status code.
    case httpError(statusCode: Int)

    /// The response couldn't be parsed as an HTTP response.
    case invalidResponse

    /// The response contained no choices.
    case emptyResponse

    /// A network-level error occurred.
    case networkError(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Invalid gateway token. Check your token in ~/.openclaw/openclaw.json under gateway.auth.token."
        case .endpointNotEnabled:
            return "Chat completions endpoint is not enabled. Set gateway.http.endpoints.chatCompletions.enabled to true in your openclaw.json."
        case .rateLimited:
            return "Rate limited by the Gateway. Wait a moment and try again."
        case .httpError(let code):
            return "Gateway returned HTTP \(code)."
        case .invalidResponse:
            return "Received an invalid response from the Gateway."
        case .emptyResponse:
            return "The agent returned an empty response."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
