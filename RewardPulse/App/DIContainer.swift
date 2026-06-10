import SwiftUI
import Foundation

final class DIContainer: ObservableObject {
    static let shared = DIContainer()

    let apiService: APIService
    let authService: AuthService
    let storeKitService: StoreKitService
    let storeKitManager: StoreKitManager
    let premiumManager: PremiumManager
    let analyticsService: AnalyticsService
    let notificationService: NotificationService
    let attributionService: AttributionService
    let hapticManager: HapticManager

    private init() {
        self.apiService = APIService.shared
        self.authService = AuthService.shared
        self.storeKitService = StoreKitService.shared
        self.storeKitManager = StoreKitManager.shared
        self.premiumManager = PremiumManager.shared
        self.analyticsService = AnalyticsService.shared
        self.notificationService = NotificationService.shared
        self.attributionService = AttributionService.shared
        self.hapticManager = HapticManager.shared
    }
}
