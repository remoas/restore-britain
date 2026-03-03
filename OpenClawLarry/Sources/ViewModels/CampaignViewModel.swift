import Foundation

@MainActor
final class CampaignViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var errorMessage: String?

    /// Larry's latest response (natural language — not structured data).
    @Published var lastRunResponse: String = ""

    private let campaignStore: CampaignStore
    private let openClawService: OpenClawService
    private let subscriptionService: SubscriptionService

    init(
        campaignStore: CampaignStore,
        openClawService: OpenClawService,
        subscriptionService: SubscriptionService
    ) {
        self.campaignStore = campaignStore
        self.openClawService = openClawService
        self.subscriptionService = subscriptionService
    }

    /// Check if the user can create a new campaign based on their subscription.
    var canCreateCampaign: Bool {
        let tier = subscriptionService.subscriptionTier
        return campaignStore.campaigns.count < tier.maxCampaigns
    }

    /// Create and save a new campaign.
    func createCampaign(
        name: String,
        niche: String,
        targetAudience: String,
        competitors: [String],
        postsPerDay: Int
    ) -> Campaign? {
        guard canCreateCampaign else {
            errorMessage = "Upgrade your subscription to create more campaigns."
            return nil
        }

        let campaign = Campaign(
            name: name,
            niche: niche,
            targetAudience: targetAudience,
            postsPerDay: postsPerDay,
            competitorAccounts: competitors
        )
        campaignStore.addCampaign(campaign)
        return campaign
    }

    /// Start a campaign: send instructions to Larry via the OpenClaw Gateway.
    ///
    /// Larry is an AI skill — it runs autonomously on the OpenClaw server.
    /// We send a natural language instruction via /v1/chat/completions and
    /// Larry researches, generates, and posts content. The response is text.
    func runCampaign(_ campaign: Campaign) async {
        guard openClawService.connectionStatus.isConnected else {
            errorMessage = "Connect to your OpenClaw Gateway first."
            return
        }

        guard openClawService.isLarryInstalled else {
            errorMessage = "Select an agent with the Larry skill in Settings."
            return
        }

        isRunning = true
        errorMessage = nil
        lastRunResponse = ""
        defer { isRunning = false }

        do {
            // Activate campaign
            var updated = campaign
            updated.status = .active
            updated.lastRunAt = Date()
            campaignStore.updateCampaign(updated)

            // Tell Larry to run the campaign — response is natural language
            let response = try await openClawService.runCampaign(campaign)
            lastRunResponse = response
        } catch {
            errorMessage = error.localizedDescription
            var reverted = campaign
            reverted.status = .paused
            campaignStore.updateCampaign(reverted)
        }
    }

    /// Pause a running campaign.
    func pauseCampaign(_ campaign: Campaign) {
        var updated = campaign
        updated.status = .paused
        campaignStore.updateCampaign(updated)
    }

    /// Delete a campaign.
    func deleteCampaign(_ campaign: Campaign) {
        campaignStore.deleteCampaign(campaign)
    }
}
