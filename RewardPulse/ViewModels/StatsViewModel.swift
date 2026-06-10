import SwiftUI
import SwiftData

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var lifetimeEarningsCents: Int = 0
    @Published var totalSurveysCompleted: Int = 0
    @Published var qualificationRatePct: Int = 0
    @Published var avgRewardPerSurveyCents: Int = 0
    @Published var effectiveHourlyRateCents: Int = 0
    @Published var annualProjectionCents: Int = 0
    @Published var weeklyEarningsData: [(Date, Int)] = []
    @Published var achievements: [Achievement] = []
    @Published var isPremium = false
    @Published var isLoading = false

    var earnerPercentile: Int = 0

    var canSeeFullStats: Bool { isPremium }

    var projectionDescription: String {
        let dollars = Double(annualProjectionCents) / 100.0
        return String(format: "At your current pace, you'll earn $%.0f this year.", dollars)
    }

    var hourlyRateDescription: String {
        let rate = Double(effectiveHourlyRateCents) / 100.0
        return String(format: "You earn $%.2f/hour across your survey history.", rate)
    }

    var lifetimeEarningsFormatted: String {
        String(format: "$%.2f", Double(lifetimeEarningsCents) / 100.0)
    }

    var avgRewardFormatted: String {
        String(format: "$%.2f", Double(avgRewardPerSurveyCents) / 100.0)
    }

    func onAppear(context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        isPremium = await RevenueCatService.shared.isEntitled
        AnalyticsService.shared.log(.screenView(name: "stats"))

        let earningDescriptor = FetchDescriptor<EarningEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let events = (try? context.fetch(earningDescriptor)) ?? []

        let surveyEarnings = events.filter { $0.source == .survey }
        lifetimeEarningsCents = events.reduce(0) { $0 + $1.amountCents }
        totalSurveysCompleted = surveyEarnings.count
        avgRewardPerSurveyCents = totalSurveysCompleted > 0
            ? lifetimeEarningsCents / totalSurveysCompleted : 0

        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? context.fetch(profileDescriptor).first {
            let total = profile.totalSurveysCompleted + profile.totalSurveysDisqualified
            qualificationRatePct = total > 0
                ? Int((Double(profile.totalSurveysCompleted) / Double(total)) * 100) : 0
        }

        buildWeeklyEarningsData(events: events)
        computeProjection()

        let achievementDescriptor = FetchDescriptor<Achievement>()
        achievements = (try? context.fetch(achievementDescriptor)) ?? []
    }

    private func buildWeeklyEarningsData(events: [EarningEvent]) {
        let calendar = Calendar.current
        var result: [(Date, Int)] = []
        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            let dayTotal = events
                .filter { $0.createdAt >= start && $0.createdAt < end }
                .reduce(0) { $0 + $1.amountCents }
            result.append((start, dayTotal))
        }
        weeklyEarningsData = result
    }

    private func computeProjection() {
        let dailyAvg = weeklyEarningsData.reduce(0) { $0 + $1.1 } / max(weeklyEarningsData.count, 1)
        annualProjectionCents = dailyAvg * 365
    }
}
