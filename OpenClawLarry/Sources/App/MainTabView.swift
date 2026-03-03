import SwiftUI

struct MainTabView: View {
    @ObservedObject var openClawService: OpenClawService
    @ObservedObject var subscriptionService: SubscriptionService
    @ObservedObject var campaignStore: CampaignStore

    @State private var showPaywall = false

    var body: some View {
        TabView {
            DashboardView(
                viewModel: DashboardViewModel(
                    campaignStore: campaignStore,
                    openClawService: openClawService
                ),
                openClawService: openClawService
            )
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }

            CampaignListView(
                campaignStore: campaignStore,
                viewModel: CampaignViewModel(
                    campaignStore: campaignStore,
                    openClawService: openClawService,
                    subscriptionService: subscriptionService
                )
            )
            .tabItem {
                Label("Campaigns", systemImage: "megaphone.fill")
            }

            NavigationStack {
                SettingsView(openClawService: openClawService)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .onAppear {
            if subscriptionService.subscriptionTier == .none {
                showPaywall = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscriptionService: subscriptionService)
        }
    }
}
