import SwiftData
import Foundation

@Model
final class UserProfile {
    var id: String
    var email: String?
    var displayName: String?
    var createdAt: Date

    var birthYear: Int?
    var gender: String?
    var countryCode: String
    var postalCode: String?
    var householdSize: Int?
    var employmentStatus: String?
    var annualIncomeRange: String?
    var educationLevel: String?
    var interestCategories: [String]

    var paypalEmail: String?
    var preferredPayoutMethod: String

    var onboardingCompleted: Bool
    var profileCompletionScore: Int
    var isPremium: Bool
    var premiumExpiresAt: Date?

    var lifetimeEarningsCents: Int
    var totalSurveysCompleted: Int
    var totalSurveysDisqualified: Int
    var currentStreakDays: Int
    var longestStreakDays: Int
    var lastActiveDate: Date?

    var updatedAt: Date

    init(id: String, countryCode: String) {
        self.id = id
        self.countryCode = countryCode
        self.createdAt = .now
        self.updatedAt = .now
        self.onboardingCompleted = false
        self.profileCompletionScore = 0
        self.isPremium = false
        self.lifetimeEarningsCents = 0
        self.totalSurveysCompleted = 0
        self.totalSurveysDisqualified = 0
        self.currentStreakDays = 0
        self.longestStreakDays = 0
        self.preferredPayoutMethod = "paypal"
        self.interestCategories = []
    }

    var lifetimeEarningsDollars: Double { Double(lifetimeEarningsCents) / 100.0 }
    var qualificationRate: Double {
        let total = totalSurveysCompleted + totalSurveysDisqualified
        guard total > 0 else { return 0 }
        return Double(totalSurveysCompleted) / Double(total)
    }
    var minimumPayoutCents: Int { isPremium ? 250 : 500 }
}
