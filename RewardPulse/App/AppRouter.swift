import SwiftUI
import Foundation

enum DeepLink: Equatable {
    case survey(id: String)
    case dailyPoll
    case rewards
    case streak
    case profile
    case paywall(source: String)
}

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()
    private init() {}

    @Published var pendingDeepLink: DeepLink?
    @Published var selectedTab: Int = 0

    func handle(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        switch type {
        case "survey_available":
            if let surveyId = userInfo["survey_id"] as? String {
                pendingDeepLink = .survey(id: surveyId)
                selectedTab = 1
            }
        case "daily_poll":
            pendingDeepLink = .dailyPoll
            selectedTab = 1
        case "streak_reminder":
            pendingDeepLink = .streak
            selectedTab = 0
        case "payout_confirmation":
            pendingDeepLink = .rewards
            selectedTab = 2
        default:
            break
        }
        AnalyticsService.shared.log(.notificationOpened(type: type))
    }

    func clearDeepLink() {
        pendingDeepLink = nil
    }
}
