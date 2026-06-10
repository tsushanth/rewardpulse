import SwiftData
import Foundation

@Model
final class SurveyResponse {
    var surveyId: String
    var startedAt: Date
    var submittedAt: Date?
    var answers: [QuestionAnswer]
    var currentQuestionIndex: Int
    var outcome: ResponseOutcome
    var dqPartialCreditCents: Int

    init(surveyId: String) {
        self.surveyId = surveyId
        self.startedAt = .now
        self.answers = []
        self.currentQuestionIndex = 0
        self.outcome = .inProgress
        self.dqPartialCreditCents = 0
    }
}

enum ResponseOutcome: String, Codable {
    case inProgress, completed, disqualified, abandoned
}

struct QuestionAnswer: Codable {
    var questionId: String
    var selectedIndices: [Int]
    var textAnswer: String?
    var ratingValue: Int?
    var rankedOrder: [Int]?
    var answeredAt: Date
}
