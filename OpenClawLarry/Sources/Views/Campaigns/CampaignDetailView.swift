import SwiftUI

struct CampaignDetailView: View {
    let campaign: Campaign
    @ObservedObject var viewModel: CampaignViewModel
    @ObservedObject var campaignStore: CampaignStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusSection
                statsSection
                larryResponseSection
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
                    Text(viewModel.isRunning ? "Larry is working..." : "Run Campaign Now")
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
            Text("Campaign Info")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "Niche", value: campaign.niche)
                infoRow(label: "Target Audience", value: campaign.targetAudience)
                infoRow(label: "Posts/Day", value: "\(campaign.postsPerDay)")
                infoRow(label: "Image Style", value: campaign.imageStyle.displayName)

                if !campaign.competitorAccounts.isEmpty {
                    infoRow(label: "Competitors", value: campaign.competitorAccounts.joined(separator: ", "))
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.subheadline)
        }
    }

    // MARK: - Larry Response

    private var larryResponseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Larry's Report")
                .font(.headline)

            if viewModel.lastRunResponse.isEmpty {
                Text("Run the campaign to see Larry's output. Larry will research competitors, generate slideshows, and report back.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                Text(viewModel.lastRunResponse)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
