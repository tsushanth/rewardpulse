import Foundation
import SwiftData

/// A lightweight @Observable facade over StoreKitManager that exposes
/// premium-gated business rules (thresholds, multipliers, feature flags).
///
/// Inject via @Environment(PremiumManager.self) in views that need reactive
/// premium gating, or call PremiumManager.shared from ViewModels.
@Observable
@MainActor
final class PremiumManager {
    static let shared = PremiumManager()
    private init() {}

    // MARK: - Premium Status

    /// Whether the current user has an active premium entitlement.
    /// Delegates to StoreKitManager for live accuracy.
    var isPremium: Bool { StoreKitManager.shared.isPremium }

    // MARK: - Business Rules

    /// Minimum balance required before a payout can be initiated.
    var minimumPayoutCents: Int {
        isPremium ? Constants.premiumPayoutThresholdCents : Constants.freePayoutThresholdCents
    }

    /// Active earnings multiplier (considers both streak and premium status).
    func activeMultiplier(streakDays: Int) -> Double {
        let streakBonus: Double
        if streakDays >= 100 { streakBonus = Constants.streak100Multiplier }
        else if streakDays >= 30 { streakBonus = Constants.streak30Multiplier }
        else if streakDays >= 7  { streakBonus = Constants.streak7Multiplier }
        else { streakBonus = 1.0 }

        return isPremium ? max(streakBonus, Constants.premiumMultiplier) : streakBonus
    }

    // MARK: - Feature Gates

    /// Returns true if the user can access advanced analytics (hourly rate, projection, CSV).
    var canAccessFullStats: Bool { isPremium }

    /// Returns true if the user can see their earner percentile ranking.
    var canSeePercentileRank: Bool { isPremium }

    /// Returns true if the user can use streak insurance.
    var hasStreakInsurance: Bool { isPremium }

    /// Returns true if the user can export earnings as CSV.
    var canExportCSV: Bool { isPremium }

    // MARK: - Persist to SwiftData Profile

    /// Called by the app when a premiumStatusDidChange notification is received.
    /// Updates the local UserProfile model to keep SwiftData in sync.
    func syncToProfile(isPremium: Bool, context: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? context.fetch(descriptor).first else { return }
        profile.isPremium = isPremium
        if !isPremium { profile.premiumExpiresAt = nil }
        try? context.save()
    }
}
