import SwiftUI

struct OnboardingDashTourView: View {
    let onComplete: () -> Void

    @State private var tourStep = 0
    private let tourItems: [(String, String, String)] = [
        ("house.fill",               "Home Dashboard",    "See your balance, streak, and daily poll at a glance"),
        ("chart.bar.fill",           "Earn Tab",          "Browse your survey queue sorted by AI match score"),
        ("dollarsign.circle.fill",   "Rewards Tab",       "Track your balance and cash out via PayPal"),
        ("chart.xyaxis.line",        "Stats Tab",         "View your earnings history and performance metrics"),
        ("person.fill",              "Profile Tab",       "Manage your demographics to unlock better-paying surveys")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Here's Your Dashboard")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            Text("Let's take a quick tour")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)

            TabView(selection: $tourStep) {
                ForEach(Array(tourItems.enumerated()), id: \.offset) { index, item in
                    tourCard(icon: item.0, title: item.1, description: item.2)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 260)
            .padding(.bottom, 32)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(
                    title: tourStep < tourItems.count - 1 ? "Next" : "Start Earning",
                    isLoading: false
                ) {
                    if tourStep < tourItems.count - 1 {
                        withAnimation {
                            tourStep += 1
                        }
                    } else {
                        onComplete()
                    }
                }
                .accessibilityHint(tourStep < tourItems.count - 1 ? "Advance to next tour item" : "Complete onboarding and open the app")

                if tourStep < tourItems.count - 1 {
                    Button("Skip Tour") { onComplete() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Skip the tour and start the app")
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private func tourCard(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text(title)
                .font(.title2.bold())

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}
