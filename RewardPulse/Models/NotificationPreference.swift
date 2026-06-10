import SwiftData
import Foundation

@Model
final class NotificationPreference {
    var surveysAvailable: Bool
    var dailyPollReminder: Bool
    var streakReminder: Bool
    var payoutConfirmation: Bool
    var achievementUnlocked: Bool
    var quietHoursStart: Int
    var quietHoursEnd: Int
    var preferredNotifHour: Int?

    init() {
        self.surveysAvailable = true
        self.dailyPollReminder = true
        self.streakReminder = true
        self.payoutConfirmation = true
        self.achievementUnlocked = true
        self.quietHoursStart = 22
        self.quietHoursEnd = 8
    }
}
