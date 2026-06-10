import SwiftData
import Foundation

@Model
final class StreakRecord {
    var currentStreak: Int
    var longestStreak: Int
    var lastEarnDate: Date?
    var streakInsuranceUsedThisMonth: Bool
    var streakInsuranceAvailable: Bool
    var totalActiveDays: Int

    var currentMultiplier: Double {
        switch currentStreak {
        case 100...: return 1.30
        case 30...:  return 1.20
        case 7...:   return 1.10
        default:     return 1.00
        }
    }

    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.streakInsuranceUsedThisMonth = false
        self.streakInsuranceAvailable = false
        self.totalActiveDays = 0
    }
}
