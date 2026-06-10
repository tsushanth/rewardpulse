import SwiftData
import Foundation

@Model
final class DailyPoll {
    var id: String
    var questionText: String
    var options: [String]
    var category: String
    var rewardCents: Int
    var availableDate: Date
    var expiresAt: Date
    var userAnswerIndex: Int?
    var answeredAt: Date?
    var resultDistribution: [Int]?

    init(id: String, questionText: String, options: [String],
         category: String, rewardCents: Int, availableDate: Date, expiresAt: Date) {
        self.id = id
        self.questionText = questionText
        self.options = options
        self.category = category
        self.rewardCents = rewardCents
        self.availableDate = availableDate
        self.expiresAt = expiresAt
    }

    var isAnswered: Bool { userAnswerIndex != nil }
    var isAvailableToday: Bool {
        Calendar.current.isDate(availableDate, inSameDayAs: .now) && !isAnswered
    }
    var rewardFormatted: String { String(format: "$%.2f", Double(rewardCents) / 100.0) }
}
