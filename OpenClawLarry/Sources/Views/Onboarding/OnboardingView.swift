import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init(openClawService: OpenClawService) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(openClawService: openClawService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= viewModel.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            TabView(selection: $viewModel.currentStep) {
                welcomeStep.tag(0)
                featuresStep.tag(1)
                connectionStep.tag(2)
                confirmationStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)

            // Navigation buttons
            HStack {
                if viewModel.currentStep > 0 {
                    Button("Back") {
                        viewModel.previousStep()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if viewModel.currentStep == viewModel.totalSteps - 1 {
                    Button("Get Started") {
                        viewModel.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canProceed)
                } else if viewModel.currentStep == 2 {
                    Button {
                        Task { await viewModel.connectToOpenClaw() }
                    } label: {
                        if viewModel.isConnecting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Connect")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canProceed || viewModel.isConnecting)
                } else {
                    Button("Next") {
                        viewModel.nextStep()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 72))
                .foregroundStyle(.accent)

            Text("Larry AI")
                .font(.largeTitle.bold())

            Text("TikTok Marketing on Autopilot")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Powered by OpenClaw, Larry researches your competitors, generates stunning slideshows, and posts them automatically.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var featuresStep: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("What Larry Does For You")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 20) {
                featureRow(icon: "magnifyingglass", title: "Competitor Research", description: "Analyzes top accounts in your niche")
                featureRow(icon: "photo.stack", title: "AI Image Generation", description: "Creates eye-catching slideshow images")
                featureRow(icon: "textformat", title: "Smart Text Overlays", description: "Adds engaging captions and CTAs")
                featureRow(icon: "arrow.up.circle", title: "Auto-Posting", description: "Publishes via Postiz on your schedule")
                featureRow(icon: "chart.line.uptrend.xyaxis", title: "Analytics Tracking", description: "Monitors views, engagement, and conversions")
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var connectionStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundStyle(.accent)

            Text("Connect Your OpenClaw Server")
                .font(.title2.bold())

            Text("Enter the URL and API key for your self-hosted OpenClaw instance.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                TextField("Server URL (e.g. https://my-openclaw.local)", text: $viewModel.serverURL)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.URL)
                    .autocapitalization(.none)

                SecureField("API Key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 24)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
    }

    private var confirmationStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.title.bold())

            Text("Larry is connected and ready to start creating TikTok content for you.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Components

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
