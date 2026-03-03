import SwiftUI

struct CampaignListView: View {
    @ObservedObject var campaignStore: CampaignStore
    @ObservedObject var viewModel: CampaignViewModel
    @State private var showNewCampaign = false

    var body: some View {
        NavigationStack {
            Group {
                if campaignStore.campaigns.isEmpty {
                    emptyCampaignsView
                } else {
                    campaignList
                }
            }
            .navigationTitle("Campaigns")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewCampaign = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!viewModel.canCreateCampaign)
                }
            }
            .sheet(isPresented: $showNewCampaign) {
                NewCampaignView(viewModel: viewModel, isPresented: $showNewCampaign)
            }
        }
    }

    private var emptyCampaignsView: some View {
        ContentUnavailableView {
            Label("No Campaigns", systemImage: "megaphone")
        } description: {
            Text("Create your first campaign and let Larry start generating TikTok content for you.")
        } actions: {
            Button("Create Campaign") {
                showNewCampaign = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var campaignList: some View {
        List {
            ForEach(campaignStore.campaigns) { campaign in
                NavigationLink {
                    CampaignDetailView(
                        campaign: campaign,
                        viewModel: viewModel,
                        campaignStore: campaignStore
                    )
                } label: {
                    CampaignRow(campaign: campaign)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteCampaign(campaignStore.campaigns[index])
                }
            }
        }
    }
}

struct CampaignRow: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(campaign.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: campaign.status)
            }

            Text(campaign.niche)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label("\(campaign.totalPosts)", systemImage: "square.stack")
                Label(formatViews(campaign.totalViews), systemImage: "eye")
                Label("\(campaign.postsPerDay)/day", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatViews(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fK", Double(n) / 1000) }
        return "\(n)"
    }
}

struct StatusBadge: View {
    let status: CampaignStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch status {
        case .draft: return .secondary
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        }
    }
}
