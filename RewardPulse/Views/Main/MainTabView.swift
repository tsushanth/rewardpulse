import SwiftUI

private struct ShowPaywallKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var showPaywall: Binding<Bool> {
        get { self[ShowPaywallKey.self] }
        set { self[ShowPaywallKey.self] = newValue }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var showPaywall = false
    @State private var paywallSource: String = "generic"

    /// Key stored in UserDefaults after the post-onboarding paywall fires once.
    private static let postOnboardingPaywallKey = "com.rewardpulse.didShowOnboardingPaywall"

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                EarnView()
            }
            .tabItem { Label("Earn", systemImage: "chart.bar.fill") }
            .tag(1)

            NavigationStack {
                RewardsView()
            }
            .tabItem { Label("Rewards", systemImage: "dollarsign.circle.fill") }
            .tag(2)

            NavigationStack {
                StatsView()
            }
            .tabItem { Label("Stats", systemImage: "chart.xyaxis.line") }
            .tag(3)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(4)
        }
        .tint(.accentColor)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(source: paywallSource)
        }
        .environment(\.showPaywall, $showPaywall)
        .task { await triggerPostOnboardingPaywallIfNeeded() }
    }

    // MARK: - Post-Onboarding Paywall

    /// Shows the paywall once, ~1.5 s after the user first lands on the main tab view,
    /// but only if they haven't already purchased premium.
    @MainActor
    private func triggerPostOnboardingPaywallIfNeeded() async {
        let shown = UserDefaults.standard.bool(forKey: Self.postOnboardingPaywallKey)
        guard !shown, !StoreKitManager.shared.isPremium else { return }

        // Mark as shown immediately to guard against race conditions
        UserDefaults.standard.set(true, forKey: Self.postOnboardingPaywallKey)

        // Brief delay so the tab view transition can settle
        try? await Task.sleep(for: .milliseconds(1200))

        paywallSource = "post_onboarding"
        showPaywall = true
    }
}
