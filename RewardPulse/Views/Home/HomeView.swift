import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: AppRouter
    @Environment(\.showPaywall) private var showPaywall

    @State private var showDailyPoll = false
    @State private var showPayoutFlow = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BalanceSummaryView(
                    balanceCents: vm.balanceCents,
                    minimumPayoutCents: vm.minimumPayoutCents,
                    onRedeemTap: { showPayoutFlow = true }
                )

                if vm.streakDays > 0 {
                    StreakBannerView(
                        days: vm.streakDays,
                        multiplier: vm.streakMultiplier,
                        insuranceAvailable: vm.streakInsuranceAvailable
                    )
                }

                QuickDailyPollCard(
                    poll: vm.todaysPoll,
                    onTap: { showDailyPoll = true }
                )

                if vm.activeSurveyCount > 0 {
                    Button {
                        router.selectedTab = 1
                    } label: {
                        HStack {
                            Label("\(vm.activeSurveyCount) surveys available", systemImage: "doc.text.fill")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding(16)
                        .background(Color.accentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(vm.activeSurveyCount) surveys available. Tap to view them.")
                    .accessibilityHint("Switches to Earn tab")
                }

                if !vm.recentEarnings.isEmpty {
                    RecentEarningsSection(events: vm.recentEarnings)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("RewardPulse")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await vm.refresh() }
        .task {
            await vm.onAppear()
            vm.loadRecentEarnings(context: modelContext)
        }
        .loadingOverlay(vm.isLoading)
        .errorBanner($vm.errorMessage)
        .sheet(isPresented: $showDailyPoll) {
            if let poll = vm.todaysPoll {
                DailyPollView(poll: poll) {
                    showDailyPoll = false
                    Task { await vm.refresh() }
                }
            }
        }
        .sheet(isPresented: $showPayoutFlow) {
            PayoutFlowView()
        }
    }
}

private struct RecentEarningsSection: View {
    let events: [EarningEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Earnings")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(events) { event in
                EarningHistoryRow(event: event)
            }
        }
    }
}
