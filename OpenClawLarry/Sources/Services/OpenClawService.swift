import Foundation
import OpenClawSDK

/// Manages the connection to the user's OpenClaw Gateway and runs the Larry skill
/// by sending natural language messages to an agent that has Larry installed.
///
/// How it works:
/// 1. User provides their Gateway URL + bearer token (from ~/.openclaw/openclaw.json)
/// 2. We connect via the OpenAI-compatible /v1/chat/completions endpoint
/// 3. We select the agent that has the Larry skill via the `model` field
/// 4. Campaign instructions are sent as chat messages — Larry handles the rest
@MainActor
final class OpenClawService: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isLarryInstalled = false
    @Published var availableAgents: [ModelInfo] = []
    @Published var selectedAgentId: String?

    /// Streaming response text for the current operation.
    @Published var streamingText: String = ""

    private var client: OpenClawClient?
    private var larrySession: AgentSession?
    private let keychain: KeychainStore

    init(keychain: KeychainStore = .shared) {
        self.keychain = keychain
    }

    // MARK: - Connection

    /// Connect to an OpenClaw Gateway with a URL and bearer token.
    ///
    /// The token is the `gateway.auth.token` from the user's `~/.openclaw/openclaw.json`.
    /// The Gateway must have `gateway.http.endpoints.chatCompletions.enabled: true`.
    func connect(serverURL: URL, apiKey: String) async throws {
        connectionStatus = .connecting

        let newClient = OpenClawClient(gatewayURL: serverURL, token: apiKey)

        // Verify connection by hitting /v1/models
        do {
            let isHealthy = try await newClient.healthCheck()
            guard isHealthy else {
                connectionStatus = .error("Gateway did not respond.")
                throw OpenClawError.connectionFailed
            }
        } catch let error as OpenClawSDKError {
            switch error {
            case .endpointNotEnabled:
                connectionStatus = .error("Chat completions endpoint is disabled. Enable it in your openclaw.json.")
            case .unauthorized:
                connectionStatus = .error("Invalid gateway token.")
            default:
                connectionStatus = .error(error.localizedDescription)
            }
            throw OpenClawError.connectionFailed
        }

        self.client = newClient

        // Save credentials
        let config = OpenClawConfig(
            serverURL: serverURL,
            apiKey: apiKey,
            larrySkillId: OpenClawConfig.defaultLarrySkillId
        )
        try keychain.saveOpenClawConfig(config)

        // List available agents to find one with Larry
        await loadAgents()

        connectionStatus = .connected
    }

    /// Disconnect and clear credentials.
    func disconnect() {
        client = nil
        larrySession = nil
        keychain.deleteOpenClawConfig()
        connectionStatus = .disconnected
        isLarryInstalled = false
        availableAgents = []
        selectedAgentId = nil
    }

    /// Restore a saved connection on app launch.
    func restoreConnection() async {
        guard let savedConfig = keychain.loadOpenClawConfig() else { return }
        do {
            try await connect(serverURL: savedConfig.serverURL, apiKey: savedConfig.apiKey)
        } catch {
            connectionStatus = .disconnected
        }
    }

    // MARK: - Agent Discovery

    /// List models/agents on the Gateway and check for a Larry-configured agent.
    func loadAgents() async {
        guard let client else { return }

        do {
            let models = try await client.listModels()
            availableAgents = models

            // Look for an agent with "larry" in the ID or name
            if let larryAgent = models.first(where: {
                $0.id.localizedCaseInsensitiveContains("larry")
            }) {
                selectedAgentId = larryAgent.id
                isLarryInstalled = true
            } else if let firstAgent = models.first(where: {
                $0.id.hasPrefix("openclaw:") || $0.id.hasPrefix("agent:")
            }) {
                // Fall back to the first OpenClaw agent — user may have Larry
                // installed under a custom agent name
                selectedAgentId = firstAgent.id
                isLarryInstalled = true
            }
        } catch {
            availableAgents = []
        }
    }

    /// Select a specific agent ID to use for Larry operations.
    func selectAgent(_ agentId: String) {
        selectedAgentId = agentId
        larrySession = nil // Reset session for new agent
        isLarryInstalled = true
    }

    // MARK: - Larry Session

    /// Get or create a persistent session with the Larry agent.
    private func getLarrySession() throws -> AgentSession {
        guard let client else { throw OpenClawError.notConnected }
        guard let agentId = selectedAgentId else { throw OpenClawError.larryNotInstalled }

        if let existing = larrySession {
            return existing
        }

        let session = AgentSession(
            client: client,
            agentId: agentId,
            systemPrompt: """
            You are running the Larry skill for TikTok slideshow marketing automation. \
            Execute campaign instructions precisely. When generating content, return structured \
            results including captions, hashtags, and image descriptions. When posting, confirm \
            the post status and any analytics available.
            """
        )
        larrySession = session
        return session
    }

    // MARK: - Campaign Execution

    /// Tell Larry to run a campaign by sending a natural language instruction.
    ///
    /// Larry is an OpenClaw skill — it runs on the server. We instruct it via chat.
    /// The agent researches competitors, generates images, adds overlays, and posts.
    func runCampaign(_ campaign: Campaign) async throws -> String {
        let session = try getLarrySession()

        let instruction = """
        Run a TikTok slideshow campaign with these settings:
        - Niche: \(campaign.niche)
        - Target audience: \(campaign.targetAudience)
        - Competitor accounts to research: \(campaign.competitorAccounts.joined(separator: ", "))
        - Number of posts to generate: \(campaign.postsPerDay)
        - Image style: \(campaign.imageStyle.rawValue)
        - Text overlay position: \(campaign.overlayConfig.position.rawValue)
        \(campaign.postizAccountId.map { "- Post via Postiz account: \($0)" } ?? "- Do not post yet, just generate the content")

        Research the competitors, generate \(campaign.postsPerDay) slideshow posts with AI images and text overlays, and report back with the results.
        """

        let response = try await session.send(instruction)
        return response.content
    }

    /// Run a campaign with streaming response, updating `streamingText` in real time.
    func runCampaignStreaming(_ campaign: Campaign) async throws {
        let session = try getLarrySession()
        streamingText = ""

        let instruction = """
        Run a TikTok slideshow campaign:
        - Niche: \(campaign.niche)
        - Target audience: \(campaign.targetAudience)
        - Competitors: \(campaign.competitorAccounts.joined(separator: ", "))
        - Posts to generate: \(campaign.postsPerDay)
        - Image style: \(campaign.imageStyle.rawValue)

        Research competitors, generate \(campaign.postsPerDay) slideshows, and report results.
        """

        let stream = try await session.stream(instruction)
        for try await chunk in stream {
            if let content = chunk.content {
                streamingText += content
            }
        }
    }

    /// Ask Larry for analytics on a campaign's published posts.
    func fetchAnalytics(for campaign: Campaign) async throws -> String {
        let session = try getLarrySession()

        let response = try await session.send(
            "Check the TikTok analytics for campaign '\(campaign.name)' in the \(campaign.niche) niche. Report views, likes, shares, comments, and engagement rate for each post."
        )
        return response.content
    }

    /// Send a freeform message to the Larry agent.
    func chat(_ message: String) async throws -> String {
        let session = try getLarrySession()
        let response = try await session.send(message)
        return response.content
    }

    /// Reset the Larry conversation session.
    func resetSession() {
        larrySession?.reset()
        larrySession = nil
    }
}

// MARK: - Errors

enum OpenClawError: LocalizedError {
    case connectionFailed
    case notConnected
    case larryNotInstalled
    case campaignRunFailed

    var errorDescription: String? {
        switch self {
        case .connectionFailed: return "Failed to connect to your OpenClaw Gateway."
        case .notConnected: return "Not connected to an OpenClaw Gateway."
        case .larryNotInstalled: return "No agent with the Larry skill found. Select an agent in Settings."
        case .campaignRunFailed: return "Failed to run the campaign."
        }
    }
}
