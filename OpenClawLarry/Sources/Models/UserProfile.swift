import Foundation

/// The authenticated user's profile and OpenClaw connection state.
struct UserProfile: Codable {
    let id: UUID
    var email: String
    var displayName: String
    var openClawServerURL: URL?
    var isOpenClawConnected: Bool
    var isLarrySkillInstalled: Bool
    var subscriptionTier: SubscriptionTier
    var subscriptionExpiresAt: Date?

    var isSubscriptionActive: Bool {
        guard subscriptionTier != .none else { return false }
        guard let expires = subscriptionExpiresAt else { return false }
        return expires > Date()
    }

    init(
        id: UUID = UUID(),
        email: String,
        displayName: String = ""
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.isOpenClawConnected = false
        self.isLarrySkillInstalled = false
        self.subscriptionTier = .none
    }
}

enum SubscriptionTier: String, Codable {
    case none
    case starter   // $49/month - 3 campaigns, 10 posts/day
    case pro       // $49/month (launch price) - unlimited

    var displayName: String {
        switch self {
        case .none: return "Free"
        case .starter: return "Starter"
        case .pro: return "Pro"
        }
    }

    var maxCampaigns: Int {
        switch self {
        case .none: return 0
        case .starter: return 3
        case .pro: return .max
        }
    }

    var maxPostsPerDay: Int {
        switch self {
        case .none: return 0
        case .starter: return 10
        case .pro: return 50
        }
    }
}
