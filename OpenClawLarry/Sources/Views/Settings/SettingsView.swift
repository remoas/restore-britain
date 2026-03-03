import SwiftUI

struct SettingsView: View {
    @ObservedObject var openClawService: OpenClawService
    @State private var serverURL = ""
    @State private var gatewayToken = ""
    @State private var showDisconnectAlert = false

    var body: some View {
        Form {
            connectionSection
            agentSection
            setupGuideSection
            aboutSection
        }
        .navigationTitle("Settings")
    }

    // MARK: - Connection

    private var connectionSection: some View {
        Section {
            if openClawService.connectionStatus.isConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Connected to Gateway")
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
                TextField("Gateway URL (e.g. http://192.168.1.100:18789)", text: $serverURL)
                    .textContentType(.URL)
                    .autocapitalization(.none)

                SecureField("Gateway Token", text: $gatewayToken)

                Button {
                    Task {
                        guard let url = URL(string: serverURL) else { return }
                        try? await openClawService.connect(serverURL: url, apiKey: gatewayToken)
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
        } header: {
            Text("OpenClaw Gateway")
        } footer: {
            Text("Find your token in ~/.openclaw/openclaw.json under gateway.auth.token")
        }
    }

    // MARK: - Agent Selection

    @ViewBuilder
    private var agentSection: some View {
        if openClawService.connectionStatus.isConnected {
            Section {
                if openClawService.availableAgents.isEmpty {
                    Text("No agents found on this Gateway.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(openClawService.availableAgents) { agent in
                        Button {
                            openClawService.selectAgent(agent.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(agent.id)
                                        .font(.body)
                                    if let owner = agent.ownedBy {
                                        Text(owner)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if openClawService.selectedAgentId == agent.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }

                Button("Refresh Agents") {
                    Task { await openClawService.loadAgents() }
                }
            } header: {
                Text("Agent (with Larry skill)")
            } footer: {
                Text("Select the agent that has the Larry skill installed. If you don't see it, install Larry on your OpenClaw server first.")
            }
        }
    }

    // MARK: - Setup Guide

    private var setupGuideSection: some View {
        Section("Setup Requirements") {
            VStack(alignment: .leading, spacing: 8) {
                setupStep(number: 1, text: "Self-host OpenClaw on your server")
                setupStep(number: 2, text: "Enable chat completions endpoint in openclaw.json")
                setupStep(number: 3, text: "Install the Larry skill: npx clawhub install OllieWazza/larry")
                setupStep(number: 4, text: "Create an agent with Larry enabled")
                setupStep(number: 5, text: "Connect this app using your Gateway URL + token")
            }
            .padding(.vertical, 4)
        }
    }

    private func setupStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Circle())
            Text(text)
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

            Link("OpenClaw Docs", destination: URL(string: "https://docs.openclaw.ai")!)
            Link("Larry on ClawHub", destination: URL(string: "https://clawhub.ai/OllieWazza/larry")!)
            Link("LarryBrain Marketplace", destination: URL(string: "https://www.larrybrain.com")!)
        }
    }
}
