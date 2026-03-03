import Foundation
import Combine

/// Persists campaigns locally using JSON file storage.
@MainActor
final class CampaignStore: ObservableObject {
    @Published var campaigns: [Campaign] = []
    @Published var posts: [UUID: [TikTokPost]] = [:]

    private let fileManager = FileManager.default

    private var campaignsURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("campaigns.json")
    }

    private var postsURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("posts.json")
    }

    init() {
        load()
    }

    // MARK: - CRUD

    func addCampaign(_ campaign: Campaign) {
        campaigns.append(campaign)
        save()
    }

    func updateCampaign(_ campaign: Campaign) {
        if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            campaigns[index] = campaign
            save()
        }
    }

    func deleteCampaign(_ campaign: Campaign) {
        campaigns.removeAll { $0.id == campaign.id }
        posts.removeValue(forKey: campaign.id)
        save()
    }

    func addPosts(_ newPosts: [TikTokPost], for campaignId: UUID) {
        var existing = posts[campaignId] ?? []
        existing.append(contentsOf: newPosts)
        posts[campaignId] = existing

        // Update campaign stats
        if let index = campaigns.firstIndex(where: { $0.id == campaignId }) {
            campaigns[index].totalPosts = existing.count
            campaigns[index].totalViews = existing.reduce(0) { $0 + $1.views }
            campaigns[index].totalLikes = existing.reduce(0) { $0 + $1.likes }
            campaigns[index].totalShares = existing.reduce(0) { $0 + $1.shares }
        }

        save()
    }

    func postsForCampaign(_ campaignId: UUID) -> [TikTokPost] {
        posts[campaignId] ?? []
    }

    // MARK: - Persistence

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(campaigns) {
            try? data.write(to: campaignsURL)
        }
        if let data = try? encoder.encode(posts) {
            try? data.write(to: postsURL)
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = try? Data(contentsOf: campaignsURL) {
            campaigns = (try? decoder.decode([Campaign].self, from: data)) ?? []
        }
        if let data = try? Data(contentsOf: postsURL) {
            posts = (try? decoder.decode([UUID: [TikTokPost]].self, from: data)) ?? [:]
        }
    }
}
