import SwiftUI

@main
struct OpenClawLarryApp: App {
    @StateObject private var openClawService = OpenClawService()
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var campaignStore = CampaignStore()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView(
                    openClawService: openClawService,
                    subscriptionService: subscriptionService,
                    campaignStore: campaignStore
                )
                .task {
                    await openClawService.restoreConnection()
                    await subscriptionService.updateSubscriptionStatus()
                }
            } else {
                OnboardingView(openClawService: openClawService)
            }
        }
    }
}
