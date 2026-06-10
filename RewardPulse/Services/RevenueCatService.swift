import Foundation
import StoreKit

// MARK: - RevenueCatService (Legacy Stub)
//
// All subscription logic has been migrated to StoreKitManager (native StoreKit 2).
// This class is kept as a thin forwarding stub so existing call sites compile without
// changes. Do not add new functionality here — use StoreKitManager / PremiumManager.

@MainActor
final class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()
    private init() {}

    /// Forwards to StoreKitManager for live accuracy.
    var isEntitled: Bool { StoreKitManager.shared.isPremium }

    /// No-op — RevenueCat SDK removed; configuration is handled by StoreKitManager.
    func configure(apiKey: String) {}

    /// Refreshes entitlements from the App Store.
    func checkEntitlement() async {
        await StoreKitManager.shared.checkCurrentEntitlements()
    }

    /// Delegates restore to StoreKitManager.
    func restorePurchases() async throws {
        try await StoreKitManager.shared.restorePurchases()
    }

    /// No-op — StoreKitManager handles transaction updates natively.
    func syncTransaction(_ transaction: StoreKit.Transaction) async {}
}

// MARK: - ProductPlanType
//
// Kept here for backwards compatibility with PaywallViewModel, PlanPickerView, etc.
// `rcIdentifier` removed — use Constants.ProductID directly.

enum ProductPlanType: String, CaseIterable, Hashable {
    case weekly, yearly, lifetime

    var displayName: String {
        switch self {
        case .weekly:   return "Weekly"
        case .yearly:   return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var productID: String {
        switch self {
        case .weekly:   return Constants.ProductID.weeklySubscription
        case .yearly:   return Constants.ProductID.yearlySubscription
        case .lifetime: return Constants.ProductID.lifetimeSubscription
        }
    }

    /// Fallback display price shown before StoreKit products are loaded.
    var fallbackPrice: String {
        switch self {
        case .weekly:   return "$4.00/week"
        case .yearly:   return "$56.00/year"
        case .lifetime: return "$92.80 one-time"
        }
    }
}

// MARK: - RevenueCatOffering (Legacy Stub)
//
// Kept for source compatibility with PlanPickerView until that view is updated.

struct RevenueCatOffering {
    let packageIdentifier: String
    let localizedPriceString: String
    let productIdentifier: String
    let planType: ProductPlanType
}
