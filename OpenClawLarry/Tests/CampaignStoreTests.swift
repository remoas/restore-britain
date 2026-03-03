import XCTest
@testable import OpenClawLarry

final class CampaignStoreTests: XCTestCase {

    @MainActor
    func testAddCampaign() {
        let store = CampaignStore()
        let campaign = Campaign(name: "Test Campaign", niche: "fitness")

        store.addCampaign(campaign)

        XCTAssertEqual(store.campaigns.count, 1)
        XCTAssertEqual(store.campaigns.first?.name, "Test Campaign")
        XCTAssertEqual(store.campaigns.first?.niche, "fitness")
    }

    @MainActor
    func testUpdateCampaign() {
        let store = CampaignStore()
        var campaign = Campaign(name: "Original", niche: "tech")
        store.addCampaign(campaign)

        campaign.name = "Updated"
        store.updateCampaign(campaign)

        XCTAssertEqual(store.campaigns.first?.name, "Updated")
    }

    @MainActor
    func testDeleteCampaign() {
        let store = CampaignStore()
        let campaign = Campaign(name: "To Delete", niche: "cooking")
        store.addCampaign(campaign)

        store.deleteCampaign(campaign)

        XCTAssertTrue(store.campaigns.isEmpty)
    }

    @MainActor
    func testAddPostsUpdatesCampaignStats() {
        let store = CampaignStore()
        let campaign = Campaign(name: "Stats Test", niche: "gaming")
        store.addCampaign(campaign)

        var post = TikTokPost(campaignId: campaign.id, caption: "Test post")
        post.views = 1000
        post.likes = 50
        post.shares = 10

        store.addPosts([post], for: campaign.id)

        XCTAssertEqual(store.campaigns.first?.totalPosts, 1)
        XCTAssertEqual(store.campaigns.first?.totalViews, 1000)
        XCTAssertEqual(store.campaigns.first?.totalLikes, 50)
        XCTAssertEqual(store.campaigns.first?.totalShares, 10)
    }

    func testTikTokPostEngagementRate() {
        var post = TikTokPost(campaignId: UUID(), caption: "Engagement test")
        post.views = 1000
        post.likes = 50
        post.comments = 10
        post.shares = 5
        post.saves = 15

        // (50 + 10 + 5 + 15) / 1000 * 100 = 8.0%
        XCTAssertEqual(post.engagementRate, 8.0, accuracy: 0.01)
    }

    func testTikTokPostEngagementRateZeroViews() {
        let post = TikTokPost(campaignId: UUID(), caption: "Zero views")
        XCTAssertEqual(post.engagementRate, 0)
    }
}
