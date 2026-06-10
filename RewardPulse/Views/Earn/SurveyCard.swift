import SwiftUI

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
                        .accessibilityLabel("Premium survey")
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
                    .accessibilityLabel("Start \(survey.title)")
                    .accessibilityHint(survey.isExpired ? "Survey has expired" : "Starts this survey")
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .accessibilityElement(children: .contain)
    }
}
