import SwiftUI

struct SurveyCompletionView: View {
    let outcome: ResponseOutcome
    let rewardCents: Int
    let onDismiss: () -> Void

    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var rewardFormatted: String { String(format: "$%.2f", Double(rewardCents) / 100.0) }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill((outcome == .completed ? Color.green : Color.orange).opacity(0.12))
                    .frame(width: 120, height: 120)
                    .scaleEffect(reduceMotion ? 1 : (animate ? 1 : 0.5))

                Image(systemName: outcome == .completed ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(outcome == .completed ? .green : .orange)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(outcome == .completed ? "Survey Complete!" : "You were disqualified")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                if outcome == .completed {
                    Text("\(rewardFormatted) has been credited to your balance.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    if rewardCents > 0 {
                        Text("You still earned \(rewardFormatted) as a partial credit — thanks for your time!")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("You weren't a match for this survey. Keep going — more surveys are available!")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, 32)
            .accessibilityElement(children: .combine)

            if rewardCents > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text(rewardFormatted)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                }
                .scaleEffect(reduceMotion ? 1 : (animate ? 1 : 0.5))
                .accessibilityLabel("Reward: \(rewardFormatted)")
            }

            Spacer()

            PrimaryButton(title: "Back to Surveys", isLoading: false, action: onDismiss)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                animate = true
            }
        }
    }
}
