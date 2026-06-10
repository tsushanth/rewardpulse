import UserNotifications
import UIKit
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    var isAuthorized = false

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                await registerForRemoteNotifications()
                setupNotificationCategories()
            }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleDailyPollReminder(hour: Int) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: ["daily_poll_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Daily Poll Available"
        content.body = "Answer today's question and earn your reward!"
        content.sound = .default
        content.categoryIdentifier = "daily_poll"

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_poll_reminder", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func scheduleStreakReminder(hour: Int = 20) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Don't Break Your Streak!"
        content.body = "You haven't earned today. Keep your streak alive by completing a survey."
        content.sound = .default
        content.categoryIdentifier = "streak_reminder"

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "streak_reminder", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func schedulePayoutConfirmation(amountFormatted: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Payout Sent!"
        content.body = "\(amountFormatted) is on its way to your account."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func removeAllPendingNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func setupNotificationCategories() {
        let startAction = UNNotificationAction(
            identifier: "START_SURVEY",
            title: "Start Survey",
            options: .foreground
        )
        let surveyCategory = UNNotificationCategory(
            identifier: "survey_available",
            actions: [startAction],
            intentIdentifiers: [],
            options: []
        )

        let streakCategory = UNNotificationCategory(
            identifier: "streak_reminder",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let pollCategory = UNNotificationCategory(
            identifier: "daily_poll",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([surveyCategory, streakCategory, pollCategory])
    }

    @MainActor
    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
