import SwiftUI

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var products: [RevenueCatOffering] = []
    @Published var selectedPlan: ProductPlanType = .yearly
    @Published var isPurchasing = false
    @Published var showError = false
    @Published var errorMessage: String?

    private let rcService: RevenueCatService
    private let analyticsService: AnalyticsService

    var roiDescription: String? {
        switch selectedPlan {
        case .weekly:   return "At average earnings, covers itself in ~8 days."
        case .yearly:   return "Best value — save 73% vs weekly. Pays for itself in 10 weeks."
        case .lifetime: return "One-time. Break even in ~5 months of active use."
        }
    }

    var purchaseButtonTitle: String {
        switch selectedPlan {
        case .weekly:   return "Start Weekly — $4.00/week"
        case .yearly:   return "Get Yearly — $56.00/year"
        case .lifetime: return "Get Lifetime — $92.80"
        }
    }

    init(rcService: RevenueCatService = .shared, analyticsService: AnalyticsService = .shared) {
        self.rcService = rcService
        self.analyticsService = analyticsService
    }

    func onAppear(source: String = "generic") async {
        products = await rcService.fetchCurrentOffering()
        analyticsService.log(.paywallViewed(source: source))
    }

    func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await rcService.purchase(plan: selectedPlan)
            analyticsService.log(.subscriptionStarted(plan: selectedPlan.rawValue))
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await rcService.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
