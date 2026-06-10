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
            PaywallView()
        }
        .environment(\.showPaywall, $showPaywall)
    }
}
