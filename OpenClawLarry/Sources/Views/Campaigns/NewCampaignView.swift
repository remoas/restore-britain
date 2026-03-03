import SwiftUI

struct NewCampaignView: View {
    @ObservedObject var viewModel: CampaignViewModel
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var niche = ""
    @State private var targetAudience = ""
    @State private var competitorsText = ""
    @State private var postsPerDay = 3
    @State private var imageStyle: ImageStyle = .modern

    var body: some View {
        NavigationStack {
            Form {
                Section("Campaign Details") {
                    TextField("Campaign Name", text: $name)
                    TextField("Niche (e.g. fitness, cooking, tech)", text: $niche)
                    TextField("Target Audience", text: $targetAudience)
                }

                Section {
                    TextField("Competitor accounts (comma separated)", text: $competitorsText)
                        .autocapitalization(.none)
                } header: {
                    Text("Competitors")
                } footer: {
                    Text("Enter TikTok usernames Larry should research for content ideas.")
                }

                Section("Content Settings") {
                    Stepper("Posts per day: \(postsPerDay)", value: $postsPerDay, in: 1...20)

                    Picker("Image Style", selection: $imageStyle) {
                        ForEach(ImageStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                }
            }
            .navigationTitle("New Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCampaign()
                    }
                    .disabled(name.isEmpty || niche.isEmpty)
                }
            }
        }
    }

    private func createCampaign() {
        let competitors = competitorsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        _ = viewModel.createCampaign(
            name: name,
            niche: niche,
            targetAudience: targetAudience,
            competitors: competitors,
            postsPerDay: postsPerDay
        )
        isPresented = false
    }
}
