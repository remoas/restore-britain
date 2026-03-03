import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    featuresSection
                    productsSection
                    restoreButton
                }
                .padding()
            }
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await subscriptionService.loadProducts()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)

            Text("Unlock Larry's Full Power")
                .font(.title2.bold())

            Text("Automate your TikTok marketing with AI-powered slideshows that drive real engagement and revenue.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            paywallFeature(icon: "infinity", text: "Unlimited campaigns")
            paywallFeature(icon: "bolt.fill", text: "Up to 50 posts per day")
            paywallFeature(icon: "chart.bar.fill", text: "Full analytics dashboard")
            paywallFeature(icon: "brain.head.profile", text: "Advanced competitor research")
            paywallFeature(icon: "paintbrush.fill", text: "All image styles unlocked")
            paywallFeature(icon: "bell.fill", text: "Performance alerts")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func paywallFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.accent)
                .frame(width: 24)
            Text(text)
                .font(.body)
        }
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(spacing: 12) {
            if subscriptionService.isLoading {
                ProgressView("Loading plans...")
            } else if subscriptionService.products.isEmpty {
                Text("Unable to load subscription options.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(subscriptionService.products, id: \.id) { product in
                    productCard(product)
                }
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        Button {
            Task {
                try? await subscriptionService.purchase(product)
            }
        } label: {
            VStack(spacing: 6) {
                Text(product.displayName)
                    .font(.headline)

                Text(product.displayPrice + " / month")
                    .font(.title3.bold())

                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.accentColor, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await subscriptionService.restorePurchases() }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}
