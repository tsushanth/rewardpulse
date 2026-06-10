import SwiftUI
import AppTrackingTransparency

struct ATTPrePromptView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text("A Quick Question")
                .font(.title2.bold())

            Text("Allowing tracking helps us show you surveys you're more likely to qualify for — meaning more earnings, fewer disqualifications.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(title: "Continue", isLoading: false) {
                    onContinue()
                }
                .accessibilityHint("Proceeds to the system tracking permission dialog")

                Button("No Thanks") { onContinue() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Decline tracking permission")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

func requestATTPermission() async {
    let status = await ATTrackingManager.requestTrackingAuthorization()
    switch status {
    case .authorized:
        AnalyticsService.shared.log(.attAuthorized)
    case .denied, .restricted:
        AnalyticsService.shared.log(.attDenied)
    case .notDetermined:
        break
    @unknown default:
        break
    }
}
