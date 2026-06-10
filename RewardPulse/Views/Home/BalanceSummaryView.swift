import SwiftUI

struct BalanceSummaryView: View {
    let balanceCents: Int
    let minimumPayoutCents: Int
    let onRedeemTap: () -> Void

    @State private var displayedCents: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var progress: Double {
        guard minimumPayoutCents > 0 else { return 1.0 }
        return min(Double(balanceCents) / Double(minimumPayoutCents), 1.0)
    }

    var canRedeem: Bool { balanceCents >= minimumPayoutCents }
    var balanceFormatted: String { String(format: "$%.2f", Double(displayedCents) / 100.0) }
    var minimumFormatted: String { String(format: "$%.2f", Double(minimumPayoutCents) / 100.0) }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Your Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(balanceFormatted)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Balance: \(balanceFormatted)")
            }

            HStack(spacing: 16) {
                ProgressRingView(progress: progress, ringColor: canRedeem ? .green : .accentColor, lineWidth: 10)
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    if canRedeem {
                        Text("Ready to cash out!")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    } else {
                        Text("\(Int(progress * 100))% to next payout")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("Minimum: \(minimumFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button(action: onRedeemTap) {
                Label("Redeem", systemImage: "arrow.right.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(canRedeem ? .green : .accentColor)
            .disabled(!canRedeem)
            .accessibilityLabel(canRedeem ? "Redeem your balance" : "Redeem — not enough balance yet")
            .accessibilityHint(canRedeem ? "Opens payout flow" : "Earn more to reach the minimum")
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .onAppear {
            if reduceMotion {
                displayedCents = balanceCents
            } else {
                withAnimation(.spring(response: 0.8).delay(0.1)) {
                    displayedCents = balanceCents
                }
            }
        }
        .onChange(of: balanceCents) { _, newValue in
            withAnimation(.spring(response: 0.5)) {
                displayedCents = newValue
            }
        }
    }
}
