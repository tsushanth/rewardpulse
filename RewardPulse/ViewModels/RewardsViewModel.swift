import SwiftUI
import SwiftData

@MainActor
final class RewardsViewModel: ObservableObject {
    @Published var balanceCents: Int = 0
    @Published var minimumPayoutCents: Int = 500
    @Published var earningHistory: [EarningEvent] = []
    @Published var payoutHistory: [PayoutRequest] = []
    @Published var showPayoutFlow = false
    @Published var payoutInProgress = false
    @Published var isPremium = false
    @Published var errorMessage: String?
    @Published var showSuccessBanner = false

    var canRedeem: Bool { balanceCents >= minimumPayoutCents }
    var progressToPayoutPct: Double {
        guard minimumPayoutCents > 0 else { return 1.0 }
        return min(Double(balanceCents) / Double(minimumPayoutCents), 1.0)
    }
    var balanceFormatted: String { String(format: "$%.2f", Double(balanceCents) / 100.0) }
    var minimumPayoutFormatted: String { String(format: "$%.2f", Double(minimumPayoutCents) / 100.0) }

    func onAppear(context: ModelContext) async {
        isPremium = PremiumManager.shared.isPremium
        minimumPayoutCents = PremiumManager.shared.minimumPayoutCents

        balanceCents = (try? await APIService.shared.fetchBalance()) ?? balanceCents

        let earningDescriptor = FetchDescriptor<EarningEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        earningHistory = (try? context.fetch(earningDescriptor)) ?? []

        let payoutDescriptor = FetchDescriptor<PayoutRequest>(
            sortBy: [SortDescriptor(\.initiatedAt, order: .reverse)]
        )
        payoutHistory = (try? context.fetch(payoutDescriptor)) ?? []
    }

    func initiatePayoutRequest(method: PayoutMethod, destination: String, context: ModelContext) async {
        guard canRedeem else { return }
        payoutInProgress = true
        defer { payoutInProgress = false }

        do {
            try await APIService.shared.initiatePayoutRequest(
                amountCents: balanceCents,
                method: method,
                destination: destination
            )

            let request = PayoutRequest(amountCents: balanceCents, method: method, destination: destination)
            context.insert(request)
            try? context.save()

            payoutHistory.insert(request, at: 0)
            balanceCents = 0

            HapticManager.shared.trigger(.success)
            AnalyticsService.shared.log(.payoutInitiated(cents: request.amountCents, method: method.rawValue))
            showSuccessBanner = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
