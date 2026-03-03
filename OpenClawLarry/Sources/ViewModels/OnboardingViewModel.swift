import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var serverURL = ""
    @Published var apiKey = ""
    @Published var isConnecting = false
    @Published var errorMessage: String?
    @Published var isOnboardingComplete = false

    private let openClawService: OpenClawService

    let totalSteps = 4

    init(openClawService: OpenClawService) {
        self.openClawService = openClawService
    }

    var canProceed: Bool {
        switch currentStep {
        case 0: return true  // Welcome screen
        case 1: return true  // Feature overview
        case 2: return !serverURL.isEmpty && !apiKey.isEmpty  // Connection step
        case 3: return openClawService.connectionStatus.isConnected  // Confirmation
        default: return false
        }
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func connectToOpenClaw() async {
        guard let url = URL(string: serverURL) else {
            errorMessage = "Invalid server URL."
            return
        }

        isConnecting = true
        errorMessage = nil
        defer { isConnecting = false }

        do {
            try await openClawService.connect(serverURL: url, apiKey: apiKey)

            if !openClawService.isLarryInstalled {
                try await openClawService.installLarrySkill()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isOnboardingComplete = true
    }
}
