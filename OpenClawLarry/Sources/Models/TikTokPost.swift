import Foundation

/// A single TikTok slideshow post created and published by Larry.
struct TikTokPost: Identifiable, Codable {
    let id: UUID
    let campaignId: UUID
    var caption: String
    var hashtags: [String]
    var slideImageURLs: [URL]
    var status: PostStatus
    var scheduledAt: Date?
    var publishedAt: Date?
    var tiktokPostId: String?

    // Analytics (populated after publishing)
    var views: Int
    var likes: Int
    var comments: Int
    var shares: Int
    var saves: Int

    var engagementRate: Double {
        guard views > 0 else { return 0 }
        return Double(likes + comments + shares + saves) / Double(views) * 100
    }

    init(
        id: UUID = UUID(),
        campaignId: UUID,
        caption: String,
        hashtags: [String] = [],
        slideImageURLs: [URL] = []
    ) {
        self.id = id
        self.campaignId = campaignId
        self.caption = caption
        self.hashtags = hashtags
        self.slideImageURLs = slideImageURLs
        self.status = .generating
        self.views = 0
        self.likes = 0
        self.comments = 0
        self.shares = 0
        self.saves = 0
    }
}

enum PostStatus: String, Codable, CaseIterable {
    case generating
    case ready
    case scheduled
    case published
    case failed

    var displayName: String {
        switch self {
        case .generating: return "Generating"
        case .ready: return "Ready"
        case .scheduled: return "Scheduled"
        case .published: return "Published"
        case .failed: return "Failed"
        }
    }
}
