import SwiftData
import Foundation

@Model
final class Achievement {
    var id: AchievementID
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }

    init(id: AchievementID) {
        self.id = id
    }
}

enum AchievementID: String, Codable, CaseIterable {
    case firstSurvey
    case firstPayout
    case tenSurveys
    case fiftySurveys
    case streak7
    case streak30
    case streak100
    case profileComplete
    case referFriend

    var title: String {
        switch self {
        case .firstSurvey:     return "First Step"
        case .firstPayout:     return "First Cash Out"
        case .tenSurveys:      return "Regular"
        case .fiftySurveys:    return "Survey Pro"
        case .streak7:         return "On a Roll"
        case .streak30:        return "Consistent"
        case .streak100:       return "Dedicated"
        case .profileComplete: return "All In"
        case .referFriend:     return "Recruiter"
        }
    }

    var description: String {
        switch self {
        case .firstSurvey:     return "Complete your first survey"
        case .firstPayout:     return "Initiate your first payout"
        case .tenSurveys:      return "Complete 10 surveys"
        case .fiftySurveys:    return "Complete 50 surveys"
        case .streak7:         return "Earn 7 days in a row"
        case .streak30:        return "Earn 30 days in a row"
        case .streak100:       return "Earn 100 days in a row"
        case .profileComplete: return "Reach 100% profile completion"
        case .referFriend:     return "Convert your first referral"
        }
    }

    var bonusCents: Int {
        switch self {
        case .firstSurvey:     return 10
        case .firstPayout:     return 0
        case .tenSurveys:      return 25
        case .fiftySurveys:    return 50
        case .streak7:         return 15
        case .streak30:        return 30
        case .streak100:       return 50
        case .profileComplete: return 20
        case .referFriend:     return 25
        }
    }

    var iconName: String {
        switch self {
        case .firstSurvey:     return "star.fill"
        case .firstPayout:     return "dollarsign.circle.fill"
        case .tenSurveys:      return "doc.text.fill"
        case .fiftySurveys:    return "crown.fill"
        case .streak7:         return "flame.fill"
        case .streak30:        return "bolt.fill"
        case .streak100:       return "trophy.fill"
        case .profileComplete: return "person.fill.checkmark"
        case .referFriend:     return "person.2.fill"
        }
    }
}
