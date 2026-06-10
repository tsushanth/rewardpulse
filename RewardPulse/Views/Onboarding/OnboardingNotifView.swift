import SwiftUI

struct OnboardingNotifView: View {
    let onContinue: () -> Void
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
                .padding(.bottom, 32)
                .accessibilityHidden(true)

            Text("Never Miss a Survey")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            Text("New surveys arrive daily and expire fast. Enable notifications so you earn more before they're gone.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 16) {
                notifBenefit("New surveys", "Get notified the moment new surveys arrive")
                notifBenefit("Streak reminders", "Protect your streak before it breaks")
                notifBenefit("Payout confirmations", "Know when your cash is on its way")
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(title: "Enable Notifications", isLoading: isRequesting) {
                    isRequesting = true
                    Task {
                        _ = await NotificationService.shared.requestAuthorization()
                        isRequesting = false
                        onContinue()
                    }
                }
                .accessibilityHint("Requests notification permission then proceeds")

                Button("Skip for now") {
                    onContinue()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Skip notifications")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private func notifBenefit(_ title: String, _ description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
