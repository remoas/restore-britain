import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var metrics: DashboardMetrics = .empty
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Latest analytics response from Larry (natural language).
    @Published var analyticsReport: String = ""

    private let campaignStore: CampaignStore
    private let openClawService: OpenClawService

    init(campaignStore: CampaignStore, openClawService: OpenClawService) {
        self.campaignStore = campaignStore
        self.openClawService = openClawService
    }

    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }

        let campaigns = campaignStore.campaigns
        let activeCampaigns = campaigns.filter { $0.status == .active }

        // Aggregate stats from locally stored data
        let totalViews = campaigns.reduce(0) { $0 + $1.totalViews }
        let totalLikes = campaigns.reduce(0) { $0 + $1.totalLikes }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var postsToday = 0
        var viewsToday = 0

        for campaign in campaigns {
            let posts = campaignStore.postsForCampaign(campaign.id)
            for post in posts {
                if let published = post.publishedAt, calendar.isDate(published, inSameDayAs: today) {
                    postsToday += 1
                    viewsToday += post.views
                }
            }
        }

        let topCampaign = campaigns.max(by: { $0.totalViews < $1.totalViews })

        let weeklyTrend = (0..<7).map { daysAgo -> MetricDataPoint in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            return MetricDataPoint(date: date, value: Double(totalViews / max(7 - daysAgo, 1)))
        }.reversed()

        metrics = DashboardMetrics(
            viewsToday: viewsToday,
            viewsThisWeek: totalViews,
            viewsThisMonth: totalViews,
            totalViews: totalViews,
            activeCampaigns: activeCampaigns.count,
            postsToday: postsToday,
            topCampaign: topCampaign,
            weeklyTrend: Array(weeklyTrend),
            revenueEstimate: Double(totalLikes) * 0.002
        )

        // Ask Larry for a fresh analytics report if connected
        if openClawService.connectionStatus.isConnected {
            for campaign in activeCampaigns {
                do {
                    let report = try await openClawService.fetchAnalytics(for: campaign)
                    analyticsReport = report
                } catch {
                    // Analytics refresh is best-effort
                }
            }
        }
    }
}
