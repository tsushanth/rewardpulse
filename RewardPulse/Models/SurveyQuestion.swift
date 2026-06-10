import SwiftData
import Foundation

@Model
final class SurveyQuestion {
    var id: String
    var questionText: String
    var questionType: QuestionType
    var options: [String]
    var required: Bool
    var sortOrder: Int
    var branchingRules: [BranchingRule]

    init(id: String, text: String, type: QuestionType, sortOrder: Int) {
        self.id = id
        self.questionText = text
        self.questionType = type
        self.options = []
        self.required = true
        self.sortOrder = sortOrder
        self.branchingRules = []
    }
}

enum QuestionType: String, Codable {
    case singleChoice, multiChoice, ratingScale, openText, ranking, imageChoice, matrix
}

struct BranchingRule: Codable {
    var ifAnswerIndex: Int
    var thenSkipToQuestionId: String
}
