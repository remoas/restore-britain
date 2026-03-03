import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var openClawService: OpenClawService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    connectionBanner
                    statsGrid
                    weeklyChart
                    topCampaignCard
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }

    // MARK: - Connection Banner

    @ViewBuilder
    private var connectionBanner: some View {
        if !openClawService.connectionStatus.isConnected {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text("Not connected to OpenClaw")
                    .font(.subheadline)
                Spacer()
                NavigationLink("Connect") {
                    SettingsView(openClawService: openClawService)
                }
                .font(.subheadline.bold())
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 16) {
            StatCard(
                title: "Views Today",
                value: formatNumber(viewModel.metrics.viewsToday),
                icon: "eye.fill",
                color: .blue
            )
            StatCard(
                title: "Posts Today",
                value: "\(viewModel.metrics.postsToday)",
                icon: "square.stack.fill",
                color: .purple
            )
            StatCard(
                title: "Active Campaigns",
                value: "\(viewModel.metrics.activeCampaigns)",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                title: "Total Views",
                value: formatNumber(viewModel.metrics.totalViews),
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Views")
                .font(.headline)

            if viewModel.metrics.weeklyTrend.isEmpty {
                Text("No data yet. Run a campaign to see your stats.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 150)
            } else {
                Chart(viewModel.metrics.weeklyTrend) { dataPoint in
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Views", dataPoint.value)
                    )
                    .foregroundStyle(.blue.opacity(0.2))

                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Views", dataPoint.value)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Top Campaign

    @ViewBuilder
    private var topCampaignCard: some View {
        if let campaign = viewModel.metrics.topCampaign {
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Campaign")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading) {
                        Text(campaign.name)
                            .font(.title3.bold())
                        Text(campaign.niche)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(formatNumber(campaign.totalViews))
                            .font(.title2.bold())
                            .foregroundStyle(.blue)
                        Text("views")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000)
        } else if n >= 1_000 {
            return String(format: "%.1fK", Double(n) / 1_000)
        }
        return "\(n)"
    }
}
