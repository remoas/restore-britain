import Foundation

/// Aggregated analytics for the dashboard.
struct AnalyticsSnapshot: Codable {
    let date: Date
    let totalViews: Int
    let totalLikes: Int
    let totalShares: Int
    let totalPosts: Int
    let engagementRate: Double
    let estimatedRevenue: Double
}

/// Time-series data point for charts.
struct MetricDataPoint: Identifiable, Codable {
    var id: Date { date }
    let date: Date
    let value: Double
}

/// Analytics summary shown on the dashboard.
struct DashboardMetrics {
    let viewsToday: Int
    let viewsThisWeek: Int
    let viewsThisMonth: Int
    let totalViews: Int
    let activeCampaigns: Int
    let postsToday: Int
    let topCampaign: Campaign?
    let weeklyTrend: [MetricDataPoint]
    let revenueEstimate: Double

    static let empty = DashboardMetrics(
        viewsToday: 0,
        viewsThisWeek: 0,
        viewsThisMonth: 0,
        totalViews: 0,
        activeCampaigns: 0,
        postsToday: 0,
        topCampaign: nil,
        weeklyTrend: [],
        revenueEstimate: 0
    )
}
