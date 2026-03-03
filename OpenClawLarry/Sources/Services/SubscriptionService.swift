import Foundation
import StoreKit

/// Manages in-app subscriptions using StoreKit 2.
@MainActor
final class SubscriptionService: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedSubscription: Product?
    @Published var subscriptionTier: SubscriptionTier = .none
    @Published var isLoading = false

    /// Product identifiers configured in App Store Connect.
    static let starterMonthlyId = "com.openclawlarry.starter.monthly"
    static let proMonthlyId = "com.openclawlarry.pro.monthly"

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    /// Fetch available subscription products from the App Store.
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIds: Set<String> = [
                Self.starterMonthlyId,
                Self.proMonthlyId,
            ]
            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    /// Purchase a subscription product.
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    /// Restore previous purchases.
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        await updateSubscriptionStatus()
    }

    // MARK: - Status

    /// Check current entitlements and update the subscription tier.
    func updateSubscriptionStatus() async {
        var highestTier: SubscriptionTier = .none

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if transaction.productID == Self.proMonthlyId {
                highestTier = .pro
            } else if transaction.productID == Self.starterMonthlyId && highestTier != .pro {
                highestTier = .starter
            }
        }

        subscriptionTier = highestTier

        // Update purchasedSubscription product reference
        purchasedSubscription = products.first { product in
            switch highestTier {
            case .pro: return product.id == Self.proMonthlyId
            case .starter: return product.id == Self.starterMonthlyId
            case .none: return false
            }
        }
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates (renewals, revocations, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                if let _ = try? self.checkVerified(result) {
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

enum SubscriptionError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed."
        }
    }
}
