import SwiftUI

struct SubscriptionStatusView: View {
    let isPremium: Bool
    let expiresAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isPremium ? "crown.fill" : "crown")
                    .foregroundStyle(isPremium ? .orange : .secondary)
                    .accessibilityHidden(true)
                Text(isPremium ? "Premium Active" : "Free Plan")
                    .font(.headline)
                Spacer()
                if isPremium {
                    Text("Active")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
            }

            if isPremium, let expiry = expiresAt {
                Text("Renews \(expiry.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if isPremium {
                Text("Lifetime access")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Upgrade for 1.5x rewards, priority surveys, and more.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isPremium {
                Button("Manage Subscription") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline.weight(.medium))
                .accessibilityLabel("Manage subscription in App Store")
                .accessibilityHint("Opens App Store subscription management")
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
        .accessibilityElement(children: .contain)
    }
}
