import SwiftUI

struct QualificationRateView: View {
    let qualificationRatePct: Int
    let totalCompleted: Int
    let totalDisqualified: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Qualification Rate")
                .font(.headline)

            HStack(spacing: 20) {
                ProgressRingView(
                    progress: Double(qualificationRatePct) / 100.0,
                    ringColor: qualificationRatePct >= 70 ? .green : (qualificationRatePct >= 50 ? .orange : .red),
                    lineWidth: 14,
                    showPercentage: true
                )
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 8) {
                    statItem("Completed", "\(totalCompleted)", .green)
                    statItem("Disqualified", "\(totalDisqualified)", .orange)
                    statItem("Total", "\(totalCompleted + totalDisqualified)", .secondary)
                }
            }

            if qualificationRatePct >= 70 {
                Label("Great qualification rate! You qualify for more surveys than average.", systemImage: "star.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            } else if qualificationRatePct >= 50 {
                Label("Complete your profile to improve your qualification rate.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
    }

    private func statItem(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
        }
    }
}
