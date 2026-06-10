import FirebaseAnalytics
import FacebookCore
import Foundation

enum AnalyticsEvent {
    case appOpen
    case screenView(name: String)
    case signUp(method: String)
    case purchase(productID: String, cents: Int)
    case subscriptionStarted(plan: String)
    case featureUsed(name: String)
    case surveyStarted(id: String)
    case surveySubmitted(id: String, questionCount: Int)
    case surveyDisqualified(id: String)
    case rewardEarned(cents: Int, source: String)
    case paywallViewed(source: String)
    case payoutInitiated(cents: Int, method: String)
    case profileUpdated
    case accountDeleted
    case streakMilestone(days: Int)
    case achievementUnlocked(id: String)
    case notificationOpened(type: String)
    case attPromptShown
    case attAuthorized
    case attDenied

    var name: String {
        switch self {
        case .appOpen:              return "app_open"
        case .screenView:           return "screen_view"
        case .signUp:               return "sign_up"
        case .purchase:             return "purchase"
        case .subscriptionStarted:  return "subscription_start"
        case .featureUsed:          return "feature_used"
        case .surveyStarted:        return "survey_started"
        case .surveySubmitted:      return "survey_submitted"
        case .surveyDisqualified:   return "survey_disqualified"
        case .rewardEarned:         return "reward_earned"
        case .paywallViewed:        return "paywall_viewed"
        case .payoutInitiated:      return "payout_initiated"
        case .profileUpdated:       return "profile_updated"
        case .accountDeleted:       return "account_deleted"
        case .streakMilestone:      return "streak_milestone"
        case .achievementUnlocked:  return "achievement_unlocked"
        case .notificationOpened:   return "notification_opened"
        case .attPromptShown:       return "att_prompt_shown"
        case .attAuthorized:        return "att_authorized"
        case .attDenied:            return "att_denied"
        }
    }

    var firebaseParams: [String: Any] {
        switch self {
        case .appOpen:
            return [:]
        case .screenView(let name):
            return [AnalyticsParameterScreenName: name]
        case .signUp(let method):
            return [AnalyticsParameterMethod: method]
        case .purchase(let productID, let cents):
            return [AnalyticsParameterItemID: productID, "amount_cents": cents]
        case .subscriptionStarted(let plan):
            return [AnalyticsParameterItemCategory: plan]
        case .featureUsed(let name):
            return ["feature_name": name]
        case .surveyStarted(let id):
            return ["survey_id": id]
        case .surveySubmitted(let id, let count):
            return ["survey_id": id, "question_count": count]
        case .surveyDisqualified(let id):
            return ["survey_id": id]
        case .rewardEarned(let cents, let source):
            return ["amount_cents": cents, "source": source]
        case .paywallViewed(let source):
            return ["trigger_source": source]
        case .payoutInitiated(let cents, let method):
            return ["amount_cents": cents, "method": method]
        case .streakMilestone(let days):
            return ["streak_days": days]
        case .achievementUnlocked(let id):
            return ["achievement_id": id]
        case .notificationOpened(let type):
            return ["notification_type": type]
        default:
            return [:]
        }
    }
}

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.firebaseParams.isEmpty ? nil : event.firebaseParams)

        let fbParams = event.firebaseParams.reduce(into: [AppEvents.ParameterName: Any]()) { result, pair in
            result[AppEvents.ParameterName(pair.key)] = pair.value
        }
        if fbParams.isEmpty {
            AppEvents.shared.logEvent(AppEvents.Name(event.name))
        } else {
            AppEvents.shared.logEvent(AppEvents.Name(event.name), parameters: fbParams)
        }
    }

    // MARK: - User Properties

    func setUserProperties(subscriptionStatus: String) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        Analytics.setUserProperty(subscriptionStatus, forName: "subscription_status")
        Analytics.setUserProperty(version, forName: "app_version")
    }
}
