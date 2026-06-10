import SwiftData
import Foundation

@Model
final class Survey {
    var id: String
    var title: String
    var categoryTag: SurveyCategory
    var estimatedMinutes: Int
    var rewardCents: Int
    var expiresAt: Date
    var matchScore: Int?
    var disqualificationRatePct: Int?
    var isPremiumOnly: Bool
    @Relationship(deleteRule: .cascade)
    var questions: [SurveyQuestion]
    var status: SurveyStatus
    var fetchedAt: Date

    @Relationship(deleteRule: .cascade)
    var response: SurveyResponse?

    init(id: String, title: String, category: SurveyCategory,
         estimatedMinutes: Int, rewardCents: Int, expiresAt: Date) {
        self.id = id
        self.title = title
        self.categoryTag = category
        self.estimatedMinutes = estimatedMinutes
        self.rewardCents = rewardCents
        self.expiresAt = expiresAt
        self.questions = []
        self.status = .available
        self.fetchedAt = .now
        self.isPremiumOnly = false
    }

    var isExpired: Bool { expiresAt < .now }
    var rewardFormatted: String { String(format: "$%.2f", Double(rewardCents) / 100.0) }
    var timeRemainingDescription: String {
        let hours = Int(expiresAt.timeIntervalSinceNow / 3600)
        return hours > 1 ? "Expires in \(hours)h" : "Expires soon"
    }
}

enum SurveyCategory: String, Codable, CaseIterable {
    case retail, technology, foodBeverage, entertainment, finance,
         healthcare, travel, automotive, realEstate, general

    var displayName: String {
        switch self {
        case .retail: return "Retail"
        case .technology: return "Technology"
        case .foodBeverage: return "Food & Beverage"
        case .entertainment: return "Entertainment"
        case .finance: return "Finance"
        case .healthcare: return "Healthcare"
        case .travel: return "Travel"
        case .automotive: return "Automotive"
        case .realEstate: return "Real Estate"
        case .general: return "General"
        }
    }

    var iconName: String {
        switch self {
        case .retail: return "cart.fill"
        case .technology: return "laptopcomputer"
        case .foodBeverage: return "fork.knife"
        case .entertainment: return "tv.fill"
        case .finance: return "dollarsign.circle.fill"
        case .healthcare: return "cross.fill"
        case .travel: return "airplane"
        case .automotive: return "car.fill"
        case .realEstate: return "house.fill"
        case .general: return "doc.text.fill"
        }
    }
}

enum SurveyStatus: String, Codable {
    case available, inProgress, completed, disqualified, expired
}
