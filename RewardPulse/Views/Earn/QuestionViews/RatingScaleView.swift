import SwiftUI

struct RatingScaleView: View {
    let question: SurveyQuestion
    let onAnswer: (QuestionAnswer) -> Void

    @State private var rating: Int = 0
    private let maxRating = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(question.questionText)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(1...maxRating, id: \.self) { star in
                        Button(action: { selectRating(star) }) {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 40))
                                .foregroundStyle(star <= rating ? .yellow : Color.secondary.opacity(0.3))
                                .scaleEffect(star <= rating ? 1.1 : 1.0)
                                .animation(.spring(response: 0.25), value: rating)
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: Constants.minTapTarget, minHeight: Constants.minTapTarget)
                        .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                        .accessibilityAddTraits(star <= rating ? .isSelected : [])
                    }
                }
                .frame(maxWidth: .infinity)

                if rating > 0 {
                    Text(ratingLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .scale))
                }
            }

            if rating > 0 {
                PrimaryButton(title: "Continue", isLoading: false) {
                    let answer = QuestionAnswer(
                        questionId: question.id,
                        selectedIndices: [],
                        ratingValue: rating,
                        answeredAt: .now
                    )
                    HapticManager.shared.trigger(.light)
                    onAnswer(answer)
                }
            }
        }
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }

    private func selectRating(_ value: Int) {
        withAnimation(.spring(response: 0.3)) {
            rating = value
        }
        HapticManager.shared.trigger(.light)
    }
}
