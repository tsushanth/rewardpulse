import SwiftUI

struct OnboardingWelcomeView: View {
    let bonusCents: Int
    let onContinue: () -> Void

    @State private var animateBonus = false
    @State private var balanceScale: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var bonusFormatted: String { String(format: "$%.2f", Double(bonusCents) / 100.0) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)
            }
            .scaleEffect(reduceMotion ? 1 : (animateBonus ? 1 : 0.5))
            .accessibilityHidden(true)
            .padding(.bottom, 32)

            Text("Welcome to RewardPulse!")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            Text("Your profile is set up. Here's a welcome bonus to get you started:")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
                    .accessibilityHidden(true)
                Text(bonusFormatted)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .scaleEffect(reduceMotion ? 1 : balanceScale)
            }
            .accessibilityLabel("Welcome bonus: \(bonusFormatted) added to your balance")
            .padding(.bottom, 8)

            Text("credited to your balance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 14) {
                bonusTip("Complete surveys daily to build your streak")
                bonusTip("Answer today's daily poll for a quick \(String(format: "$%.2f", Double(Constants.dailyPollRewardCents) / 100.0))")
                bonusTip("Cash out via PayPal once you reach \(String(format: "$%.2f", Double(Constants.freePayoutThresholdCents) / 100.0))")
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)

            Spacer()

            PrimaryButton(title: "Show Me Around", isLoading: false, action: onContinue)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                animateBonus = true
                balanceScale = 1.0
            }
        }
    }

    private func bonusTip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.caption)
                .padding(.top, 3)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
