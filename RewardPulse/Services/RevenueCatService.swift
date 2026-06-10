import RevenueCat
import StoreKit
import Foundation

struct RevenueCatOffering {
    let packageIdentifier: String
    let localizedPriceString: String
    let productIdentifier: String
    let planType: ProductPlanType

    init(package: Package) {
        self.packageIdentifier = package.identifier
        self.localizedPriceString = package.localizedPriceString
        self.productIdentifier = package.storeProduct.productIdentifier
        if package.identifier.contains("weekly") {
            self.planType = .weekly
        } else if package.identifier.contains("yearly") || package.identifier.contains("annual") {
            self.planType = .yearly
        } else if package.identifier.contains("lifetime") {
            self.planType = .lifetime
        } else {
            self.planType = .yearly
        }
    }
}

@MainActor
final class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()
    private init() {}

    @Published var isEntitled = false

    func configure(apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
        Purchases.logLevel = .warn
    }

    func checkEntitlement() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isEntitled = info.entitlements["premium"]?.isActive == true
        } catch {
            isEntitled = false
        }
    }

    func fetchCurrentOffering() async -> [RevenueCatOffering] {
        do {
            let offerings = try await Purchases.shared.offerings()
            return offerings.current?.availablePackages.map { RevenueCatOffering(package: $0) } ?? []
        } catch {
            return []
        }
    }

    func purchase(plan: ProductPlanType) async throws {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.package(identifier: plan.rcIdentifier) else { return }
        let (_, info, _) = try await Purchases.shared.purchase(package: package)
        isEntitled = info.entitlements["premium"]?.isActive == true
    }

    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        isEntitled = info.entitlements["premium"]?.isActive == true
    }

    nonisolated func syncTransaction(_ transaction: StoreKit.Transaction) async {
        // RevenueCat automatically handles StoreKit 2 transactions when configured
    }
}

enum ProductPlanType: String, CaseIterable {
    case weekly, yearly, lifetime

    var rcIdentifier: String {
        switch self {
        case .weekly:   return "$rc_weekly"
        case .yearly:   return "$rc_annual"
        case .lifetime: return "$rc_lifetime"
        }
    }

    var displayName: String {
        switch self {
        case .weekly:   return "Weekly"
        case .yearly:   return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var priceDisplay: String {
        switch self {
        case .weekly:   return "$4.00/week"
        case .yearly:   return "$56.00/year"
        case .lifetime: return "$92.80 one-time"
        }
    }
}
