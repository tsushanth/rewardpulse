import AdServices
import Foundation

actor AttributionService {
    static let shared = AttributionService()
    private init() {}

    private static let resolvedKey = "attribution_token_resolved"

    func fetchAttributionToken() async -> String? {
        do {
            return try AAAttribution.attributionToken()
        } catch {
            return nil
        }
    }

    /// Resolves the Apple Search Ads attribution token on first launch only.
    /// Subsequent calls are no-ops to avoid redundant network requests.
    func resolveAttribution() async {
        guard !UserDefaults.standard.bool(forKey: Self.resolvedKey) else { return }
        guard let token = await fetchAttributionToken() else { return }
        UserDefaults.standard.set(true, forKey: Self.resolvedKey)
        try? await APIService.shared.submitAttributionToken(token)
        AnalyticsService.shared.log(.featureUsed(name: "attribution_resolved"))
    }
}
