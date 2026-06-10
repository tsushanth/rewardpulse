import SwiftUI
import SwiftData

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
    @Published var errorMessage: String?

    private let apiService: APIService
    private let analyticsService: AnalyticsService
    private let rcService: RevenueCatService

    init(apiService: APIService = .shared,
         analyticsService: AnalyticsService = .shared,
         rcService: RevenueCatService = .shared) {
        self.apiService = apiService
        self.analyticsService = analyticsService
        self.rcService = rcService
    }

    func onAppear() async {
        isLoading = true
        defer { isLoading = false }

        minimumPayoutCents = rcService.isEntitled ? Constants.premiumPayoutThresholdCents : Constants.freePayoutThresholdCents

        async let balance = apiService.fetchBalance()
        async let streak  = apiService.fetchStreak()
        async let polls   = apiService.fetchDailyPoll()
        async let surveys = apiService.fetchSurveyCount()

        balanceCents       = (try? await balance) ?? balanceCents
        let streakData      = try? await streak
        streakDays          = streakData?.currentStreak ?? streakDays
        streakMultiplier    = streakData?.currentMultiplier ?? streakMultiplier
        streakInsuranceAvailable = streakData?.streakInsuranceAvailable ?? false
        todaysPoll          = try? await polls
        activeSurveyCount   = (try? await surveys) ?? activeSurveyCount

        analyticsService.log(.screenView(name: "home"))
        await triggerStreakCheckIn()
    }

    func refresh() async { await onAppear() }

    func loadRecentEarnings(context: ModelContext) {
        let descriptor = FetchDescriptor<EarningEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allEvents = (try? context.fetch(descriptor)) ?? []
        recentEarnings = Array(allEvents.prefix(3))
    }

    private func triggerStreakCheckIn() async {
        try? await apiService.recordDailyCheckIn()
    }
}
