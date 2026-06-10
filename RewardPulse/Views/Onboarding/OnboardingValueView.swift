import SwiftUI

struct OnboardingValueView: View {
    let onContinue: () -> Void

    private let features = [
        ("dollarsign.circle.fill", "Earn $0.50–$2.00 per survey", "Real cash paid to PayPal"),
        ("chart.bar.fill", "AI-powered matching", "Higher qualification rate than competitors"),
        ("flame.fill", "Daily streaks & bonuses", "Earn more the more you engage"),
        ("hand.thumbsup.fill", "Partial pay on disqualification", "You earn even when DQ'd — first in market")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 24)
                .accessibilityHidden(true)

            Text("Get Paid for Your Opinion")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            Text("Earn real money by completing surveys. No points, no gift card hassle — just cash.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 20) {
                ForEach(features, id: \.0) { icon, title, subtitle in
                    HStack(spacing: 16) {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            PrimaryButton(title: "Get Started", isLoading: false, action: onContinue)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .accessibilityHint("Proceeds to notification setup")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}
