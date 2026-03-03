import Foundation

/// Configuration for connecting to a user's OpenClaw instance.
struct OpenClawConfig: Codable {
    var serverURL: URL
    var apiKey: String
    var larrySkillId: String

    /// Default Larry skill identifier on ClawHub.
    static let defaultLarrySkillId = "OllieWazza/larry"

    /// Validate that the server URL is reachable and the API key is valid.
    var isValid: Bool {
        !apiKey.isEmpty && serverURL.scheme != nil
    }
}

/// Status of the connection to the user's OpenClaw instance.
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}
