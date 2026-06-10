import SwiftUI
import SwiftData

@main
struct RewardPulseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let container: DIContainer
    let modelContainer: ModelContainer

    @State private var showOnboarding = true

    init() {
        container = DIContainer.shared
        let schema = Schema([
            UserProfile.self,
            Survey.self,
            SurveyQuestion.self,
            SurveyResponse.self,
            EarningEvent.self,
            DailyPoll.self,
            StreakRecord.self,
            Achievement.self,
            PayoutRequest.self,
            NotificationPreference.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try! ModelContainer(for: schema, configurations: config)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingContainerView()
                        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                } else {
                    MainTabView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showOnboarding)
            .modelContainer(modelContainer)
            .environmentObject(container)
            .environmentObject(AppRouter.shared)
            .task { await bootstrap() }
            .onReceive(NotificationCenter.default.publisher(for: .premiumStatusDidChange)) { note in
                guard let isPremium = note.userInfo?["isPremium"] as? Bool else { return }
                let context = modelContainer.mainContext
                PremiumManager.shared.syncToProfile(isPremium: isPremium, context: context)
            }
        }
    }

    @MainActor
    private func bootstrap() async {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try? context.fetch(descriptor)
        showOnboarding = profiles?.first?.onboardingCompleted != true

        // Check persisted entitlements (fast — reads UserDefaults first, then App Store)
        await StoreKitManager.shared.checkCurrentEntitlements()

        // Load products in background so paywall renders immediately
        Task {
            await StoreKitManager.shared.loadProducts()
        }
    }
}
