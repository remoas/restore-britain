import SwiftUI

struct SettingsView: View {
    @ObservedObject var openClawService: OpenClawService
    @State private var serverURL = ""
    @State private var apiKey = ""
    @State private var showDisconnectAlert = false

    var body: some View {
        Form {
            connectionSection
            larrySkillSection
            aboutSection
        }
        .navigationTitle("Settings")
    }

    // MARK: - Connection

    private var connectionSection: some View {
        Section("OpenClaw Server") {
            if openClawService.connectionStatus.isConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Connected")
                    Spacer()
                }

                Button("Disconnect", role: .destructive) {
                    showDisconnectAlert = true
                }
                .alert("Disconnect?", isPresented: $showDisconnectAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Disconnect", role: .destructive) {
                        openClawService.disconnect()
                    }
                } message: {
                    Text("Larry won't be able to generate or post content until you reconnect.")
                }
            } else {
                TextField("Server URL", text: $serverURL)
                    .textContentType(.URL)
                    .autocapitalization(.none)

                SecureField("API Key", text: $apiKey)

                Button {
                    Task {
                        guard let url = URL(string: serverURL) else { return }
                        try? await openClawService.connect(serverURL: url, apiKey: apiKey)
                    }
                } label: {
                    HStack {
                        if case .connecting = openClawService.connectionStatus {
                            ProgressView()
                                .padding(.trailing, 4)
                        }
                        Text("Connect")
                    }
                }

                if case .error(let message) = openClawService.connectionStatus {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Larry Skill

    private var larrySkillSection: some View {
        Section("Larry Skill") {
            HStack {
                Text("Status")
                Spacer()
                if openClawService.isLarryInstalled {
                    Label("Installed", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Not Installed", systemImage: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if openClawService.connectionStatus.isConnected && !openClawService.isLarryInstalled {
                Button("Install Larry Skill") {
                    Task {
                        try? await openClawService.installLarrySkill()
                    }
                }
            }

            Link("Larry on ClawHub", destination: URL(string: "https://clawhub.ai/OllieWazza/larry")!)
                .font(.subheadline)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }

            Link("OpenClaw Documentation", destination: URL(string: "https://docs.openclaw.ai")!)
            Link("LarryBrain Marketplace", destination: URL(string: "https://www.larrybrain.com")!)
        }
    }
}
