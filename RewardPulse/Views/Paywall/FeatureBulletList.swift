import SwiftUI

private struct PremiumFeature: Identifiable {
    let id: Int
    let icon: String
    let title: String
}

private let premiumFeatures: [PremiumFeature] = {
    let data: [(Int, String, String)] = [
        (0, "bolt.fill",              "Priority Survey Queue"),
        (1, "multiply.circle.fill",   "1.5x Reward Multiplier"),
        (2, "crown.fill",             "Exclusive Premium Surveys"),
        (3, "dollarsign.circle.fill", "$2.50 Minimum Payout"),
        (4, "shield.fill",            "Streak Insurance"),
        (5, "chart.xyaxis.line",      "Full Lifetime Analytics"),
        (6, "arrow.down.doc.fill",    "Earnings CSV Export"),
        (7, "chart.bar.xaxis",        "Earner Percentile Ranking")
    ]
    return data.map { PremiumFeature(id: $0.0, icon: $0.1, title: $0.2) }
}()

struct FeatureBulletList: View {
    @State private var visibleItems: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(premiumFeatures) { feature in
                FeatureBulletRow(feature: feature, isVisible: visibleItems.contains(feature.id))
                    .onAppear {
                        let delay = Double(feature.id) * 0.06
                        withAnimation(Animation.spring(response: 0.4).delay(delay)) {
                            visibleItems.insert(feature.id)
                        }
                    }
            }
        }
    }
}

private struct FeatureBulletRow: View {
    let feature: PremiumFeature
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 28)
                .accessibilityHidden(true)

            Text(feature.title)
                .font(.subheadline.weight(.medium))

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .accessibilityLabel(feature.title)
    }
}
