import SwiftUI

struct RankingView: View {
    let question: SurveyQuestion
    let onAnswer: (QuestionAnswer) -> Void

    @State private var rankedItems: [String]

    init(question: SurveyQuestion, onAnswer: @escaping (QuestionAnswer) -> Void) {
        self.question = question
        self.onAnswer = onAnswer
        self._rankedItems = State(initialValue: question.options)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.questionText)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            Text("Drag to reorder from most to least preferred")
                .font(.caption)
                .foregroundStyle(.secondary)

            List {
                ForEach(Array(rankedItems.enumerated()), id: \.element) { index, item in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                            .accessibilityHidden(true)

                        Text(item)
                            .font(.body)

                        Spacer()

                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 4)
                    .frame(minHeight: Constants.minTapTarget)
                    .accessibilityLabel("Rank \(index + 1): \(item)")
                    .accessibilityHint("Drag to reorder")
                }
                .onMove { source, destination in
                    rankedItems.move(fromOffsets: source, toOffset: destination)
                    HapticManager.shared.trigger(.light)
                }
            }
            .listStyle(.plain)
            .frame(minHeight: CGFloat(rankedItems.count) * 60)
            .environment(\.editMode, .constant(.active))

            PrimaryButton(title: "Continue", isLoading: false) {
                let originalIndices = rankedItems.compactMap { item in
                    question.options.firstIndex(of: item)
                }
                let answer = QuestionAnswer(
                    questionId: question.id,
                    selectedIndices: [],
                    rankedOrder: originalIndices,
                    answeredAt: .now
                )
                HapticManager.shared.trigger(.light)
                onAnswer(answer)
            }
        }
    }
}
