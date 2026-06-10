import SwiftUI

struct MultiChoiceView: View {
    let question: SurveyQuestion
    let onAnswer: (QuestionAnswer) -> Void

    @State private var selectedIndices: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.questionText)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            Text("Select all that apply")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button(action: { toggleOption(index) }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedIndices.contains(index) ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                if selectedIndices.contains(index) {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .accessibilityHidden(true)

                            Text(option)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(selectedIndices.contains(index)
                                    ? Color.accentColor.opacity(0.08)
                                    : Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedIndices.contains(index) ? Color.accentColor : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: Constants.minTapTarget)
                    .accessibilityLabel(option)
                    .accessibilityAddTraits(selectedIndices.contains(index) ? .isSelected : [])
                }
            }

            if !selectedIndices.isEmpty {
                PrimaryButton(title: "Continue (\(selectedIndices.count) selected)", isLoading: false) {
                    let answer = QuestionAnswer(
                        questionId: question.id,
                        selectedIndices: Array(selectedIndices).sorted(),
                        answeredAt: .now
                    )
                    HapticManager.shared.trigger(.light)
                    onAnswer(answer)
                }
            }
        }
    }

    private func toggleOption(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
        }
        HapticManager.shared.trigger(.light)
    }
}
