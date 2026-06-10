import SwiftUI

struct SingleChoiceView: View {
    let question: SurveyQuestion
    let onAnswer: (QuestionAnswer) -> Void

    @State private var selectedIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.questionText)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button(action: { selectOption(index) }) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .stroke(selectedIndex == index ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                if selectedIndex == index {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 14, height: 14)
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
                        .background(selectedIndex == index
                                    ? Color.accentColor.opacity(0.08)
                                    : Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedIndex == index ? Color.accentColor : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: Constants.minTapTarget)
                    .accessibilityLabel(option)
                    .accessibilityAddTraits(selectedIndex == index ? .isSelected : [])
                    .accessibilityHint("Selects this answer")
                }
            }

            if selectedIndex != nil {
                PrimaryButton(title: "Continue", isLoading: false) {
                    guard let idx = selectedIndex else { return }
                    let answer = QuestionAnswer(
                        questionId: question.id,
                        selectedIndices: [idx],
                        answeredAt: .now
                    )
                    HapticManager.shared.trigger(.light)
                    onAnswer(answer)
                }
            }
        }
    }

    private func selectOption(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedIndex = index
        }
        HapticManager.shared.trigger(.light)
    }
}
