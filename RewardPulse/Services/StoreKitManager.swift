import StoreKit
import Foundation

// MARK: - Purchase Result

enum PurchaseOutcome {
    case success(Transaction)
    case pending          // Family Sharing / Ask to Buy
    case cancelled
}

// MARK: - Errors

enum StoreKitManagerError: Error, LocalizedError {
    case failedVerification
    case productNotFound(String)
    case purchaseFailed(Error)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed. Please contact support."
        case .productNotFound(let id):
            return "Product "\(id)" not found. Please try again later."
        case .purchaseFailed(let e):
            return e.localizedDescription
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        }
    }
}

// MARK: - StoreKitManager

@Observable
@MainActor
final class StoreKitManager {
    static let shared = StoreKitManager()

    // MARK: Observable State
    var products: [Product] = []
    var isPremium: Bool = false
    var isPurchasing: Bool = false
    var isRestoring: Bool = false
    var purchaseError: StoreKitManagerError? = nil
    var hasPendingPurchase: Bool = false   // e.g. Ask to Buy / Family Sharing

    // MARK: Computed accessors
    var weeklyProduct: Product?  { products.first { $0.id == Constants.ProductID.weeklySubscription } }
    var yearlyProduct: Product?  { products.first { $0.id == Constants.ProductID.yearlySubscription } }
    var lifetimeProduct: Product? { products.first { $0.id == Constants.ProductID.lifetimeSubscription } }
    var smallIAPProduct: Product? { products.first { $0.id == Constants.ProductID.smallIAP } }

    // MARK: Private
    private var transactionListenerTask: Task<Void, Never>?

    private static let premiumProductIDs: Set<String> = [
        Constants.ProductID.weeklySubscription,
        Constants.ProductID.yearlySubscription,
        Constants.ProductID.lifetimeSubscription
    ]

    private static let allProductIDs: Set<String> = premiumProductIDs.union([
        Constants.ProductID.smallIAP
    ])

    private static let persistenceKey = "com.rewardpulse.isPremium"

    // MARK: Init / Deinit

    private init() {
        // Restore persisted status immediately for fast UI render
        isPremium = UserDefaults.standard.bool(forKey: Self.persistenceKey)
        startTransactionListener()
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Load Products

    /// Fetches all products from the App Store (or StoreKit config in debug).
    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.allProductIDs)
            // Sort into a deterministic order for the paywall
            products.sort { lhs, rhs in
                let order = [
                    Constants.ProductID.weeklySubscription,
                    Constants.ProductID.yearlySubscription,
                    Constants.ProductID.lifetimeSubscription,
                    Constants.ProductID.smallIAP
                ]
                let li = order.firstIndex(of: lhs.id) ?? 99
                let ri = order.firstIndex(of: rhs.id) ?? 99
                return li < ri
            }
        } catch {
            purchaseError = .networkUnavailable
        }
    }

    // MARK: - Purchase

    /// Purchases a specific StoreKit Product.
    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        guard !isPurchasing else { return .cancelled }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verify(verification)
                await transaction.finish()
                await checkCurrentEntitlements()
                AnalyticsService.shared.log(.subscriptionStarted(plan: product.id))
                return .success(transaction)

            case .pending:
                hasPendingPurchase = true
                return .pending

            case .userCancelled:
                return .cancelled

            @unknown default:
                return .cancelled
            }
        } catch {
            let mapped = StoreKitManagerError.purchaseFailed(error)
            purchaseError = mapped
            throw mapped
        }
    }

    /// Convenience: purchase by plan type (looks up the matching Product).
    func purchasePlan(_ plan: ProductPlanType) async throws -> PurchaseOutcome {
        let targetID: String
        switch plan {
        case .weekly:   targetID = Constants.ProductID.weeklySubscription
        case .yearly:   targetID = Constants.ProductID.yearlySubscription
        case .lifetime: targetID = Constants.ProductID.lifetimeSubscription
        }
        guard let product = products.first(where: { $0.id == targetID }) else {
            let err = StoreKitManagerError.productNotFound(targetID)
            purchaseError = err
            throw err
        }
        return try await purchase(product)
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        isRestoring = true
        purchaseError = nil
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
        } catch {
            let mapped = StoreKitManagerError.purchaseFailed(error)
            purchaseError = mapped
            throw mapped
        }
    }

    // MARK: - Entitlement Validation

    /// Iterates all current entitlements from the App Store and updates `isPremium`.
    func checkCurrentEntitlements() async {
        var hasPremium = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verify(result) else { continue }
            guard Self.premiumProductIDs.contains(transaction.productID) else { continue }

            if let expiry = transaction.expirationDate {
                // Subscription — check not expired
                if expiry > .now {
                    hasPremium = true
                }
            } else {
                // Non-consumable (Lifetime) — always valid
                hasPremium = true
            }
        }

        setPremium(hasPremium)
    }

    // MARK: - Private Helpers

    /// Verifies a StoreKit VerificationResult, throwing on cryptographic failure.
    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitManagerError.failedVerification
        case .verified(let value):
            return value
        }
    }

    /// Updates `isPremium` and persists the value.
    private func setPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: Self.persistenceKey)

        // Sync to SwiftData UserProfile — best-effort, fire-and-forget
        Task { await syncPremiumToProfile(value) }
    }

    /// Keeps the local SwiftData UserProfile in sync with entitlement state.
    private func syncPremiumToProfile(_ isPremium: Bool) async {
        // Accessing SwiftData here requires a ModelContext. We post a notification
        // that the app can observe and persist to the profile model.
        NotificationCenter.default.post(
            name: .premiumStatusDidChange,
            object: nil,
            userInfo: ["isPremium": isPremium]
        )
    }

    /// Starts a long-lived Task that reacts to transaction updates (e.g. renewals,
    /// refunds, Ask-to-Buy approvals) delivered while the app is running.
    private func startTransactionListener() {
        transactionListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.verify(result) else { continue }
                await transaction.finish()
                await self.checkCurrentEntitlements()

                // Clear pending flag if this was an approval
                if Self.premiumProductIDs.contains(transaction.productID) {
                    self.hasPendingPurchase = false
                }
            }
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let premiumStatusDidChange = Notification.Name("com.rewardpulse.premiumStatusDidChange")
}
