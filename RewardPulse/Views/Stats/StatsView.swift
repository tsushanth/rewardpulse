import SwiftUI
import SwiftData

struct StatsView: View {
    @StateObject private var vm = StatsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showPaywall) private var showPaywall

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Lifetime Earnings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(vm.lifetimeEarningsFormatted)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.accentColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
                .accessibilityLabel("Lifetime earnings: \(vm.lifetimeEarningsFormatted)")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metricTile("Surveys Completed", "\(vm.totalSurveysCompleted)", "doc.text.fill", .accentColor)
                    metricTile("Avg per Survey", vm.avgRewardFormatted, "chart.bar.fill", .green)
                }

                // Full analytics section header
                HStack {
                    Text("Advanced Analytics")
                        .font(.headline)
                    ProBadgeView()
                    Spacer()
                }
                .padding(.horizontal, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Advanced Analytics — Premium feature")

                if vm.canSeeFullStats {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(vm.hourlyRateDescription)
                                .font(.subheadline.weight(.medium))
                            Text(vm.projectionDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))

                        EarningsChartView(data: vm.weeklyEarningsData)
                    }
                } else {
                    premiumBlurredSection
                }

                QualificationRateView(
                    qualificationRatePct: vm.qualificationRatePct,
                    totalCompleted: vm.totalSurveysCompleted,
                    totalDisqualified: max(0, vm.totalSurveysCompleted > 0
                        ? Int(Double(vm.totalSurveysCompleted) * (1 - Double(vm.qualificationRatePct) / 100))
                        : 0)
                )

                AchievementsView(achievements: vm.achievements)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
        .task { await vm.onAppear(context: modelContext) }
        .loadingOverlay(vm.isLoading)
    }

    private var premiumBlurredSection: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("$12.50/hour")
                    .font(.subheadline.weight(.medium))
                Text("On track to earn $820 this year")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
            .blur(radius: 8)

            Button(action: { showPaywall.wrappedValue = true }) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text("Unlock Full Stats")
                        .font(.subheadline.weight(.semibold))
                    Text("Upgrade to Premium")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
            }
            .accessibilityLabel("Unlock full stats — Upgrade to Premium")
            .accessibilityHint("Opens the paywall")
        }
    }

    private func metricTile(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
