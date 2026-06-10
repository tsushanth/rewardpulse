import AdServices
import Foundation

actor AttributionService {
    static let shared = AttributionService()
    private init() {}

    func fetchAttributionToken() async -> String? {
        do {
            return try AAAttribution.attributionToken()
        } catch {
            return nil
        }
    }

    func resolveAttribution() async {
        guard let token = await fetchAttributionToken() else { return }
        try? await APIService.shared.submitAttributionToken(token)
        AnalyticsService.shared.log(.screenView(name: "attribution_resolved"))
    }
}
