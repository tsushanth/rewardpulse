import SwiftUI
import SwiftData

@MainActor
final class SurveyViewModel: ObservableObject {
    @Published var survey: Survey
    @Published var currentQuestionIndex: Int = 0
    @Published var answers: [QuestionAnswer] = []
    @Published var isSubmitting = false
    @Published var outcome: ResponseOutcome = .inProgress
    @Published var rewardCredited: Int = 0
    @Published var showCompletionAnimation = false
    @Published var errorMessage: String?

    private let apiService: APIService
    private let analyticsService: AnalyticsService
    private let haptics: HapticManager

    var currentQuestion: SurveyQuestion? {
        guard currentQuestionIndex < survey.questions.count else { return nil }
        return survey.questions[currentQuestionIndex]
    }

    var progress: Double {
        guard !survey.questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(survey.questions.count)
    }

    var isLastQuestion: Bool {
        guard !survey.questions.isEmpty else { return true }
        return currentQuestionIndex == survey.questions.count - 1
    }

    init(survey: Survey,
         apiService: APIService = .shared,
         analyticsService: AnalyticsService = .shared,
         haptics: HapticManager = .shared) {
        self.survey = survey
        self.apiService = apiService
        self.analyticsService = analyticsService
        self.haptics = haptics
    }

    func submitAnswer(_ answer: QuestionAnswer) {
        if let branch = currentQuestion?.branchingRules
            .first(where: { $0.ifAnswerIndex == answer.selectedIndices.first }) {
            if branch.thenSkipToQuestionId == "END" {
                answers.append(answer)
                Task { await submitSurvey(early: true) }
                return
            }
            let targetIndex = survey.questions.firstIndex { $0.id == branch.thenSkipToQuestionId }
            answers.append(answer)
            if let index = targetIndex {
                currentQuestionIndex = index
            }
            return
        }
        answers.append(answer)

        if isLastQuestion {
            Task { await submitSurvey(early: false) }
        } else {
            currentQuestionIndex += 1
        }
    }

    func submitSurvey(early: Bool) async {
        isSubmitting = true
        analyticsService.log(.surveySubmitted(id: survey.id, questionCount: answers.count))

        do {
            let result = try await apiService.submitSurvey(id: survey.id, answers: answers)
            outcome = result.outcome
            rewardCredited = result.rewardCents

            if result.outcome == .completed {
                haptics.trigger(.reward)
                showCompletionAnimation = true
                analyticsService.log(.rewardEarned(cents: result.rewardCents, source: "survey"))
            } else if result.outcome == .disqualified {
                haptics.trigger(.light)
                analyticsService.log(.surveyDisqualified(id: survey.id))
                rewardCredited = result.dqPartialCreditCents
            }
        } catch {
            errorMessage = "Failed to submit survey. Your answers are saved."
        }
        isSubmitting = false
    }

    func goToPreviousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        answers.removeLast()
        currentQuestionIndex -= 1
    }
}
