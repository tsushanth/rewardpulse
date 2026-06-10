import Foundation

struct SurveyResult {
    let outcome: ResponseOutcome
    let rewardCents: Int
    let dqPartialCreditCents: Int
}

struct ProfileUpdates: Codable {
    var displayName: String?
    var birthYear: Int?
    var gender: String?
    var postalCode: String?
    var householdSize: Int?
    var employmentStatus: String?
    var annualIncomeRange: String?
    var educationLevel: String?
    var interestCategories: [String]?
    var preferredPayoutMethod: String?
}

final class APIService {
    static let shared = APIService()
    private init() {}

    private var baseURL: URL { URL(string: Constants.apiBaseURL)! }
    private var session: URLSession { .shared }

    private func authorizedRequest(path: String, method: String = "GET") async throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = try? KeychainService.load(.sessionToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    func fetchBalance() async throws -> Int {
        let request = try await authorizedRequest(path: "balance")
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode([String: Int].self, from: data)
        return response["balance_cents"] ?? 0
    }

    func fetchStreak() async throws -> StreakRecord {
        let request = try await authorizedRequest(path: "streak")
        let (data, _) = try await session.data(for: request)
        let dto = try JSONDecoder().decode(StreakDTO.self, from: data)
        let record = StreakRecord()
        record.currentStreak = dto.currentStreak
        record.longestStreak = dto.longestStreak
        record.streakInsuranceAvailable = dto.insuranceAvailable
        return record
    }

    func fetchDailyPoll() async throws -> DailyPoll {
        let request = try await authorizedRequest(path: "daily-poll")
        let (data, _) = try await session.data(for: request)
        let dto = try JSONDecoder().decode(DailyPollDTO.self, from: data)
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        return DailyPoll(
            id: dto.id,
            questionText: dto.questionText,
            options: dto.options,
            category: dto.category,
            rewardCents: dto.rewardCents,
            availableDate: start,
            expiresAt: end
        )
    }

    func fetchSurveyCount() async throws -> Int {
        let request = try await authorizedRequest(path: "surveys/count")
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode([String: Int].self, from: data)
        return response["count"] ?? 0
    }

    func fetchSurveys() async throws -> [Survey] {
        let request = try await authorizedRequest(path: "surveys")
        let (data, _) = try await session.data(for: request)
        let dtos = try JSONDecoder().decode([SurveyDTO].self, from: data)
        return dtos.map { dto in
            let survey = Survey(
                id: dto.id,
                title: dto.title,
                category: SurveyCategory(rawValue: dto.category) ?? .general,
                estimatedMinutes: dto.estimatedMinutes,
                rewardCents: dto.rewardCents,
                expiresAt: dto.expiresAt
            )
            survey.matchScore = dto.matchScore
            survey.disqualificationRatePct = dto.disqualificationRatePct
            survey.isPremiumOnly = dto.isPremiumOnly
            return survey
        }
    }

    func submitSurvey(id: String, answers: [QuestionAnswer]) async throws -> SurveyResult {
        var request = try await authorizedRequest(path: "surveys/\(id)/submit", method: "POST")
        let body = SurveySubmitBody(surveyId: id, answers: answers)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(SurveySubmitResponse.self, from: data)
        return SurveyResult(
            outcome: ResponseOutcome(rawValue: response.outcome) ?? .completed,
            rewardCents: response.rewardCents,
            dqPartialCreditCents: response.dqPartialCreditCents
        )
    }

    func recordDailyCheckIn() async throws {
        var request = try await authorizedRequest(path: "check-in", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])
        _ = try await session.data(for: request)
    }

    func answerDailyPoll(id: String, answerIndex: Int) async throws -> [Int] {
        var request = try await authorizedRequest(path: "daily-poll/\(id)/answer", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["answer_index": answerIndex])
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode([String: [Int]].self, from: data)
        return response["distribution"] ?? []
    }

    func initiatePayoutRequest(amountCents: Int, method: PayoutMethod, destination: String) async throws {
        var request = try await authorizedRequest(path: "payouts", method: "POST")
        let body: [String: String] = [
            "amount_cents": String(amountCents),
            "method": method.rawValue,
            "destination": destination
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await session.data(for: request)
    }

    func updateProfile(_ updates: ProfileUpdates) async throws {
        var request = try await authorizedRequest(path: "profile", method: "PATCH")
        request.httpBody = try JSONEncoder().encode(updates)
        _ = try await session.data(for: request)
    }

    func submitAttributionToken(_ token: String) async throws {
        var request = try await authorizedRequest(path: "attribution", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["token": token])
        _ = try await session.data(for: request)
    }

    func deleteAccount() async throws {
        let request = try await authorizedRequest(path: "account", method: "DELETE")
        _ = try await session.data(for: request)
    }
}

// MARK: - DTOs

private struct StreakDTO: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let insuranceAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case insuranceAvailable = "insurance_available"
    }
}

private struct DailyPollDTO: Codable {
    let id: String
    let questionText: String
    let options: [String]
    let category: String
    let rewardCents: Int

    enum CodingKeys: String, CodingKey {
        case id
        case questionText = "question_text"
        case options
        case category
        case rewardCents = "reward_cents"
    }
}

private struct SurveyDTO: Codable {
    let id: String
    let title: String
    let category: String
    let estimatedMinutes: Int
    let rewardCents: Int
    let expiresAt: Date
    let matchScore: Int?
    let disqualificationRatePct: Int?
    let isPremiumOnly: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, category
        case estimatedMinutes = "estimated_minutes"
        case rewardCents = "reward_cents"
        case expiresAt = "expires_at"
        case matchScore = "match_score"
        case disqualificationRatePct = "disqualification_rate_pct"
        case isPremiumOnly = "is_premium_only"
    }
}

private struct SurveySubmitBody: Codable {
    let surveyId: String
    let answers: [QuestionAnswer]

    enum CodingKeys: String, CodingKey {
        case surveyId = "survey_id"
        case answers
    }
}

private struct SurveySubmitResponse: Codable {
    let outcome: String
    let rewardCents: Int
    let dqPartialCreditCents: Int

    enum CodingKeys: String, CodingKey {
        case outcome
        case rewardCents = "reward_cents"
        case dqPartialCreditCents = "dq_partial_credit_cents"
    }
}
