import SwiftUI
import StoreKit

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var selectedPlan: ProductPlanType = .yearly
    @Published var purchaseState: PaywallPurchaseState = .idle
    @Published var showError = false
    @Published var errorMessage: String?
    /// Cached copy so ObservableObject view re-renders when products finish loading.
    @Published private(set) var products: [Product] = []

    private let analyticsService: AnalyticsService

    // MARK: - Init

    init(analyticsService: AnalyticsService = .shared) {
        self.analyticsService = analyticsService
        // Seed from already-loaded products if available (e.g. paywall re-opened)
        self.products = StoreKitManager.shared.products
    }

    var isLoading: Bool { products.isEmpty && purchaseState == .idle }

    var isPurchasing: Bool {
        purchaseState == .purchasing || purchaseState == .restoring
    }

    /// Localized price string from StoreKit, falling back to hard-coded string.
    func price(for plan: ProductPlanType) -> String {
        if let product = products.first(where: { $0.id == plan.productID }) {
            if let subscription = product.subscription {
                return subscription.localizedPricePerPeriod ?? product.displayPrice
            }
            return product.displayPrice
        }
        return plan.fallbackPrice
    }

    // MARK: - ROI Copy

    var roiDescription: String {
        switch selectedPlan {
        case .weekly:   return "At average earnings, covers itself in ~8 days."
        case .yearly:   return "Best value — save 73% vs weekly. Pays for itself in 10 weeks."
        case .lifetime: return "One-time. Break even in ~5 months of active use."
        }
    }

    var purchaseButtonTitle: String {
        switch selectedPlan {
        case .weekly:   return "Start Weekly — \(price(for: .weekly))"
        case .yearly:   return "Get Yearly — \(price(for: .yearly))"
        case .lifetime: return "Get Lifetime — \(price(for: .lifetime))"
        }
    }

    // MARK: - Lifecycle

    func onAppear(source: String = "generic") async {
        analyticsService.log(.paywallViewed(source: source))
        if StoreKitManager.shared.products.isEmpty {
            await StoreKitManager.shared.loadProducts()
        }
        products = StoreKitManager.shared.products
    }

    // MARK: - Actions

    func purchase() async {
        purchaseState = .purchasing
        clearError()

        do {
            let outcome = try await StoreKitManager.shared.purchasePlan(selectedPlan)
            products = StoreKitManager.shared.products  // Refresh product cache
            switch outcome {
            case .success:
                purchaseState = .succeeded
                HapticManager.shared.trigger(.success)
            case .pending:
                purchaseState = .pending
            case .cancelled:
                purchaseState = .idle
            }
        } catch let error as StoreKitManagerError {
            purchaseState = .idle
            showPurchaseError(error.errorDescription ?? error.localizedDescription)
        } catch {
            purchaseState = .idle
            showPurchaseError(error.localizedDescription)
        }
    }

    func restore() async {
        purchaseState = .restoring
        clearError()

        do {
            try await StoreKitManager.shared.restorePurchases()
            purchaseState = StoreKitManager.shared.isPremium ? .succeeded : .idle
            if !StoreKitManager.shared.isPremium {
                showPurchaseError("No active purchases found for this Apple ID.")
            } else {
                HapticManager.shared.trigger(.success)
            }
        } catch let error as StoreKitManagerError {
            purchaseState = .idle
            showPurchaseError(error.errorDescription ?? error.localizedDescription)
        } catch {
            purchaseState = .idle
            showPurchaseError(error.localizedDescription)
        }
    }

    // MARK: - Private

    private func clearError() {
        errorMessage = nil
        showError = false
    }

    private func showPurchaseError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Purchase State

enum PaywallPurchaseState: Equatable {
    case idle
    case purchasing
    case restoring
    case pending      // Ask to Buy / Family Sharing approval needed
    case succeeded
}

// MARK: - SubscriptionProduct+LocalizedPricePerPeriod

private extension Product.SubscriptionInfo {
    /// Returns a localized "price/period" string, e.g. "$4.00/week".
    var localizedPricePerPeriod: String? {
        guard let period = subscriptionPeriod.periodString else { return nil }
        return "\(product.displayPrice)/\(period)"
    }
}

private extension Product.SubscriptionPeriod {
    var periodString: String? {
        switch unit {
        case .day:   return value == 1 ? "day"   : "\(value) days"
        case .week:  return value == 1 ? "week"  : "\(value) weeks"
        case .month: return value == 1 ? "month" : "\(value) months"
        case .year:  return value == 1 ? "year"  : "\(value) years"
        @unknown default: return nil
        }
    }
}
