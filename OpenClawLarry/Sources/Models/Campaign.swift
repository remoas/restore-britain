import Foundation

/// A Larry marketing campaign targeting a specific niche on TikTok.
struct Campaign: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var niche: String
    var targetAudience: String
    var status: CampaignStatus
    var postsPerDay: Int
    var createdAt: Date
    var lastRunAt: Date?

    /// Competitor TikTok accounts Larry will research for content ideas.
    var competitorAccounts: [String]

    /// Style preferences for AI-generated slideshow images.
    var imageStyle: ImageStyle

    /// Text overlay configuration.
    var overlayConfig: OverlayConfig

    /// Postiz connection details for automated posting.
    var postizAccountId: String?

    var totalPosts: Int
    var totalViews: Int
    var totalLikes: Int
    var totalShares: Int

    init(
        id: UUID = UUID(),
        name: String,
        niche: String,
        targetAudience: String = "",
        status: CampaignStatus = .draft,
        postsPerDay: Int = 3,
        competitorAccounts: [String] = [],
        imageStyle: ImageStyle = .modern,
        overlayConfig: OverlayConfig = .default
    ) {
        self.id = id
        self.name = name
        self.niche = niche
        self.targetAudience = targetAudience
        self.status = status
        self.postsPerDay = postsPerDay
        self.createdAt = Date()
        self.competitorAccounts = competitorAccounts
        self.imageStyle = imageStyle
        self.overlayConfig = overlayConfig
        self.totalPosts = 0
        self.totalViews = 0
        self.totalLikes = 0
        self.totalShares = 0
    }
}

enum CampaignStatus: String, Codable, CaseIterable {
    case draft
    case active
    case paused
    case completed

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }
}

enum ImageStyle: String, Codable, CaseIterable {
    case modern
    case vintage
    case minimalist
    case bold
    case pastel
    case dark

    var displayName: String { rawValue.capitalized }
}

struct OverlayConfig: Codable, Hashable {
    var fontName: String
    var fontSize: CGFloat
    var textColor: String
    var backgroundColor: String
    var position: TextPosition

    static let `default` = OverlayConfig(
        fontName: "SF Pro Display",
        fontSize: 32,
        textColor: "#FFFFFF",
        backgroundColor: "#000000CC",
        position: .bottom
    )
}

enum TextPosition: String, Codable, CaseIterable {
    case top, center, bottom
}
