# RewardPulse — iOS Implementation Plan

> Bundle ID: `com.appfactory.rewardpulse` | Deployment Target: iOS 17+ | Architecture: MVVM + SwiftData

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [File Structure](#2-file-structure)
3. [Data Models](#3-data-models)
4. [View Hierarchy](#4-view-hierarchy)
5. [ViewModel Layer](#5-viewmodel-layer)
6. [Feature Prioritization](#6-feature-prioritization)
7. [Paywall Strategy](#7-paywall-strategy)
8. [SDK Integration Plan](#8-sdk-integration-plan)
9. [App Store Readiness](#9-app-store-readiness)
10. [TODO Checklist](#10-todo-checklist)

---

## 1. Architecture Overview

### 1.1 App Structure Diagram

```
RewardPulseApp
│
├── App Layer
│   ├── RewardPulseApp.swift          (entry point, SDK init, DI container)
│   └── AppDelegate.swift             (Firebase, Facebook app launch hooks)
│
├── Presentation Layer (SwiftUI)
│   ├── Onboarding/                   (5-screen onboarding flow)
│   ├── MainTabView.swift             (TabView shell: Home/Earn/Rewards/Stats/Profile)
│   ├── Home/
│   ├── Earn/
│   ├── Rewards/
│   ├── Stats/
│   ├── Profile/
│   ├── Paywall/
│   └── Shared/                       (reusable components)
│
├── ViewModel Layer
│   ├── OnboardingViewModel
│   ├── HomeViewModel
│   ├── EarnViewModel
│   ├── SurveyViewModel
│   ├── RewardsViewModel
│   ├── StatsViewModel
│   ├── ProfileViewModel
│   └── PaywallViewModel
│
├── Service Layer
│   ├── APIService                    (network requests, survey delivery)
│   ├── AuthService                   (Sign in with Apple, session mgmt)
│   ├── StoreKitService               (StoreKit 2, subscriptions, IAPs)
│   ├── RevenueCatService             (entitlement management)
│   ├── AnalyticsService              (Firebase + Facebook event wrapper)
│   ├── NotificationService           (UNUserNotificationCenter)
│   ├── AttributionService            (AdServices + Facebook attribution)
│   └── KeychainService               (secure credential storage)
│
├── Data Layer (SwiftData)
│   ├── Models/                       (@Model classes)
│   └── ModelContainer.swift          (schema config + migrations)
│
└── Utilities/
    ├── Extensions/
    ├── Constants.swift
    └── HapticManager.swift
```

### 1.2 MVVM Layer Breakdown

```
Views  ──────────────►  ViewModels  ──────────────►  Services
  │                          │                           │
  │  @State, @Binding        │  @Published props         │  async/await
  │  .task { }               │  @MainActor               │  URLSession
  │  .onAppear { }           │  Business logic           │  SwiftData
  │                          │  Input validation         │  Keychain
  │                          │                           │  StoreKit 2
  │                          ▼                           │
  │                     SwiftData Models  ◄──────────────┘
  │                     (local cache)
  │
  └── Shared UI Components (SurveyCard, BalanceView, StreakBadge…)
```

**Data Flow (unidirectional):**
1. User action fires a method on the ViewModel (`vm.startSurvey(id:)`)
2. ViewModel calls a Service (`await apiService.fetchSurvey(id:)`)
3. Service returns data; ViewModel updates `@Published` properties
4. SwiftUI re-renders automatically via `@Observable` / `@StateObject`
5. Persistent changes written to SwiftData via `ModelContext`
6. Analytics events fired as side effects in Service layer (not in Views)

### 1.3 Navigation Approach

The app uses a **hybrid** approach:
- **`TabView`** as the root shell (5 tabs: Home, Earn, Rewards, Stats, Profile)
- **`NavigationStack`** inside each tab for push navigation
- **`.sheet`** / **`.fullScreenCover`** for modals (paywall, survey, payout flow)

```
TabView
  ├── NavigationStack (Home)
  │     ├── HomeView
  │     └── SurveyDetailView  (push)
  ├── NavigationStack (Earn)
  │     ├── EarnView
  │     ├── SurveyPlayerView  (push)
  │     └── DailyPollView     (push)
  ├── NavigationStack (Rewards)
  │     ├── RewardsView
  │     └── PayoutFlowView    (fullScreenCover)
  ├── NavigationStack (Stats)
  │     └── StatsView
  └── NavigationStack (Profile)
        ├── ProfileView
        ├── EditProfileView   (push)
        ├── NotificationPrefsView (push)
        └── PrivacySettingsView   (push)

Global modals (environment-injected):
  ├── PaywallView             (fullScreenCover)
  ├── OnboardingView          (fullScreenCover, shown until complete)
  └── ATTPermissionView       (fullScreenCover, shown after first earn)
```

---

## 2. File Structure

```
RewardPulse/
├── RewardPulse.xcodeproj
├── RewardPulse/
│   ├── RewardPulseApp.swift                  # @main entry point, SDK init, ModelContainer setup
│   ├── AppDelegate.swift                     # Firebase configure, Facebook application(_:didFinishLaunching:)
│
│   ├── App/
│   │   ├── Constants.swift                   # API base URL, product IDs, feature flags, thresholds
│   │   ├── DIContainer.swift                 # Dependency injection container (environment object)
│   │   └── AppRouter.swift                   # Centralized navigation state / deep link handling
│
│   ├── Models/                               # SwiftData @Model classes
│   │   ├── UserProfile.swift                 # Demographics, preferences, subscription status
│   │   ├── Survey.swift                      # Survey metadata (title, reward, expiry, questions)
│   │   ├── SurveyQuestion.swift              # Individual question (type, options, branching)
│   │   ├── SurveyResponse.swift              # User's in-progress or submitted answers
│   │   ├── EarningEvent.swift                # Ledger entry: survey earn, poll earn, streak bonus
│   │   ├── DailyPoll.swift                   # Today's daily poll question + user's answer
│   │   ├── StreakRecord.swift                # Current streak count, last active date, insurance used
│   │   ├── Achievement.swift                 # Badge definition + unlock date
│   │   ├── PayoutRequest.swift               # Payout history: amount, method, status, timestamp
│   │   └── NotificationPreference.swift      # User's notification opt-ins and quiet hours
│
│   ├── Services/
│   │   ├── APIService.swift                  # URLSession wrapper: survey fetch, response submit, balance
│   │   ├── AuthService.swift                 # Sign In with Apple, session token, account deletion
│   │   ├── StoreKitService.swift             # StoreKit 2: Product load, purchase, restore, transaction listen
│   │   ├── RevenueCatService.swift           # RevenueCat entitlement check, offering fetch, purchase bridge
│   │   ├── AnalyticsService.swift            # Firebase + Facebook unified event logging wrapper
│   │   ├── NotificationService.swift         # UNUserNotificationCenter authorization and scheduling
│   │   ├── AttributionService.swift          # AdServices token fetch + Facebook attribution
│   │   ├── KeychainService.swift             # Read/write/delete Keychain items (session token, PayPal email)
│   │   └── HapticManager.swift               # UIImpactFeedbackGenerator helpers (reward credit, streak)
│
│   ├── ViewModels/
│   │   ├── OnboardingViewModel.swift         # Onboarding step state, profile save, welcome bonus
│   │   ├── HomeViewModel.swift               # Balance, streak, active survey count, daily poll status
│   │   ├── EarnViewModel.swift               # Survey queue fetch, filter, sort; daily poll load
│   │   ├── SurveyViewModel.swift             # Survey player: question paging, answer capture, submit
│   │   ├── RewardsViewModel.swift            # Payout eligibility, initiate payout, payout history
│   │   ├── StatsViewModel.swift              # Lifetime earnings, DQ rate, hourly rate, projections
│   │   ├── ProfileViewModel.swift            # Edit demographics, notification prefs, account deletion
│   │   └── PaywallViewModel.swift            # Fetch offerings, initiate purchase, restore, close logic
│
│   ├── Views/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingContainerView.swift  # TabView-based step container
│   │   │   ├── OnboardingValueView.swift      # Step 1: "Earn $0.50–$2.00 per survey"
│   │   │   ├── OnboardingNotifView.swift      # Step 2: Notification permission primer
│   │   │   ├── OnboardingProfileView.swift    # Step 3: 5–8 demographic questions
│   │   │   ├── OnboardingWelcomeView.swift    # Step 4: Welcome bonus credited ($0.10)
│   │   │   └── OnboardingDashTourView.swift   # Step 5: Animated dashboard walkthrough
│   │   │
│   │   ├── Main/
│   │   │   └── MainTabView.swift              # TabView root with 5 tabs
│   │   │
│   │   ├── Home/
│   │   │   ├── HomeView.swift                 # Dashboard: balance, streak, active surveys, daily poll CTA
│   │   │   ├── BalanceSummaryView.swift        # Animated balance + progress bar to next payout
│   │   │   ├── StreakBannerView.swift          # Streak count, flame icon, day label
│   │   │   └── QuickDailyPollCard.swift        # Compact daily poll CTA on home screen
│   │   │
│   │   ├── Earn/
│   │   │   ├── EarnView.swift                 # Survey queue list + earning method tiles
│   │   │   ├── SurveyCard.swift               # Card: topic, time, reward, expiry, match %, Start button
│   │   │   ├── SurveyDetailView.swift         # Full survey info before starting
│   │   │   ├── SurveyPlayerView.swift         # Question-by-question survey renderer
│   │   │   ├── QuestionViews/
│   │   │   │   ├── SingleChoiceView.swift      # Radio button list
│   │   │   │   ├── MultiChoiceView.swift       # Checkbox multi-select
│   │   │   │   ├── RatingScaleView.swift       # Star or slider rating
│   │   │   │   ├── OpenTextView.swift          # Text field with character counter
│   │   │   │   └── RankingView.swift           # Drag-to-reorder ranking
│   │   │   ├── DailyPollView.swift            # Full-screen daily poll (1 question, instant reward)
│   │   │   └── SurveyCompletionView.swift     # Reward credited animation + balance update
│   │   │
│   │   ├── Rewards/
│   │   │   ├── RewardsView.swift              # Balance, payout CTA, history list
│   │   │   ├── PayoutFlowView.swift           # Choose method (PayPal, gift card), confirm, send
│   │   │   ├── PayoutHistoryRow.swift         # Single payout row: date, amount, method, status badge
│   │   │   └── EarningHistoryRow.swift        # Single earning event row: source, amount, color-coded
│   │   │
│   │   ├── Stats/
│   │   │   ├── StatsView.swift                # Lifetime earnings, per-survey avg, hourly rate, projection
│   │   │   ├── EarningsChartView.swift        # Weekly/monthly earnings chart (Swift Charts)
│   │   │   ├── QualificationRateView.swift    # DQ rate trend over time
│   │   │   └── AchievementsView.swift         # Badge grid: earned vs locked
│   │   │
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift              # Profile completion %, subscription status, settings list
│   │   │   ├── EditProfileView.swift          # Editable demographics form
│   │   │   ├── NotificationPrefsView.swift    # Per-type notification toggles, quiet hours
│   │   │   ├── PrivacySettingsView.swift      # Data sharing toggles, CCPA opt-out, delete account
│   │   │   └── SubscriptionStatusView.swift   # Active plan details, manage/cancel link
│   │   │
│   │   ├── Paywall/
│   │   │   ├── PaywallView.swift              # Full paywall: feature list, plan picker, purchase CTA
│   │   │   ├── PlanPickerView.swift           # Weekly / Yearly / Lifetime card selector
│   │   │   └── FeatureBulletList.swift        # Animated feature comparison (free vs premium)
│   │   │
│   │   └── Shared/
│   │       ├── PrimaryButton.swift            # Reusable full-width CTA button
│   │       ├── LoadingOverlay.swift           # Semi-transparent spinner overlay
│   │       ├── ErrorBanner.swift              # Non-blocking error toast
│   │       ├── RewardCreditAnimation.swift    # Particle burst + balance increment animation
│   │       ├── ProgressRingView.swift         # Circular progress for payout goal
│   │       └── BadgeView.swift                # Achievement badge display component
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   │   ├── AppIcon.appiconset/
│   │   │   ├── AccentColor.colorset/
│   │   │   ├── Colors/                        # semantic colors: Background, Surface, PrimaryText…
│   │   │   └── Images/                        # onboarding illustrations, badge icons, category icons
│   │   ├── Localizable.strings                # All user-facing strings (en base)
│   │   └── PrivacyInfo.xcprivacy              # Privacy manifest (mandatory since May 2024)
│   │
│   └── Supporting Files/
│       ├── Info.plist                         # Privacy descriptions, URL schemes, capabilities
│       └── RewardPulse.entitlements           # Push notifications, iCloud, Sign In with Apple
│
├── RewardPulseTests/
│   ├── ViewModelTests/
│   └── ServiceTests/
│
└── Package.swift (or SPM dependencies in Xcode project)
    Dependencies:
    ├── RevenueCat/purchases-ios
    ├── firebase-ios-sdk (FirebaseAnalytics)
    ├── facebook-ios-sdk (FacebookCore)
    └── AdServices (system framework, no SPM needed)
```

---

## 3. Data Models

### 3.1 UserProfile

```swift
import SwiftData
import Foundation

@Model
final class UserProfile {
    // Identity
    var id: String                          // Apple user ID or server-assigned UUID
    var email: String?                      // Optional (Apple private relay supported)
    var displayName: String?
    var createdAt: Date
    
    // Demographics (for survey matching)
    var birthYear: Int?
    var gender: String?                     // "male" | "female" | "nonbinary" | "prefer_not"
    var countryCode: String                 // ISO 3166-1 alpha-2 (e.g. "US")
    var postalCode: String?
    var householdSize: Int?
    var employmentStatus: String?           // "employed_full" | "part" | "student" | "retired" | etc.
    var annualIncomeRange: String?          // "$0-25k" | "$25-50k" | … (display bracket, not exact)
    var educationLevel: String?
    var interestCategories: [String]        // ["technology", "food", "finance", …]
    
    // Payout
    var paypalEmail: String?               // Stored encrypted; see KeychainService for sensitive alt
    var preferredPayoutMethod: String      // "paypal" | "gift_card"
    
    // App state
    var onboardingCompleted: Bool
    var profileCompletionScore: Int        // 0–100, updated as fields are filled
    var isPremium: Bool                    // Cached from RevenueCat; source of truth is RC entitlement
    var premiumExpiresAt: Date?
    
    // Stats (cached from server, refreshed on launch)
    var lifetimeEarningsCents: Int         // Store in cents to avoid Float precision issues
    var totalSurveysCompleted: Int
    var totalSurveysDisqualified: Int
    var currentStreakDays: Int
    var longestStreakDays: Int
    var lastActiveDate: Date?
    
    // Timestamps
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
    }
    
    // Computed
    var lifetimeEarningsDollars: Double { Double(lifetimeEarningsCents) / 100.0 }
    var qualificationRate: Double {
        let total = totalSurveysCompleted + totalSurveysDisqualified
        guard total > 0 else { return 0 }
        return Double(totalSurveysCompleted) / Double(total)
    }
    var minimumPayoutCents: Int { isPremium ? 250 : 500 }  // $2.50 vs $5.00
}
```

### 3.2 Survey

```swift
@Model
final class Survey {
    var id: String                          // Server-assigned survey ID
    var title: String
    var categoryTag: SurveyCategory
    var estimatedMinutes: Int
    var rewardCents: Int                    // e.g. 75 = $0.75
    var expiresAt: Date
    var matchScore: Int?                    // 0–100 AI qualification probability
    var disqualificationRatePct: Int?       // Platform-wide DQ rate for this survey
    var isPremiumOnly: Bool                 // Exclusive to subscribers
    var questions: [SurveyQuestion]         // Ordered list
    var status: SurveyStatus
    var fetchedAt: Date
    
    // Relationships
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
    
    var displayName: String { /* e.g. "Food & Beverage" */ rawValue.capitalized }
    var iconName: String   { /* SF Symbol names */ "cart.fill" }  // mapped per case
}

enum SurveyStatus: String, Codable {
    case available, inProgress, completed, disqualified, expired
}
```

### 3.3 SurveyQuestion

```swift
@Model
final class SurveyQuestion {
    var id: String
    var questionText: String
    var questionType: QuestionType
    var options: [String]               // For choice-based types; empty for open text
    var required: Bool
    var sortOrder: Int
    var branchingRules: [BranchingRule] // If answer == X, skip to question Y
    
    init(id: String, text: String, type: QuestionType, sortOrder: Int) {
        self.id = id
        self.questionText = text
        self.questionType = type
        self.options = []
        self.required = true
        self.sortOrder = sortOrder
        self.branchingRules = []
    }
}

enum QuestionType: String, Codable {
    case singleChoice, multiChoice, ratingScale, openText, ranking, imageChoice, matrix
}

struct BranchingRule: Codable {
    var ifAnswerIndex: Int
    var thenSkipToQuestionId: String   // "END" to terminate survey
}
```

### 3.4 SurveyResponse

```swift
@Model
final class SurveyResponse {
    var surveyId: String
    var startedAt: Date
    var submittedAt: Date?
    var answers: [QuestionAnswer]
    var currentQuestionIndex: Int       // Enables mid-survey save/resume
    var outcome: ResponseOutcome
    var dqPartialCreditCents: Int       // $0.05 partial credit if DQ'd
    
    init(surveyId: String) {
        self.surveyId = surveyId
        self.startedAt = .now
        self.answers = []
        self.currentQuestionIndex = 0
        self.outcome = .inProgress
        self.dqPartialCreditCents = 0
    }
}

enum ResponseOutcome: String, Codable {
    case inProgress, completed, disqualified, abandoned
}

struct QuestionAnswer: Codable {
    var questionId: String
    var selectedIndices: [Int]          // For choice types
    var textAnswer: String?             // For open text
    var ratingValue: Int?               // For rating scale
    var rankedOrder: [Int]?             // For ranking
    var answeredAt: Date
}
```

### 3.5 EarningEvent

```swift
@Model
final class EarningEvent {
    var id: UUID
    var amountCents: Int                // Always positive (earning); use PayoutRequest for withdrawals
    var source: EarningSource
    var surveyId: String?               // Set when source == .survey or .surveyDQPartial
    var description: String             // Human-readable: "Retail Survey • 2 min"
    var createdAt: Date
    var isStreakBonus: Bool             // True if multiplier applied
    var multiplierApplied: Double       // 1.0 baseline; 1.5 for premium; 1.1–1.3 for streak milestones
    
    init(amountCents: Int, source: EarningSource) {
        self.id = UUID()
        self.amountCents = amountCents
        self.source = source
        self.description = ""
        self.createdAt = .now
        self.isStreakBonus = false
        self.multiplierApplied = 1.0
    }
}

enum EarningSource: String, Codable {
    case survey           // Completed survey
    case surveyDQPartial  // Partial pay on disqualification (first to market)
    case dailyPoll        // Daily poll completion
    case dailyCheckIn     // Just opening the app
    case streakBonus      // Milestone streak reward
    case weeklyChallenge  // Complete 5 surveys bonus
    case referralBonus    // Friend referral
    case welcomeBonus     // Onboarding welcome credit
    case achievementBonus // Badge milestone reward
}
```

### 3.6 DailyPoll

```swift
@Model
final class DailyPoll {
    var id: String
    var questionText: String
    var options: [String]               // 2–4 options
    var category: String
    var rewardCents: Int                // Typically 5–10 cents
    var availableDate: Date             // The calendar date this poll is for
    var expiresAt: Date                 // End of that day
    var userAnswerIndex: Int?           // nil = not answered; set after tap
    var answeredAt: Date?
    var resultDistribution: [Int]?      // % each option chosen (shown after answering)
    
    var isAnswered: Bool { userAnswerIndex != nil }
    var isAvailableToday: Bool {
        Calendar.current.isDate(availableDate, inSameDayAs: .now) && !isAnswered
    }
}
```

### 3.7 StreakRecord

```swift
@Model
final class StreakRecord {
    var currentStreak: Int
    var longestStreak: Int
    var lastEarnDate: Date?             // Date of most recent earning action
    var streakInsuranceUsedThisMonth: Bool  // Resets on 1st of each month
    var streakInsuranceAvailable: Bool      // Premium only: 1 miss per 30 days
    var totalActiveDays: Int
    
    // Milestone thresholds → multipliers (research: 7d=10%, 30d=20%, 100d=30%)
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
```

### 3.8 Achievement

```swift
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
    case firstSurvey       // "First Step" — first survey completed
    case firstPayout       // "First Cash Out" — first payout initiated
    case tenSurveys        // "Regular" — 10 surveys completed
    case fiftySurveys      // "Survey Pro" — 50 surveys completed
    case streak7           // "On a Roll" — 7-day streak
    case streak30          // "Consistent" — 30-day streak
    case streak100         // "Dedicated" — 100-day streak
    case profileComplete   // "All In" — 100% profile completion
    case referFriend       // "Recruiter" — first referral converted
    
    var title: String { /* mapped display names */ "" }
    var description: String { /* "Complete your first survey" etc */ "" }
    var bonusCents: Int { /* e.g. firstSurvey: 10, firstPayout: 0, streak100: 50 */ 0 }
    var iconName: String { /* SF Symbol or custom asset */ "" }
}
```

### 3.9 PayoutRequest

```swift
@Model
final class PayoutRequest {
    var id: UUID
    var amountCents: Int
    var method: PayoutMethod
    var destinationIdentifier: String   // PayPal email (masked for display), gift card type
    var status: PayoutStatus
    var initiatedAt: Date
    var completedAt: Date?
    var serverTransactionId: String?    // PayPal Payouts API batch item ID
    var failureReason: String?
    
    init(amountCents: Int, method: PayoutMethod, destination: String) {
        self.id = UUID()
        self.amountCents = amountCents
        self.method = method
        self.destinationIdentifier = destination
        self.status = .initiated
        self.initiatedAt = .now
    }
}

enum PayoutMethod: String, Codable {
    case paypal, giftCardAmazon, giftCardStarbucks, bankTransfer
}

enum PayoutStatus: String, Codable {
    case initiated, processing, completed, failed
    
    var displayText: String {
        switch self {
        case .initiated:  return "Sending…"
        case .processing: return "Processing"
        case .completed:  return "Sent"
        case .failed:     return "Failed"
        }
    }
}
```

### 3.10 NotificationPreference

```swift
@Model
final class NotificationPreference {
    var surveysAvailable: Bool          // New survey in queue
    var dailyPollReminder: Bool         // Daily poll available
    var streakReminder: Bool            // Streak at risk
    var payoutConfirmation: Bool        // Payout processed
    var achievementUnlocked: Bool       // Badge earned
    var quietHoursStart: Int            // Hour 0–23, e.g. 22 = 10pm
    var quietHoursEnd: Int              // Hour 0–23, e.g. 8 = 8am
    var preferredNotifHour: Int?        // User's preferred daily alert time (learned from engagement)
    
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
```

---

## 4. View Hierarchy

### 4.1 Entry Point

```swift
// RewardPulseApp.swift
@main
struct RewardPulseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let container: DIContainer
    let modelContainer: ModelContainer
    
    @State private var showOnboarding = false
    
    init() {
        container = DIContainer.shared
        modelContainer = try! ModelContainer(for: UserProfile.self, Survey.self,
            SurveyQuestion.self, SurveyResponse.self, EarningEvent.self,
            DailyPoll.self, StreakRecord.self, Achievement.self,
            PayoutRequest.self, NotificationPreference.self)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingContainerView()
                        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                } else {
                    MainTabView()
                }
            }
            .modelContainer(modelContainer)
            .environmentObject(container)
            .task { await checkOnboardingStatus() }
        }
    }
}
```

### 4.2 MainTabView

```swift
// MainTabView.swift
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showPaywall = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home",   systemImage: "house.fill") }
            .tag(0)
            
            NavigationStack {
                EarnView()
            }
            .tabItem { Label("Earn",    systemImage: "chart.bar.fill") }
            .tag(1)
            
            NavigationStack {
                RewardsView()
            }
            .tabItem { Label("Rewards", systemImage: "dollarsign.circle.fill") }
            .tag(2)
            
            NavigationStack {
                StatsView()
            }
            .tabItem { Label("Stats",   systemImage: "chart.xyaxis.line") }
            .tag(3)
            
            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(4)
        }
        .tint(.accentColor)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .environment(\.showPaywall, $showPaywall)   // injected via custom EnvironmentKey
    }
}
```

### 4.3 HomeView

```swift
// HomeView.swift
struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Balance card: animated dollar amount, progress ring, payout CTA
                BalanceSummaryView(
                    balanceCents: vm.balanceCents,
                    minimumPayoutCents: vm.minimumPayoutCents,
                    onRedeemTap: { vm.showPayoutFlow = true }
                )
                
                // Streak banner: flame icon + "Day 23 Streak"
                if vm.streakDays > 0 {
                    StreakBannerView(
                        days: vm.streakDays,
                        multiplier: vm.streakMultiplier,
                        insuranceAvailable: vm.streakInsuranceAvailable
                    )
                }
                
                // Daily poll compact card (always visible, highest habit value)
                QuickDailyPollCard(
                    poll: vm.todaysPoll,
                    onTap: { vm.navigateToDailyPoll = true }
                )
                
                // Active survey count teaser
                if vm.activeSurveyCount > 0 {
                    Button {
                        // Switch to Earn tab
                    } label: {
                        Label("\(vm.activeSurveyCount) surveys available", systemImage: "doc.text.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }
                
                // Recent earnings mini-list (last 3 events)
                RecentEarningsSection(events: vm.recentEarnings)
            }
            .padding()
        }
        .navigationTitle("RewardPulse")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await vm.refresh() }
        .task { await vm.onAppear() }
    }
}
```

### 4.4 SurveyCard

```swift
// SurveyCard.swift  — core repeating component on EarnView
struct SurveyCard: View {
    let survey: Survey
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(survey.categoryTag.displayName, systemImage: survey.categoryTag.iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if survey.isPremiumOnly {
                    Label("Premium", systemImage: "crown.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                }
            }
            
            Text(survey.title)
                .font(.headline)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                Label(survey.rewardFormatted, systemImage: "dollarsign.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline.weight(.bold))
                
                Label("~\(survey.estimatedMinutes) min", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let match = survey.matchScore {
                    Label("\(match)% match", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(match > 70 ? .green : .orange)
                }
            }
            
            HStack {
                Text(survey.timeRemainingDescription)
                    .font(.caption)
                    .foregroundStyle(survey.isExpired ? .red : .secondary)
                Spacer()
                Button("Start Survey", action: onStart)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(survey.isExpired)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}
```

### 4.5 PaywallView

```swift
// PaywallView.swift
struct PaywallView: View {
    @StateObject private var vm = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        Text("RewardPulse Premium")
                            .font(.title.bold())
                        Text("Earn more. Pay less fees. Skip the wait.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Feature bullets
                    FeatureBulletList()
                    
                    // Plan picker (Weekly / Yearly / Lifetime)
                    PlanPickerView(
                        selectedPlan: $vm.selectedPlan,
                        products: vm.products
                    )
                    
                    // ROI calculator hint from research: show "pays for itself in X days"
                    if let roi = vm.roiDescription {
                        Text(roi)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Purchase CTA
                    PrimaryButton(
                        title: vm.purchaseButtonTitle,
                        isLoading: vm.isPurchasing
                    ) {
                        Task { await vm.purchase() }
                    }
                    
                    // Restore + Terms
                    Button("Restore Purchases") {
                        Task { await vm.restore() }
                    }
                    .font(.footnote)
                    
                    Text("Subscriptions auto-renew. Cancel anytime in Settings.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Error", isPresented: $vm.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.errorMessage ?? "Something went wrong")
            }
        }
    }
}
```

---

## 5. ViewModel Layer

### 5.1 HomeViewModel

```swift
// HomeViewModel.swift
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var balanceCents: Int = 0
    @Published var minimumPayoutCents: Int = 500
    @Published var streakDays: Int = 0
    @Published var streakMultiplier: Double = 1.0
    @Published var streakInsuranceAvailable: Bool = false
    @Published var todaysPoll: DailyPoll? = nil
    @Published var activeSurveyCount: Int = 0
    @Published var recentEarnings: [EarningEvent] = []
    @Published var isLoading = false
    @Published var showPayoutFlow = false
    @Published var navigateToDailyPoll = false
    
    private let apiService: APIService
    private let analyticsService: AnalyticsService
    
    init(apiService: APIService = .shared, analyticsService: AnalyticsService = .shared) {
        self.apiService = apiService
        self.analyticsService = analyticsService
    }
    
    func onAppear() async {
        isLoading = true
        defer { isLoading = false }
        
        async let balance = apiService.fetchBalance()
        async let streak  = apiService.fetchStreak()
        async let polls   = apiService.fetchDailyPoll()
        async let surveys = apiService.fetchSurveyCount()
        
        balanceCents       = (try? await balance) ?? 0
        let streakData      = try? await streak
        streakDays          = streakData?.currentStreak ?? 0
        streakMultiplier    = streakData?.currentMultiplier ?? 1.0
        todaysPoll          = try? await polls
        activeSurveyCount   = (try? await surveys) ?? 0
        
        analyticsService.log(.screenView(name: "home"))
        await triggerStreakCheckIn()
    }
    
    func refresh() async { await onAppear() }
    
    /// Credits daily check-in micro-reward ($0.02) — called once per calendar day
    private func triggerStreakCheckIn() async {
        // server enforces idempotency; client just fires the request
        try? await apiService.recordDailyCheckIn()
    }
}
```

### 5.2 SurveyViewModel

```swift
// SurveyViewModel.swift
@MainActor
final class SurveyViewModel: ObservableObject {
    @Published var survey: Survey
    @Published var currentQuestionIndex: Int = 0
    @Published var answers: [QuestionAnswer] = []
    @Published var isSubmitting = false
    @Published var outcome: ResponseOutcome = .inProgress
    @Published var rewardCredited: Int = 0          // cents, shown in completion view
    @Published var showCompletionAnimation = false
    
    private let apiService: APIService
    private let analyticsService: AnalyticsService
    private let haptics: HapticManager
    
    var currentQuestion: SurveyQuestion? {
        guard currentQuestionIndex < survey.questions.count else { return nil }
        return survey.questions[currentQuestionIndex]
    }
    var progress: Double {
        guard !survey.questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(survey.questions.count)
    }
    var isLastQuestion: Bool { currentQuestionIndex == survey.questions.count - 1 }
    
    init(survey: Survey, apiService: APIService = .shared,
         analyticsService: AnalyticsService = .shared,
         haptics: HapticManager = .shared) {
        self.survey = survey
        self.apiService = apiService
        self.analyticsService = analyticsService
        self.haptics = haptics
    }
    
    func submitAnswer(_ answer: QuestionAnswer) {
        // Handle branching logic
        if let branch = currentQuestion?.branchingRules
            .first(where: { $0.ifAnswerIndex == answer.selectedIndices.first }) {
            if branch.thenSkipToQuestionId == "END" {
                Task { await submitSurvey(early: true) }
                return
            }
            // Navigate to specific question
        }
        answers.append(answer)
        
        // Autosave mid-survey response to SwiftData for resume support
        Task { await saveProgress() }
        
        if isLastQuestion {
            Task { await submitSurvey(early: false) }
        } else {
            currentQuestionIndex += 1
        }
    }
    
    func submitSurvey(early: Bool) async {
        isSubmitting = true
        analyticsService.log(.surveySubmitted(id: survey.id, questionCount: answers.count))
        
        do {
            let result = try await apiService.submitSurvey(id: survey.id, answers: answers)
            outcome = result.outcome
            rewardCredited = result.rewardCents
            
            if result.outcome == .completed {
                haptics.trigger(.reward)
                showCompletionAnimation = true
                analyticsService.log(.rewardEarned(cents: result.rewardCents, source: "survey"))
            } else if result.outcome == .disqualified {
                haptics.trigger(.light)
                analyticsService.log(.surveyDisqualified(id: survey.id))
                // Partial credit — research finding: even $0.05 eliminates resentment
                rewardCredited = result.dqPartialCreditCents
            }
        } catch {
            // Queue response for retry on next connectivity window (offline support)
        }
        isSubmitting = false
    }
    
    private func saveProgress() async {
        // SwiftData write via ModelContext — enables resume if app is killed mid-survey
    }
}
```

### 5.3 PaywallViewModel

```swift
// PaywallViewModel.swift
@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var products: [RevenueCatOffering] = []
    @Published var selectedPlan: ProductPlanType = .yearly  // Default to yearly (best value)
    @Published var isPurchasing = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let rcService: RevenueCatService
    private let analyticsService: AnalyticsService
    
    // Research: show ROI to justify subscription price
    var roiDescription: String? {
        switch selectedPlan {
        case .weekly:   return "At average earnings, covers itself in ~8 days."
        case .yearly:   return "Best value — save 73% vs weekly. Pays for itself in 10 weeks."
        case .lifetime: return "One-time. Break even in ~5 months of active use."
        }
    }
    
    var purchaseButtonTitle: String {
        switch selectedPlan {
        case .weekly:   return "Start Weekly — $4.00/week"
        case .yearly:   return "Get Yearly — $56.00/year"
        case .lifetime: return "Get Lifetime — $92.80"
        }
    }
    
    init(rcService: RevenueCatService = .shared, analyticsService: AnalyticsService = .shared) {
        self.rcService = rcService
        self.analyticsService = analyticsService
    }
    
    func onAppear() async {
        products = await rcService.fetchCurrentOffering()
        analyticsService.log(.paywallViewed(source: "generic"))
    }
    
    func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            try await rcService.purchase(plan: selectedPlan)
            analyticsService.log(.subscriptionStarted(plan: selectedPlan.rawValue))
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func restore() async {
        try? await rcService.restorePurchases()
    }
}

enum ProductPlanType: String {
    case weekly, yearly, lifetime
}
```

### 5.4 EarnViewModel

```swift
// EarnViewModel.swift
@MainActor
final class EarnViewModel: ObservableObject {
    @Published var surveys: [Survey] = []
    @Published var todaysPoll: DailyPoll? = nil
    @Published var isLoading = false
    @Published var selectedSurvey: Survey? = nil
    @Published var navigateToSurvey = false
    @Published var showPremiumLock = false
    
    private let apiService: APIService
    private let rcService: RevenueCatService
    private let analyticsService: AnalyticsService
    
    // Research: premium users see surveys 15 minutes earlier
    var isPremium: Bool { rcService.isEntitled }
    
    var sortedSurveys: [Survey] {
        surveys
            .filter { !$0.isExpired && ($0.isPremiumOnly ? isPremium : true) }
            .sorted { ($0.matchScore ?? 0) > ($1.matchScore ?? 0) }  // AI match score sort
    }
    
    func onAppear() async {
        isLoading = true
        async let surveyList = apiService.fetchSurveys()
        async let poll = apiService.fetchDailyPoll()
        surveys = (try? await surveyList) ?? []
        todaysPoll = try? await poll
        isLoading = false
        analyticsService.log(.screenView(name: "earn"))
    }
    
    func startSurvey(_ survey: Survey) {
        if survey.isPremiumOnly && !isPremium {
            showPremiumLock = true
            analyticsService.log(.paywallViewed(source: "premium_survey"))
            return
        }
        selectedSurvey = survey
        navigateToSurvey = true
        analyticsService.log(.surveyStarted(id: survey.id))
    }
}
```

### 5.5 RewardsViewModel

```swift
// RewardsViewModel.swift
@MainActor
final class RewardsViewModel: ObservableObject {
    @Published var balanceCents: Int = 0
    @Published var minimumPayoutCents: Int = 500
    @Published var earningHistory: [EarningEvent] = []
    @Published var payoutHistory: [PayoutRequest] = []
    @Published var showPayoutFlow = false
    @Published var payoutInProgress = false
    @Published var isPremium = false
    
    var canRedeem: Bool { balanceCents >= minimumPayoutCents }
    var progressToPayoutPct: Double {
        guard minimumPayoutCents > 0 else { return 1.0 }
        return min(Double(balanceCents) / Double(minimumPayoutCents), 1.0)
    }
    
    func initiatePayoutRequest(method: PayoutMethod, destination: String) async {
        guard canRedeem else { return }
        payoutInProgress = true
        defer { payoutInProgress = false }
        
        do {
            try await APIService.shared.initiatePayoutRequest(
                amountCents: balanceCents,
                method: method,
                destination: destination
            )
            // Server processes via PayPal Payouts API — webhook confirms later
            HapticManager.shared.trigger(.success)
            AnalyticsService.shared.log(.payoutInitiated(cents: balanceCents, method: method.rawValue))
        } catch { /* surface error */ }
    }
}
```

### 5.6 StatsViewModel

```swift
// StatsViewModel.swift
@MainActor
final class StatsViewModel: ObservableObject {
    @Published var lifetimeEarningsCents: Int = 0
    @Published var totalSurveysCompleted: Int = 0
    @Published var qualificationRatePct: Int = 0
    @Published var avgRewardPerSurveyCents: Int = 0
    @Published var effectiveHourlyRateCents: Int = 0  // lifetime earnings / total minutes spent * 60
    @Published var annualProjectionCents: Int = 0
    @Published var weeklyEarningsData: [(Date, Int)] = []  // for Swift Charts
    @Published var achievements: [Achievement] = []
    @Published var isPremium = false
    
    // Research: "You're in the top X% of earners" — builds competitive engagement
    var earnerPercentile: Int = 0
    
    // Only premium users see full history & projections
    var canSeeFullStats: Bool { isPremium }
    
    var projectionDescription: String {
        let dollars = Double(annualProjectionCents) / 100.0
        return String(format: "At your current pace, you'll earn $%.0f this year.", dollars)
    }
    
    var hourlyRateDescription: String {
        let rate = Double(effectiveHourlyRateCents) / 100.0
        return String(format: "You earn $%.2f/hour across your survey history.", rate)
    }
}
```

### 5.7 ProfileViewModel

```swift
// ProfileViewModel.swift
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var notificationPrefs: NotificationPreference?
    @Published var isSaving = false
    @Published var showDeleteConfirmation = false
    @Published var showPremiumStatus = false
    
    var profileCompletionPct: Int { profile?.profileCompletionScore ?? 0 }
    var completionPrompt: String {
        // Research: "Add your job type to unlock 3 new survey categories"
        if profileCompletionPct < 100 {
            return "Complete your profile to unlock more survey matches."
        }
        return "Your profile is fully complete."
    }
    
    func saveProfile(updates: ProfileUpdates) async {
        isSaving = true
        defer { isSaving = false }
        try? await APIService.shared.updateProfile(updates)
        AnalyticsService.shared.log(.profileUpdated)
    }
    
    /// App Store Guideline 5.1.1 — account deletion must be in-app and work immediately
    func deleteAccount() async {
        do {
            try await AuthService.shared.deleteAccount()
            // Clears SwiftData, Keychain, signs out
            AnalyticsService.shared.log(.accountDeleted)
        } catch { /* surface error */ }
    }
}
```

---

## 6. Feature Prioritization

### 6.1 Core Features (v1, Free Tier — Must Ship)

Based on research section 3.1 ("table stakes" for any survey reward app):

| Feature | Notes |
|---|---|
| Sign In with Apple + email sign-up | Required by App Store Guidelines |
| 5-screen onboarding with welcome bonus | Credit $0.10 at onboarding end to create "aha moment" |
| Demographic profile survey (5–8 questions) | Drives survey matching quality |
| Survey queue with card UI | Show reward, time, expiry, match score |
| Survey player (all question types) | Single, multi, rating, open text, ranking |
| Daily poll (1 question/day, $0.05–$0.10) | Always available — prevents engagement drought |
| Real-time balance display | Dollar amounts, never points |
| Streak tracker | 7/30/100-day milestones with multipliers |
| Achievement badges | First survey, first payout, streak milestones |
| PayPal payout flow | Server-side via PayPal Payouts API; $5 minimum for free |
| Payout history | Status tracking: initiated/processing/completed |
| Earning history (last 30 days, free) | Color-coded by source |
| Push notifications | Survey alerts, streak reminders, payout confirmations |
| Account deletion (in-app) | Guideline 5.1.1 compliance |
| Privacy settings dashboard | GDPR/CCPA toggles, data download request |
| PrivacyInfo.xcprivacy | Mandatory since May 2024; block first submission otherwise |
| ATT prompt (with pre-prompt education screen) | Time after first earning event for best opt-in rate |
| Offline grace handling | Cache balance, queue responses, disable Redeem when offline |
| Dark mode support | Full semantic color system |
| Accessibility labels + VoiceOver | ADA / HIG requirement |
| DQ partial credit ($0.05) | First-to-market differentiator; funded into B2B pricing |

### 6.2 Premium Features (Gated Behind Paywall — ~60% of feature surface)

| Feature | Paywall Trigger |
|---|---|
| Priority survey queue (15-min early access) | Passive — free users see a "Available in 12 min for free" badge |
| 1.5x reward multiplier on all earnings | Shown on each survey card for free users (FOMO) |
| Exclusive premium surveys ($2–$5 payout) | Card visible but locked with crown icon |
| $2.50 minimum payout threshold | Shown in Rewards tab ("Upgrade to unlock $2.50 minimum") |
| Streak insurance (1 miss/30 days) | Triggered when user is about to break a streak |
| Full lifetime analytics dashboard | Blurred preview on Stats tab for free users |
| Earnings projection & hourly rate | Premium-only stats section |
| Earnings CSV export | Profile tab, premium-only action |
| Earner percentile ranking | Stats tab, premium-only |
| Dedicated support priority | Profile tab label |

### 6.3 Nice-to-Have (Defer if Time-Constrained)

| Feature | Reason to Defer |
|---|---|
| Receipt scanning (purchase-verified panel) | Requires significant backend work; camera + OCR |
| Location-triggered surveys (CoreLocation Always) | App Review scrutiny on Always location is high; ship after trust is established |
| Referral program | Needs backend referral tracking, fraud prevention |
| Gift card payout (Tremendous API) | Good v1.1 feature; PayPal covers 90% of users first |
| Bank transfer (Stripe Connect) | US-only; adds compliance complexity |
| Weekly challenge bonus system | Complements streak but is not blocking |
| Multi-currency / international payout | Critical long-term but complex; defer behind PayPal |
| Adaptive notification timing (ML) | Nice personalization; can start with user-set preference |
| Swift Charts weekly earnings graph | StatsView works without it; add in v1.1 |
| Social sharing of achievements | Research says optional-only; low priority |

---

## 7. Paywall Strategy

### 7.1 Free vs Premium Split

```
FREE TIER                            PREMIUM TIER
─────────────────────────────        ─────────────────────────────
All standard surveys                 Priority survey queue (15 min early)
  (delayed 15 min after premium)     1.5x reward multiplier
Daily poll (always free)             Exclusive premium surveys
Standard reward rates                $2.50 minimum payout threshold
$5.00 minimum payout                 Streak insurance (1 miss / 30 days)
Streak tracking (no insurance)       Full lifetime analytics
Basic earning history (30 days)      Earnings projection & hourly rate
Achievements & badges                CSV export
                                     Earner percentile ranking
                                     Dedicated support priority
```

### 7.2 Paywall Trigger Points

| Trigger | Action | Timing |
|---|---|---|
| Post-onboarding (first launch) | Show paywall on onboarding final screen as optional upsell — NOT mandatory | After welcome bonus credited |
| Tap locked premium survey | Show paywall with "Unlock Premium Surveys" headline | Immediate on tap |
| Tap blurred Stats section | Show paywall with stats preview | Immediate on tap |
| Streak about to break | Show streak insurance paywall | Push notification tap + in-app |
| Balance reaches $5 (free user) | Toast: "Upgrade to cash out at $2.50" | RewardsView balance milestone |
| Settings → Subscription | Paywall presented from Profile tab | User-initiated |

**Never gate**: Daily poll, basic balance display, earning history (30 days), account deletion, privacy settings.

### 7.3 StoreKit 2 Integration

```swift
// StoreKitService.swift
import StoreKit

actor StoreKitService {
    static let shared = StoreKitService()
    
    // Product IDs — note double "com.com" matches spec
    private let productIDs: Set<String> = [
        "com.com.appfactory.rewardpulse.subscription.weekly",
        "com.com.appfactory.rewardpulse.subscription.yearly",
        "com.com.appfactory.rewardpulse.subscription.lifetime",
        "com.com.appfactory.rewardpulse.iap.small_iap"   // $0.99 boost/restore
    ]
    
    var products: [Product] = []
    
    func loadProducts() async throws {
        products = try await Product.products(for: productIDs)
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .pending:
            return nil   // Awaiting parental approval etc.
        case .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }
    
    /// Listen for transactions from other devices, renewals, refunds
    func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await RevenueCatService.shared.syncTransaction(transaction)
                await transaction.finish()
            }
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
    }
}

enum StoreError: Error {
    case failedVerification
}
```

### 7.4 RevenueCat Integration

RevenueCat sits on top of StoreKit 2 to provide:
- Entitlement management (`.isPremium` check without parsing receipt)
- A/B testing of paywall offerings
- Cross-platform receipt validation
- Churn analytics and renewal webhooks

```swift
// RevenueCatService.swift
import RevenueCat

@MainActor
final class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()
    
    @Published var isEntitled = false
    
    func configure(apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self   // Implement PurchasesDelegate
    }
    
    func checkEntitlement() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isEntitled = info.entitlements["premium"]?.isActive == true
        } catch { isEntitled = false }
    }
    
    func fetchCurrentOffering() async -> [RevenueCatOffering] {
        do {
            let offerings = try await Purchases.shared.offerings()
            return offerings.current?.availablePackages.map { RevenueCatOffering(package: $0) } ?? []
        } catch { return [] }
    }
    
    func purchase(plan: ProductPlanType) async throws {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.package(identifier: plan.rcIdentifier) else { return }
        let (_, info, _) = try await Purchases.shared.purchase(package: package)
        isEntitled = info.entitlements["premium"]?.isActive == true
    }
    
    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        isEntitled = info.entitlements["premium"]?.isActive == true
    }
}
```

---

## 8. SDK Integration Plan

### 8.1 SDK Initialization Order

Initialization order in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`:

```
1. Firebase.configure()                     ← First: crash reporting + analytics
2. FacebookCore.ApplicationDelegate setup   ← Second: attribution window starts
3. RevenueCat.configure(withAPIKey:)        ← Third: entitlement check at launch
4. AdServices token fetch (background)      ← Async, does not block launch
5. ATT prompt                               ← Deferred to post-first-earn (not at launch)
```

### 8.2 Firebase Analytics

```swift
// AnalyticsService.swift
import FirebaseAnalytics
import FacebookCore

enum AnalyticsEvent {
    case screenView(name: String)
    case surveyStarted(id: String)
    case surveySubmitted(id: String, questionCount: Int)
    case surveyDisqualified(id: String)
    case rewardEarned(cents: Int, source: String)
    case paywallViewed(source: String)
    case subscriptionStarted(plan: String)
    case payoutInitiated(cents: Int, method: String)
    case profileUpdated
    case accountDeleted
    case streakMilestone(days: Int)
    case achievementUnlocked(id: String)
    case notificationOpened(type: String)
    case attPromptShown
    case attAuthorized
    case attDenied
    
    var firebaseParams: [String: Any] {
        switch self {
        case .screenView(let name):
            return [AnalyticsParameterScreenName: name]
        case .surveyStarted(let id):
            return ["survey_id": id]
        case .surveySubmitted(let id, let count):
            return ["survey_id": id, "question_count": count]
        case .rewardEarned(let cents, let source):
            return ["amount_cents": cents, "source": source]
        case .paywallViewed(let source):
            return ["trigger_source": source]
        case .subscriptionStarted(let plan):
            return [AnalyticsParameterItemCategory: plan]
        case .payoutInitiated(let cents, let method):
            return ["amount_cents": cents, "method": method]
        default:
            return [:]
        }
    }
}

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    func log(_ event: AnalyticsEvent) {
        let name = String(describing: event).components(separatedBy: "(").first ?? ""
        Analytics.logEvent(name, parameters: event.firebaseParams)
        // Mirror to Facebook for attribution
        AppEvents.shared.logEvent(AppEvents.Name(name), parameters: event.firebaseParams)
    }
}
```

### 8.3 Facebook SDK Initialization

```swift
// AppDelegate.swift
import FacebookCore

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        RevenueCatService.shared.configure(apiKey: Constants.revenueCatAPIKey)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}
```

Add to Info.plist:
```xml
<key>FacebookAppID</key>         <string>YOUR_FB_APP_ID</string>
<key>FacebookClientToken</key>   <string>YOUR_FB_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>   <string>RewardPulse</string>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
</array>
```

### 8.4 AdServices Attribution

```swift
// AttributionService.swift
import AdServices

actor AttributionService {
    static let shared = AttributionService()
    
    /// Call once after user consent is confirmed; Apple Search Ads token
    func fetchAttributionToken() async -> String? {
        do {
            return try AAAttribution.attributionToken()
        } catch {
            return nil
        }
    }
    
    /// Send the token to your backend to resolve attribution via Apple Search Ads API
    func resolveAttribution() async {
        guard let token = await fetchAttributionToken() else { return }
        try? await APIService.shared.submitAttributionToken(token)
        AnalyticsService.shared.log(.screenView(name: "attribution_resolved"))
    }
}
```

### 8.5 App Tracking Transparency

```swift
// ATTPermissionView.swift + NotificationService.swift
import AppTrackingTransparency

// Research: Global opt-in ~46%; Finance/utilities ~53%.
// Best practice: show AFTER first earning event, not at launch.
// Include a custom pre-prompt education screen.

struct ATTPrePromptView: View {
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 56))
                .foregroundStyle(.accentColor)
            
            Text("A Quick Question")
                .font(.title2.bold())
            
            Text("Allowing tracking helps us show you surveys you're more likely to qualify for — meaning more earnings, fewer disqualifications.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            PrimaryButton(title: "Continue", isLoading: false) {
                onContinue()
            }
            
            Button("No Thanks") { onContinue() }
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}

// Then trigger system ATT prompt:
func requestATTPermission() async {
    let status = await ATTrackingManager.requestTrackingAuthorization()
    switch status {
    case .authorized:
        AnalyticsService.shared.log(.attAuthorized)
    case .denied, .restricted:
        AnalyticsService.shared.log(.attDenied)
    default:
        break
    }
}
```

### 8.6 Keychain Service

```swift
// KeychainService.swift
import Security

enum KeychainKey: String {
    case sessionToken = "com.appfactory.rewardpulse.sessionToken"
    case paypalEmail  = "com.appfactory.rewardpulse.paypalEmail"
}

struct KeychainService {
    static func save(_ value: String, for key: KeychainKey) throws {
        let data = value.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecValueData:   data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }
    
    static func load(_ key: KeychainKey) throws -> String {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { throw KeychainError.loadFailed }
        return string
    }
    
    static func delete(_ key: KeychainKey) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case loadFailed
}
```

---

## 9. App Store Readiness

### 9.1 Info.plist Required Entries

```xml
<!-- Privacy Usage Descriptions — all required if features are used -->
<key>NSUserNotificationsUsageDescription</key>
<string>We'll notify you when new surveys are available and before your streak expires.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Location helps us match you with local merchant surveys worth more money.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Background location enables location-triggered surveys when you visit stores.</string>

<key>NSCameraUsageDescription</key>
<string>Camera is used to scan receipts for purchase-verification surveys.</string>

<!-- Facebook SDK -->
<key>FacebookAppID</key>
<string>$(FACEBOOK_APP_ID)</string>
<key>FacebookClientToken</key>
<string>$(FACEBOOK_CLIENT_TOKEN)</string>
<key>FacebookDisplayName</key>
<string>RewardPulse</string>

<!-- Sign In with Apple URL scheme -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>com.appfactory.rewardpulse</string></array>
  </dict>
</array>

<!-- ATT — required since iOS 14 -->
<key>NSUserTrackingUsageDescription</key>
<string>Tracking helps personalize your survey matches so you earn more and qualify more often.</string>

<!-- AdServices — no extra plist entry needed; just link the framework -->
```

### 9.2 PrivacyInfo.xcprivacy (Mandatory)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "…">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>         <true/>   <!-- Set false if ATT not used -->
  <key>NSPrivacyTrackingDomains</key>
  <array>
    <string>graph.facebook.com</string>
    <string>analytics.google.com</string>
  </array>
  
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>           <string>NSPrivacyCollectedDataTypeEmailAddress</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>     <true/>
      <key>NSPrivacyCollectedDataTypeTracking</key>   <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>         <string>NSPrivacyCollectedDataTypePreciseLocation</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>   <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>         <string>NSPrivacyCollectedDataTypeProductInteraction</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>   <true/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>NSPrivacyCollectedDataTypePurposeAnalytics</string>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
      </array>
    </dict>
    <!-- Also declare: DeviceID, UserID, PurchaseHistory, SurveyResponses (other data) -->
  </array>
  
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>         <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>  <array><string>CA92.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>         <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>  <array><string>1C8F.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>         <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>  <array><string>E174.1</string></array>
    </dict>
  </array>
</dict>
</plist>
```

### 9.3 Entitlements (RewardPulse.entitlements)

```xml
<dict>
  <key>aps-environment</key>               <string>production</string>   <!-- Push Notifications -->
  <key>com.apple.developer.icloud-container-identifiers</key>
  <array><string>iCloud.com.appfactory.rewardpulse</string></array>
  <key>com.apple.developer.ubiquity-kvstore-identifier</key>
  <string>$(TeamIdentifierPrefix)com.appfactory.rewardpulse</string>
  <key>com.apple.developer.applesignin</key>
  <array><string>Default</string></array>
  <key>com.apple.security.application-groups</key>
  <array><string>group.com.appfactory.rewardpulse</string></array>
</dict>
```

### 9.4 Required Capabilities (Xcode → Signing & Capabilities)

- Push Notifications
- Sign In with Apple
- iCloud (CloudKit + Key-Value Storage)
- App Groups (for Notification Service Extension if needed)
- Background Modes: `Remote notifications` + `Background fetch`

### 9.5 Asset Requirements

| Asset | Spec |
|---|---|
| AppIcon | 1024×1024 PNG (no alpha); all required sizes generated by Xcode |
| AccentColor | Light + Dark appearances in Assets.xcassets |
| LaunchScreen | SwiftUI LaunchScreen.storyboard or Info.plist `UILaunchScreen` key |
| Semantic colors | Background, Surface, PrimaryText, SecondaryText, Success, Warning, Error, Gold (streak) |
| Category icons | SF Symbols where possible; custom SVG for category-specific icons |
| Onboarding illustrations | 3 illustrations for value/notification/dashboard steps |
| Achievement badge icons | 9 badges: PNG @1x/@2x/@3x or SVG |
| Empty state illustrations | Empty survey queue, no earnings history yet |

### 9.6 Age Rating

Set to **17+** in App Store Connect. The app involves financial transactions and must enforce age verification at signup (collect birth year, reject if under 18). This eliminates COPPA risk per research section 8.1 Risk 7.

### 9.7 App Review Notes (submit with every build)

Include the following in the App Review Information notes field:
- Credentials for a test account with pre-seeded balance and survey data
- Explanation that cash payouts go outbound via server-side PayPal API (not StoreKit)
- Explanation that the subscription provides priority access and multipliers — not access to the app itself (free tier is fully functional)
- Note differentiating RewardPulse from Google Opinion Rewards: gamification, AI matching, partial DQ pay, premium subscription tier

---

## 10. TODO Checklist

### Project Setup
- [ ] Create Xcode project: `RewardPulse`, Bundle ID `com.appfactory.rewardpulse`, iOS 17+, SwiftUI lifecycle
- [ ] Add SPM dependencies: `purchases-ios` (RevenueCat), `firebase-ios-sdk` (FirebaseAnalytics), `facebook-ios-sdk` (FacebookCore)
- [ ] Link AdServices.framework (system framework, no SPM needed)
- [ ] Configure Signing & Capabilities: Push Notifications, Sign In with Apple, iCloud, App Groups, Background Modes
- [ ] Create `RewardPulse.entitlements` with all required keys
- [ ] Add `AccentColor` and semantic color set to `Assets.xcassets`
- [ ] Create `PrivacyInfo.xcprivacy` with all data type and API reason declarations
- [ ] Create `Info.plist` entries for all privacy usage descriptions and Facebook SDK keys
- [ ] Set up `.xcconfig` files for Debug/Release with API keys (never commit raw keys)

### Data Layer
- [ ] Define `UserProfile` SwiftData model with all properties
- [ ] Define `Survey` SwiftData model with `SurveyCategory` and `SurveyStatus` enums
- [ ] Define `SurveyQuestion` model with `QuestionType` and `BranchingRule`
- [ ] Define `SurveyResponse` model with `QuestionAnswer` and `ResponseOutcome`
- [ ] Define `EarningEvent` model with `EarningSource` enum
- [ ] Define `DailyPoll` model
- [ ] Define `StreakRecord` model with computed `currentMultiplier`
- [ ] Define `Achievement` model with `AchievementID` enum (9 achievements)
- [ ] Define `PayoutRequest` model with `PayoutMethod` and `PayoutStatus`
- [ ] Define `NotificationPreference` model
- [ ] Configure `ModelContainer` in `RewardPulseApp.swift` with all models
- [ ] Verify SwiftData schema compiles with a preview/test run

### App Entry Point & Navigation
- [ ] Implement `RewardPulseApp.swift` with `@main`, `DIContainer`, `ModelContainer` initialization
- [ ] Implement `AppDelegate.swift` with Firebase, Facebook, RevenueCat initialization in correct order
- [ ] Implement `MainTabView.swift` with 5 tabs using `NavigationStack` in each
- [ ] Implement `DIContainer.swift` with all service singletons as environment object
- [ ] Implement `AppRouter.swift` for deep link routing (push notification taps)
- [ ] Implement `Constants.swift` with product IDs, API base URL, payout thresholds

### Services
- [ ] Implement `KeychainService` (save/load/delete session token and PayPal email)
- [ ] Implement `APIService` stub with URLSession + JWT auth header injection
- [ ] Implement `AuthService` with Sign In with Apple via `ASAuthorizationController`
- [ ] Implement `StoreKitService` with StoreKit 2: load products, purchase, verify, finish transaction
- [ ] Add `Transaction.updates` listener in `StoreKitService` for renewal/refund handling
- [ ] Implement `RevenueCatService` with configure, entitlement check, purchase, restore
- [ ] Implement `AnalyticsService` wrapping Firebase `Analytics.logEvent` + `AppEvents`
- [ ] Implement `NotificationService` with authorization request, schedule local notifications
- [ ] Implement `AttributionService` with `AAAttribution.attributionToken()` + backend POST
- [ ] Implement `HapticManager` with `.reward`, `.success`, `.light` presets

### ViewModels
- [ ] Implement `OnboardingViewModel` (step state, profile save, welcome bonus trigger)
- [ ] Implement `HomeViewModel` (@Published balance, streak, poll, active count; `onAppear`, `refresh`)
- [ ] Implement `EarnViewModel` (survey fetch, sort by match score, premium gate logic)
- [ ] Implement `SurveyViewModel` (question paging, branching, answer capture, submit, DQ partial credit)
- [ ] Implement `RewardsViewModel` (payout eligibility, `initiatePayoutRequest`, history fetch)
- [ ] Implement `StatsViewModel` (lifetime earnings, hourly rate, projection, achievement load)
- [ ] Implement `ProfileViewModel` (edit demographics, save, account deletion, notification prefs)
- [ ] Implement `PaywallViewModel` (fetch offerings, ROI description, purchase, restore)

### Onboarding Views
- [ ] Implement `OnboardingContainerView` (TabView step container, progress dots)
- [ ] Implement `OnboardingValueView` (step 1: specific earning claim "$0.50–$2.00 per survey")
- [ ] Implement `OnboardingNotifView` (step 2: notification primer before system prompt)
- [ ] Implement `OnboardingProfileView` (step 3: 5–8 demographic questions with progress bar)
- [ ] Implement `OnboardingWelcomeView` (step 4: welcome bonus $0.10 credited with animation)
- [ ] Implement `OnboardingDashTourView` (step 5: animated walkthrough of home screen)

### Home Views
- [ ] Implement `HomeView` (ScrollView layout: balance card, streak banner, daily poll CTA, survey count)
- [ ] Implement `BalanceSummaryView` (animated dollar amount, progress ring to payout threshold)
- [ ] Implement `StreakBannerView` (flame icon, day count, multiplier badge)
- [ ] Implement `QuickDailyPollCard` (compact daily poll CTA, reward amount, tap to open)

### Earn Views
- [ ] Implement `EarnView` (survey queue List + daily poll tile + earning method tiles)
- [ ] Implement `SurveyCard` (card layout: category, title, reward $, time, expiry, match %, Start button)
- [ ] Implement `SurveyDetailView` (full survey info screen before starting)
- [ ] Implement `SurveyPlayerView` (question pager with progress bar, branching support)
- [ ] Implement `SingleChoiceView` (radio button list question renderer)
- [ ] Implement `MultiChoiceView` (checkbox multi-select question renderer)
- [ ] Implement `RatingScaleView` (star or 0–10 slider renderer)
- [ ] Implement `OpenTextView` (UITextView with character counter)
- [ ] Implement `RankingView` (drag-to-reorder with drag gesture)
- [ ] Implement `DailyPollView` (full-screen single question, instant reward on answer)
- [ ] Implement `SurveyCompletionView` (reward credited animation, balance update, next survey CTA)

### Rewards Views
- [ ] Implement `RewardsView` (balance display, payout CTA, earning history list, payout history list)
- [ ] Implement `PayoutFlowView` (method picker: PayPal/gift card, destination input, confirm, sent state)
- [ ] Implement `PayoutHistoryRow` (date, amount, method icon, status badge color-coded)
- [ ] Implement `EarningHistoryRow` (date, source type with color, amount, survey topic label)

### Stats Views
- [ ] Implement `StatsView` (lifetime earnings hero, metric tiles, premium-blurred section for free users)
- [ ] Implement `EarningsChartView` (Swift Charts bar chart, weekly data, premium-gated)
- [ ] Implement `QualificationRateView` (DQ rate trend, "improved X% this month")
- [ ] Implement `AchievementsView` (badge grid: unlocked color, locked grayscale + unlock condition)

### Profile Views
- [ ] Implement `ProfileView` (completion %, subscription status, settings list rows)
- [ ] Implement `EditProfileView` (editable demographics form, save button)
- [ ] Implement `NotificationPrefsView` (per-type toggles, quiet hours time pickers)
- [ ] Implement `PrivacySettingsView` (GDPR toggles, CCPA "Do Not Sell" toggle, data download, delete account)
- [ ] Implement `SubscriptionStatusView` (plan name, next renewal date, manage link to App Store settings)

### Paywall Views
- [ ] Implement `PaywallView` (header with crown, feature list, plan picker, purchase CTA, restore, legal)
- [ ] Implement `PlanPickerView` (3-card selector: Weekly $4 / Yearly $56 / Lifetime $92.80, best-value badge on yearly)
- [ ] Implement `FeatureBulletList` (animated checkmark list: priority queue, 1.5x multiplier, etc.)

### Shared Components
- [ ] Implement `PrimaryButton` (full-width, loading state, disabled state)
- [ ] Implement `LoadingOverlay` (semi-transparent background + ProgressView)
- [ ] Implement `ErrorBanner` (toast notification, auto-dismiss after 3 seconds)
- [ ] Implement `RewardCreditAnimation` (particle burst + balance counter increment)
- [ ] Implement `ProgressRingView` (circular progress for payout goal, percentage label)
- [ ] Implement `BadgeView` (achievement badge: icon + title + locked overlay)

### StoreKit & Paywall Integration
- [ ] Create all 4 products in App Store Connect:
  - `com.com.appfactory.rewardpulse.subscription.weekly` — Auto-Renewable, $4.00/week
  - `com.com.appfactory.rewardpulse.subscription.yearly` — Auto-Renewable, $56.00/year
  - `com.com.appfactory.rewardpulse.subscription.lifetime` — Non-Consumable (or Non-Renewing), $92.80
  - `com.com.appfactory.rewardpulse.iap.small_iap` — Consumable, $0.99
- [ ] Create "Premium" entitlement in RevenueCat dashboard
- [ ] Map all 4 products to entitlement in RevenueCat
- [ ] Implement StoreKit 2 `Transaction.updates` background listener (started at app launch)
- [ ] Test purchase flows in StoreKit sandbox (Xcode scheme → StoreKit config file)
- [ ] Verify `Restore Purchases` correctly re-gates/un-gates premium features
- [ ] Add paywall trigger from premium survey card tap
- [ ] Add paywall trigger from blurred Stats section tap
- [ ] Add paywall trigger from streak-break notification

### Analytics & Attribution
- [ ] Add `GoogleService-Info.plist` to project (from Firebase console)
- [ ] Verify all `AnalyticsEvent` cases fire at correct interaction points
- [ ] Test that Firebase DebugView shows events during development (launch argument `-FIRAnalyticsDebugEnabled`)
- [ ] Implement Facebook `AppEvents` mirroring in `AnalyticsService`
- [ ] Implement `AttributionService.resolveAttribution()` call after user consent
- [ ] Verify AdServices token is sent to backend and attribution resolves in Apple Search Ads dashboard
- [ ] Implement ATT pre-prompt education screen (`ATTPrePromptView`)
- [ ] Trigger ATT system prompt after user's first earning event (not at launch)
- [ ] Log `attAuthorized` / `attDenied` events to Firebase

### Notifications
- [ ] Request notification authorization during onboarding step 2
- [ ] Implement notification categories: `survey_available` with "Start Survey" action
- [ ] Schedule local daily poll reminder at user's preferred hour (default 8am)
- [ ] Schedule streak reminder: fire at 8pm if user hasn't had an earning action that day
- [ ] Handle notification tap routing in `AppRouter` (deep link to correct tab/view)
- [ ] Implement notification preference toggles in `NotificationPrefsView`
- [ ] Register for remote notifications (APNs) for server-sent survey alerts

### Assets & Branding
- [ ] Design and export AppIcon (1024×1024 PNG, no alpha channel, no rounded corners — App Store does that)
- [ ] Set `AccentColor` in Assets.xcassets (light and dark appearance)
- [ ] Create semantic color set: Background, Surface, PrimaryText, SecondaryText, Success (#34C759), Warning (#FF9500), Error (#FF3B30), StreakGold (#FFD60A)
- [ ] Add onboarding illustration assets (3 images for steps 1, 2, 5)
- [ ] Add 9 achievement badge icons (SF Symbols acceptable for v1)
- [ ] Add survey category icons (SF Symbols mapped per `SurveyCategory` enum)
- [ ] Add empty state illustrations for: empty survey queue, empty earnings history

### Polish & Compliance
- [ ] Add accessibility labels to all interactive elements (buttons, cards, toggles)
- [ ] Add accessibility hints where action is non-obvious
- [ ] Verify Dynamic Type scaling on all text (use `.font(.body)` and text styles, not fixed sizes)
- [ ] Verify dark mode on all screens (use semantic colors only — no hardcoded hex)
- [ ] Add haptic feedback: `.reward` on survey completion, `.success` on payout, `.light` on daily poll answer
- [ ] Implement keyboard dismissal on all form screens (`.scrollDismissesKeyboard(.interactively)`)
- [ ] Add `Reduce Motion` check before playing balance animation (`@Environment(\.accessibilityReduceMotion)`)
- [ ] Verify minimum tap target size 44×44pt on all interactive elements
- [ ] Implement offline detection: disable Redeem button when offline, show explanatory message
- [ ] Verify survey response queue-and-retry when offline
- [ ] Add CCPA "Do Not Sell or Share My Personal Information" toggle in PrivacySettingsView
- [ ] Implement in-app account deletion flow (Guideline 5.1.1): confirm dialog → server delete → local SwiftData purge → Keychain clear → sign out
- [ ] Add App Store Review test account credentials to App Review notes
- [ ] Write App Review notes explaining payout architecture and subscription value
- [ ] Write README.md covering: setup, SPM dependencies, environment config, backend requirements, testing

---

*Plan version 1.0 | Based on RewardPulse competitive research (June 2026)*
*Primary differentiators vs. Google Opinion Rewards: AI DQ prediction, daily engagement loop (poll + streak + check-in), partial DQ pay (first to market), premium subscription tier, earnings transparency dashboard*
