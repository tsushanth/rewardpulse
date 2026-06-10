import SwiftData
import Foundation

@Model
final class EarningEvent {
    var id: UUID
    var amountCents: Int
    var source: EarningSource
    var surveyId: String?
    var eventDescription: String
    var createdAt: Date
    var isStreakBonus: Bool
    var multiplierApplied: Double

    init(amountCents: Int, source: EarningSource) {
        self.id = UUID()
        self.amountCents = amountCents
        self.source = source
        self.eventDescription = ""
        self.createdAt = .now
        self.isStreakBonus = false
        self.multiplierApplied = 1.0
    }

    var amountFormatted: String { String(format: "$%.2f", Double(amountCents) / 100.0) }
}

enum EarningSource: String, Codable {
    case survey
    case surveyDQPartial
    case dailyPoll
    case dailyCheckIn
    case streakBonus
    case weeklyChallenge
    case referralBonus
    case welcomeBonus
    case achievementBonus

    var displayName: String {
        switch self {
        case .survey: return "Survey"
        case .surveyDQPartial: return "Survey (Partial)"
        case .dailyPoll: return "Daily Poll"
        case .dailyCheckIn: return "Daily Check-In"
        case .streakBonus: return "Streak Bonus"
        case .weeklyChallenge: return "Weekly Challenge"
        case .referralBonus: return "Referral Bonus"
        case .welcomeBonus: return "Welcome Bonus"
        case .achievementBonus: return "Achievement Bonus"
        }
    }

    var colorName: String {
        switch self {
        case .survey: return "AccentColor"
        case .surveyDQPartial: return "Warning"
        case .dailyPoll: return "Success"
        case .dailyCheckIn: return "SecondaryText"
        case .streakBonus: return "StreakGold"
        case .weeklyChallenge: return "AccentColor"
        case .referralBonus: return "Success"
        case .welcomeBonus: return "AccentColor"
        case .achievementBonus: return "StreakGold"
        }
    }
}
