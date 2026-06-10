import Foundation

enum Constants {
    // MARK: - API
    static let apiBaseURL = "https://api.rewardpulse.app/v1/"

    // MARK: - Product IDs
    enum ProductID {
        static let weeklySubscription   = "com.com.appfactory.rewardpulse.subscription.weekly"
        static let yearlySubscription   = "com.com.appfactory.rewardpulse.subscription.yearly"
        static let lifetimeSubscription = "com.com.appfactory.rewardpulse.subscription.lifetime"
        static let smallIAP             = "com.com.appfactory.rewardpulse.iap.small_iap"
    }

    // MARK: - RevenueCat
    static let revenueCatAPIKey = "appl_placeholder_key"

    // MARK: - Payout Thresholds
    static let freePayoutThresholdCents    = 500   // $5.00
    static let premiumPayoutThresholdCents = 250   // $2.50

    // MARK: - Rewards
    static let welcomeBonusCents       = 10    // $0.10
    static let dailyCheckInBonusCents  = 2     // $0.02
    static let dailyPollRewardCents    = 7     // $0.07 average
    static let dqPartialCreditCents    = 5     // $0.05

    // MARK: - Feature Flags
    static let enableReceiptScanning   = false
    static let enableLocationSurveys   = false
    static let enableReferralProgram   = false

    // MARK: - Streak
    static let streak7Multiplier   = 1.10
    static let streak30Multiplier  = 1.20
    static let streak100Multiplier = 1.30
    static let premiumMultiplier   = 1.50

    // MARK: - UI
    static let cardCornerRadius: CGFloat       = 16
    static let minTapTarget: CGFloat           = 44
    static let animationDurationStandard       = 0.3

    // MARK: - Minimum Age
    static let minimumAgeYears = 18
}
