import SwiftUI

struct SurveyDetailView: View {
    let survey: Survey
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(survey.categoryTag.displayName, systemImage: survey.categoryTag.iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(survey.title)
                        .font(.title2.bold())
                }

                HStack(spacing: 0) {
                    metricTile("Reward", survey.rewardFormatted, "dollarsign.circle.fill", .green)
                    Divider().frame(height: 50)
                    metricTile("Duration", "~\(survey.estimatedMinutes) min", "clock", .secondary)
                    if let match = survey.matchScore {
                        Divider().frame(height: 50)
                        metricTile("Match", "\(match)%", "checkmark.seal.fill", match > 70 ? .green : .orange)
                    }
                }
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 12) {
                    Text("About This Survey")
                        .font(.headline)
                    Text("Complete all questions to receive the full reward. If you're disqualified, you'll still earn a \(String(format: "$%.2f", Double(Constants.dqPartialCreditCents) / 100.0)) partial credit.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if survey.isPremiumOnly {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        Text("This is a premium-exclusive survey with higher payouts. Upgrade to access it.")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let dqRate = survey.disqualificationRatePct {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("\(dqRate)% of people are disqualified from this survey.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(survey.timeRemainingDescription)
                    .font(.caption)
                    .foregroundStyle(survey.isExpired ? .red : .secondary)
            }
            .padding()
        }
        .navigationTitle("Survey Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: survey.isExpired ? "Survey Expired" : "Start Survey",
                isLoading: false,
                isDisabled: survey.isExpired,
                action: onStart
            )
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    private func metricTile(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.subheadline.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
