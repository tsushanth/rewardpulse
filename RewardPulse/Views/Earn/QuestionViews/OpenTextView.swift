import SwiftUI

struct OpenTextView: View {
    let question: SurveyQuestion
    let onAnswer: (QuestionAnswer) -> Void

    @State private var text = ""
    private let maxCharacters = 500

    var characterCountColor: Color {
        let remaining = maxCharacters - text.count
        if remaining < 20 { return .red }
        if remaining < 50 { return .orange }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.questionText)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Type your answer here…")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(.body)
                    .frame(minHeight: 140)
                    .padding(8)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxCharacters {
                            text = String(newValue.prefix(maxCharacters))
                        }
                    }
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .accessibilityLabel(question.questionText)

            HStack {
                if !question.required {
                    Text("Optional")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(text.count)/\(maxCharacters)")
                    .font(.caption)
                    .foregroundStyle(characterCountColor)
                    .accessibilityLabel("\(text.count) of \(maxCharacters) characters used")
            }

            PrimaryButton(
                title: text.isEmpty && !question.required ? "Skip" : "Continue",
                isLoading: false,
                isDisabled: text.isEmpty && question.required
            ) {
                let answer = QuestionAnswer(
                    questionId: question.id,
                    selectedIndices: [],
                    textAnswer: text.isEmpty ? nil : text,
                    answeredAt: .now
                )
                HapticManager.shared.trigger(.light)
                onAnswer(answer)
            }
        }
    }
}
