import SwiftUI
import SwiftData

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var notificationPrefs: NotificationPreference?
    @Published var isSaving = false
    @Published var showDeleteConfirmation = false
    @Published var showPremiumStatus = false
    @Published var isDeleting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    var profileCompletionPct: Int { profile?.profileCompletionScore ?? 0 }
    var completionPrompt: String {
        if profileCompletionPct < 100 {
            return "Complete your profile to unlock more survey matches."
        }
        return "Your profile is fully complete."
    }

    func onAppear(context: ModelContext) {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        profile = try? context.fetch(profileDescriptor).first

        let notifDescriptor = FetchDescriptor<NotificationPreference>()
        if let existing = try? context.fetch(notifDescriptor).first {
            notificationPrefs = existing
        } else {
            let prefs = NotificationPreference()
            context.insert(prefs)
            try? context.save()
            notificationPrefs = prefs
        }
    }

    func saveProfile(updates: ProfileUpdates, context: ModelContext) async {
        isSaving = true
        defer { isSaving = false }

        if let profile {
            if let name = updates.displayName  { profile.displayName = name }
            if let year = updates.birthYear    { profile.birthYear = year }
            if let g    = updates.gender       { profile.gender = g }
            if let zip  = updates.postalCode   { profile.postalCode = zip }
            if let hs   = updates.householdSize { profile.householdSize = hs }
            if let emp  = updates.employmentStatus { profile.employmentStatus = emp }
            if let inc  = updates.annualIncomeRange { profile.annualIncomeRange = inc }
            if let edu  = updates.educationLevel { profile.educationLevel = edu }
            if let interests = updates.interestCategories { profile.interestCategories = interests }
            profile.updatedAt = .now
            profile.profileCompletionScore = computeScore(profile)
            try? context.save()
        }

        try? await APIService.shared.updateProfile(updates)
        AnalyticsService.shared.log(.profileUpdated)
        successMessage = "Profile saved."
    }

    func saveNotificationPrefs(context: ModelContext) {
        try? context.save()
    }

    func deleteAccount(context: ModelContext) async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await AuthService.shared.deleteAccount()

            let profileDescriptor = FetchDescriptor<UserProfile>()
            let profiles = try? context.fetch(profileDescriptor)
            profiles?.forEach { context.delete($0) }

            let earningDescriptor = FetchDescriptor<EarningEvent>()
            let events = try? context.fetch(earningDescriptor)
            events?.forEach { context.delete($0) }

            let payoutDescriptor = FetchDescriptor<PayoutRequest>()
            let payouts = try? context.fetch(payoutDescriptor)
            payouts?.forEach { context.delete($0) }

            try? context.save()
            KeychainService.delete(.sessionToken)
            KeychainService.delete(.paypalEmail)
            AnalyticsService.shared.log(.accountDeleted)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func computeScore(_ profile: UserProfile) -> Int {
        var score = 0
        if !(profile.displayName?.isEmpty ?? true)          { score += 10 }
        if profile.birthYear != nil                          { score += 15 }
        if !(profile.gender?.isEmpty ?? true)                { score += 10 }
        if !(profile.postalCode?.isEmpty ?? true)            { score += 10 }
        if profile.householdSize != nil                      { score += 5  }
        if !(profile.employmentStatus?.isEmpty ?? true)      { score += 15 }
        if !(profile.annualIncomeRange?.isEmpty ?? true)     { score += 15 }
        if !(profile.educationLevel?.isEmpty ?? true)        { score += 10 }
        if !profile.interestCategories.isEmpty               { score += 10 }
        return min(score, 100)
    }
}
