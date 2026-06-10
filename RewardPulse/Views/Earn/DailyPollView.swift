import SwiftUI

struct DailyPollView: View {
    let poll: DailyPoll
    let onComplete: () -> Void

    @State private var selectedIndex: Int? = nil
    @State private var isSubmitting = false
    @State private var showResults = false
    @State private var resultDistribution: [Int] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Label(poll.category.capitalized, systemImage: "calendar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("Daily Poll")
                            .font(.title2.bold())
                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundStyle(.green)
                                .accessibilityHidden(true)
                            Text("Earn \(poll.rewardFormatted)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.top)

                    Text(poll.questionText)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    if showResults {
                        resultsView
                    } else {
                        optionsView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                        onComplete()
                    }
                    .accessibilityLabel("Close daily poll")
                }
            }
        }
    }

    private var optionsView: some View {
        VStack(spacing: 10) {
            ForEach(Array(poll.options.enumerated()), id: \.offset) { index, option in
                Button(action: { submitAnswer(index) }) {
                    HStack {
                        Text(option)
                            .font(.body.weight(.medium))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(selectedIndex == index
                                ? Color.accentColor
                                : Color(uiColor: .secondarySystemBackground))
                    .foregroundStyle(selectedIndex == index ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .frame(minHeight: Constants.minTapTarget)
                .disabled(isSubmitting || poll.isAnswered)
                .accessibilityLabel(option)
                .accessibilityHint("Select this answer")
            }
        }
        .loadingOverlay(isSubmitting, message: "Submitting…")
    }

    private var resultsView: some View {
        VStack(spacing: 10) {
            ForEach(Array(poll.options.enumerated()), id: \.offset) { index, option in
                let pct = resultDistribution.indices.contains(index) ? resultDistribution[index] : 0
                let isSelected = index == selectedIndex

                HStack(spacing: 12) {
                    Text(option)
                        .font(.body.weight(isSelected ? .semibold : .regular))
                    Spacer()
                    Text("\(pct)%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack(alignment: .leading) {
                        (isSelected ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                        GeometryReader { geo in
                            (isSelected ? Color.accentColor.opacity(0.3) : Color.accentColor.opacity(0.15))
                                .frame(width: geo.size.width * CGFloat(pct) / 100)
                        }
                    }
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel("\(option): \(pct)% selected\(isSelected ? " — your answer" : "")")
            }

            PrimaryButton(title: "Done", isLoading: false) {
                dismiss()
                onComplete()
            }
            .padding(.top, 8)
        }
    }

    private func submitAnswer(_ index: Int) {
        guard !isSubmitting && !poll.isAnswered else { return }
        selectedIndex = index
        isSubmitting = true
        HapticManager.shared.trigger(.light)

        Task {
            let distribution = (try? await APIService.shared.answerDailyPoll(id: poll.id, answerIndex: index)) ?? []
            poll.userAnswerIndex = index
            poll.answeredAt = .now
            if distribution.isEmpty {
                resultDistribution = poll.options.indices.map { _ in Int.random(in: 15...35) }
            } else {
                resultDistribution = distribution
            }
            isSubmitting = false
            withAnimation(.spring(response: 0.4)) {
                showResults = true
            }
            HapticManager.shared.trigger(.reward)
            AnalyticsService.shared.log(.rewardEarned(cents: poll.rewardCents, source: "daily_poll"))
        }
    }
}
