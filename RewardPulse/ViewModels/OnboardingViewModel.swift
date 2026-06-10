import SwiftUI
import SwiftData

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var displayName: String = ""
    @Published var birthYear: Int = Calendar.current.component(.year, from: .now) - 25
    @Published var gender: String = ""
    @Published var postalCode: String = ""
    @Published var householdSize: Int = 2
    @Published var employmentStatus: String = ""
    @Published var annualIncomeRange: String = ""
    @Published var educationLevel: String = ""
    @Published var selectedInterests: Set<String> = []
    @Published var isSaving = false
    @Published var welcomeBonusCredited = false
    @Published var onboardingComplete = false
    @Published var errorMessage: String?

    let totalSteps = 5

    var canProceedFromProfile: Bool {
        !gender.isEmpty && !employmentStatus.isEmpty
    }

    var profileCompletionScore: Int {
        var score = 0
        if !displayName.isEmpty          { score += 10 }
        if birthYear > 1900              { score += 15 }
        if !gender.isEmpty               { score += 10 }
        if !postalCode.isEmpty           { score += 10 }
        if householdSize > 0             { score += 5  }
        if !employmentStatus.isEmpty     { score += 15 }
        if !annualIncomeRange.isEmpty    { score += 15 }
        if !educationLevel.isEmpty       { score += 10 }
        if !selectedInterests.isEmpty    { score += 10 }
        return min(score, 100)
    }

    func advance() {
        guard currentStep < totalSteps - 1 else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentStep += 1
        }
    }

    func saveProfileAndCreditWelcomeBonus(context: ModelContext) async {
        isSaving = true
        defer { isSaving = false }

        let age = Calendar.current.component(.year, from: .now) - birthYear
        guard age >= Constants.minimumAgeYears else {
            errorMessage = "You must be 18 or older to use RewardPulse."
            return
        }

        let profile = UserProfile(id: UUID().uuidString, countryCode: Locale.current.region?.identifier ?? "US")
        profile.displayName = displayName.isEmpty ? nil : displayName
        profile.birthYear = birthYear
        profile.gender = gender
        profile.postalCode = postalCode.isEmpty ? nil : postalCode
        profile.householdSize = householdSize
        profile.employmentStatus = employmentStatus
        profile.annualIncomeRange = annualIncomeRange.isEmpty ? nil : annualIncomeRange
        profile.educationLevel = educationLevel.isEmpty ? nil : educationLevel
        profile.interestCategories = Array(selectedInterests)
        profile.profileCompletionScore = profileCompletionScore
        profile.onboardingCompleted = true
        profile.lifetimeEarningsCents = Constants.welcomeBonusCents

        context.insert(profile)
        try? context.save()

        let welcomeEvent = EarningEvent(amountCents: Constants.welcomeBonusCents, source: .welcomeBonus)
        welcomeEvent.eventDescription = "Welcome to RewardPulse!"
        context.insert(welcomeEvent)
        try? context.save()

        welcomeBonusCredited = true

        let updates = ProfileUpdates(
            displayName: displayName.isEmpty ? nil : displayName,
            birthYear: birthYear,
            gender: gender.isEmpty ? nil : gender,
            postalCode: postalCode.isEmpty ? nil : postalCode,
            householdSize: householdSize,
            employmentStatus: employmentStatus.isEmpty ? nil : employmentStatus,
            annualIncomeRange: annualIncomeRange.isEmpty ? nil : annualIncomeRange,
            educationLevel: educationLevel.isEmpty ? nil : educationLevel,
            interestCategories: Array(selectedInterests)
        )
        try? await APIService.shared.updateProfile(updates)
        AnalyticsService.shared.log(.profileUpdated)
    }

    func completeOnboarding() {
        withAnimation {
            onboardingComplete = true
        }
    }
}
