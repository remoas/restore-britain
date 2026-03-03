import SwiftUI

struct CampaignDetailView: View {
    let campaign: Campaign
    @ObservedObject var viewModel: CampaignViewModel
    @ObservedObject var campaignStore: CampaignStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status + controls
                statusSection

                // Stats overview
                statsSection

                // Recent posts
                postsSection
            }
            .padding()
        }
        .navigationTitle(campaign.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if campaign.status == .active {
                        Button("Pause Campaign", systemImage: "pause.fill") {
                            viewModel.pauseCampaign(campaign)
                        }
                    }

                    Button("Delete Campaign", systemImage: "trash", role: .destructive) {
                        viewModel.deleteCampaign(campaign)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                StatusBadge(status: campaign.status)
                Spacer()
                if let lastRun = campaign.lastRunAt {
                    Text("Last run: \(lastRun, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task { await viewModel.runCampaign(campaign) }
            } label: {
                HStack {
                    if viewModel.isRunning {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(viewModel.isRunning ? "Generating..." : "Run Campaign Now")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isRunning)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Total Posts", value: "\(campaign.totalPosts)", icon: "square.stack.fill", color: .purple)
                StatCard(title: "Total Views", value: formatNumber(campaign.totalViews), icon: "eye.fill", color: .blue)
                StatCard(title: "Likes", value: formatNumber(campaign.totalLikes), icon: "heart.fill", color: .red)
                StatCard(title: "Shares", value: formatNumber(campaign.totalShares), icon: "arrowshape.turn.up.right.fill", color: .green)
            }
        }
    }

    // MARK: - Posts

    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Posts")
                .font(.headline)

            let posts = campaignStore.postsForCampaign(campaign.id)

            if posts.isEmpty {
                Text("No posts yet. Run the campaign to generate content.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(posts.prefix(10)) { post in
                    PostRow(post: post)
                }
            }
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }
}

struct PostRow: View {
    let post: TikTokPost

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(post.caption)
                    .font(.subheadline)
                    .lineLimit(2)
                Spacer()
                Text(post.status.displayName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            if !post.hashtags.isEmpty {
                Text(post.hashtags.map { "#\($0)" }.joined(separator: " "))
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            if post.status == .published {
                HStack(spacing: 12) {
                    Label("\(post.views)", systemImage: "eye")
                    Label("\(post.likes)", systemImage: "heart")
                    Label("\(post.comments)", systemImage: "bubble.right")
                    Label(String(format: "%.1f%%", post.engagementRate), systemImage: "chart.bar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
