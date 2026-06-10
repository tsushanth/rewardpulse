import SwiftUI

struct QuickDailyPollCard: View {
    let poll: DailyPoll?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: poll?.isAnswered == true
                          ? "checkmark.circle.fill" : "questionmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(poll?.isAnswered == true ? .green : .purple)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let poll {
                        if poll.isAnswered {
                            Text("Daily Poll Complete")
                                .font(.subheadline.weight(.semibold))
                            Text("You've answered today's question")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Daily Poll")
                                .font(.subheadline.weight(.semibold))
                            Text(poll.questionText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    } else {
                        Text("Daily Poll")
                            .font(.subheadline.weight(.semibold))
                        Text("Loading today's question…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let poll, !poll.isAnswered {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(poll.rewardFormatted)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.green)
                        Text("reward")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(poll?.isAnswered == true
                            ? "Daily poll complete"
                            : "Daily poll: \(poll?.questionText ?? "Loading"). Earn \(poll?.rewardFormatted ?? "")")
        .accessibilityHint(poll?.isAnswered == true ? "" : "Tap to answer and earn a reward")
    }
}
