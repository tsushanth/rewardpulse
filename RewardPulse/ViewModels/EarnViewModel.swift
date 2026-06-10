import SwiftUI

@MainActor
final class EarnViewModel: ObservableObject {
    @Published var surveys: [Survey] = []
    @Published var todaysPoll: DailyPoll? = nil
    @Published var isLoading = false
    @Published var selectedSurvey: Survey? = nil
    @Published var navigateToSurvey = false
    @Published var showPremiumLock = false
    @Published var errorMessage: String?

    private let apiService: APIService
    private let rcService: RevenueCatService
    private let analyticsService: AnalyticsService

    var isPremium: Bool { rcService.isEntitled }

    var sortedSurveys: [Survey] {
        surveys
            .filter { !$0.isExpired && ($0.isPremiumOnly ? isPremium : true) }
            .sorted { ($0.matchScore ?? 0) > ($1.matchScore ?? 0) }
    }

    var lockedPremiumSurveys: [Survey] {
        guard !isPremium else { return [] }
        return surveys.filter { $0.isPremiumOnly && !$0.isExpired }
    }

    init(apiService: APIService = .shared,
         rcService: RevenueCatService = .shared,
         analyticsService: AnalyticsService = .shared) {
        self.apiService = apiService
        self.rcService = rcService
        self.analyticsService = analyticsService
    }

    func onAppear() async {
        isLoading = true
        async let surveyList = apiService.fetchSurveys()
        async let poll = apiService.fetchDailyPoll()
        surveys = (try? await surveyList) ?? surveys
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
