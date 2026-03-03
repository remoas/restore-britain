import Foundation
import Combine

/// Manages the connection to the user's OpenClaw instance and the Larry skill.
@MainActor
final class OpenClawService: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isLarryInstalled = false

    private var config: OpenClawConfig?
    private let session: URLSession
    private let keychain: KeychainStore

    init(keychain: KeychainStore = .shared) {
        self.keychain = keychain
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Connection

    /// Connect to an OpenClaw instance with the given URL and API key.
    func connect(serverURL: URL, apiKey: String) async throws {
        connectionStatus = .connecting

        let config = OpenClawConfig(
            serverURL: serverURL,
            apiKey: apiKey,
            larrySkillId: OpenClawConfig.defaultLarrySkillId
        )

        // Validate connection by hitting the health endpoint
        var request = URLRequest(url: serverURL.appendingPathComponent("/api/health"))
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            connectionStatus = .error("Failed to connect. Check your server URL and API key.")
            throw OpenClawError.connectionFailed
        }

        self.config = config
        try keychain.saveOpenClawConfig(config)
        connectionStatus = .connected

        // Check if Larry is installed
        await checkLarrySkill()
    }

    /// Disconnect from the current OpenClaw instance.
    func disconnect() {
        config = nil
        keychain.deleteOpenClawConfig()
        connectionStatus = .disconnected
        isLarryInstalled = false
    }

    /// Attempt to restore a saved connection on app launch.
    func restoreConnection() async {
        guard let savedConfig = keychain.loadOpenClawConfig() else { return }
        do {
            try await connect(serverURL: savedConfig.serverURL, apiKey: savedConfig.apiKey)
        } catch {
            connectionStatus = .disconnected
        }
    }

    // MARK: - Larry Skill

    /// Check whether the Larry skill is installed on the connected OpenClaw instance.
    func checkLarrySkill() async {
        guard let config = config else { return }

        let url = config.serverURL.appendingPathComponent("/api/skills")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await session.data(for: request)
            let skills = try JSONDecoder().decode([SkillInfo].self, from: data)
            isLarryInstalled = skills.contains { $0.id == config.larrySkillId }
        } catch {
            isLarryInstalled = false
        }
    }

    /// Install the Larry skill on the connected OpenClaw instance.
    func installLarrySkill() async throws {
        guard let config = config else { throw OpenClawError.notConnected }

        let url = config.serverURL.appendingPathComponent("/api/skills/install")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["skill_id": config.larrySkillId]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenClawError.skillInstallFailed
        }

        isLarryInstalled = true
    }

    // MARK: - Campaign Execution

    /// Tell Larry to run a campaign (generate content, create slides, post).
    func runCampaign(_ campaign: Campaign) async throws -> [TikTokPost] {
        guard let config = config else { throw OpenClawError.notConnected }
        guard isLarryInstalled else { throw OpenClawError.larryNotInstalled }

        let url = config.serverURL.appendingPathComponent("/api/skills/\(config.larrySkillId)/run")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let payload = CampaignRunPayload(
            niche: campaign.niche,
            competitors: campaign.competitorAccounts,
            postsToGenerate: campaign.postsPerDay,
            imageStyle: campaign.imageStyle.rawValue,
            overlayConfig: campaign.overlayConfig,
            postizAccountId: campaign.postizAccountId
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([TikTokPost].self, from: data)
    }

    /// Fetch analytics for published posts from the OpenClaw instance.
    func fetchAnalytics(for campaignId: UUID) async throws -> [TikTokPost] {
        guard let config = config else { throw OpenClawError.notConnected }

        let url = config.serverURL.appendingPathComponent("/api/skills/\(config.larrySkillId)/analytics/\(campaignId.uuidString)")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([TikTokPost].self, from: data)
    }
}

// MARK: - Supporting Types

enum OpenClawError: LocalizedError {
    case connectionFailed
    case notConnected
    case larryNotInstalled
    case skillInstallFailed
    case campaignRunFailed

    var errorDescription: String? {
        switch self {
        case .connectionFailed: return "Failed to connect to your OpenClaw server."
        case .notConnected: return "Not connected to an OpenClaw server."
        case .larryNotInstalled: return "The Larry skill is not installed."
        case .skillInstallFailed: return "Failed to install the Larry skill."
        case .campaignRunFailed: return "Failed to run the campaign."
        }
    }
}

struct SkillInfo: Codable {
    let id: String
    let name: String
    let version: String
}

struct CampaignRunPayload: Codable {
    let niche: String
    let competitors: [String]
    let postsToGenerate: Int
    let imageStyle: String
    let overlayConfig: OverlayConfig
    let postizAccountId: String?
}
