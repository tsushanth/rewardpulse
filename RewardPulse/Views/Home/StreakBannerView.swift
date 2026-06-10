import SwiftUI

struct StreakBannerView: View {
    let days: Int
    let multiplier: Double
    let insuranceAvailable: Bool
    var isPremium: Bool = false

    private var milestoneLabel: String? {
        switch days {
        case 100...: return "100-Day Legend!"
        case 30...:  return "30-Day Master"
        case 7...:   return "7-Day Streak"
        default:     return nil
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Day \(days) Streak")
                        .font(.headline)
                    if let label = milestoneLabel {
                        Text(label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    if multiplier > 1.0 {
                        Label("\(Int((multiplier - 1) * 100))% bonus active", systemImage: "arrow.up.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    if insuranceAvailable {
                        HStack(spacing: 4) {
                            Label("Insurance", systemImage: "shield.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            if !isPremium {
                                ProBadgeView(style: .small)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Streak: Day \(days). \(multiplier > 1.0 ? "\(Int((multiplier - 1) * 100))% earning bonus active." : "") \(insuranceAvailable ? "Streak insurance available." : "")")
    }
}
