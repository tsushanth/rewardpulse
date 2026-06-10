import SwiftUI

struct PlanPickerView: View {
    @Binding var selectedPlan: ProductPlanType
    let products: [RevenueCatOffering]

    private let plans: [(ProductPlanType, String, String, Bool)] = [
        (.weekly,   "$4.00/wk",   "Flexible",    false),
        (.yearly,   "$56.00/yr",  "Best Value",  true),
        (.lifetime, "$92.80",     "One-Time",    false)
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(plans, id: \.0) { plan, price, label, isBestValue in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPlan = plan
                    }
                    HapticManager.shared.trigger(.light)
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(selectedPlan == plan ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2)
                                .frame(width: 22, height: 22)
                            if selectedPlan == plan {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 13, height: 13)
                            }
                        }
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.displayName)
                                .font(.subheadline.weight(.semibold))
                            Text(localizedPrice(for: plan) ?? price)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        selectedPlan == plan
                        ? Color.accentColor.opacity(0.08)
                        : Color(uiColor: .secondarySystemBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selectedPlan == plan ? Color.accentColor : .clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .frame(minHeight: Constants.minTapTarget)
                .accessibilityLabel("\(plan.displayName): \(localizedPrice(for: plan) ?? price)\(isBestValue ? ". Best value." : "")")
                .accessibilityAddTraits(selectedPlan == plan ? .isSelected : [])
            }
        }
    }

    private func localizedPrice(for plan: ProductPlanType) -> String? {
        products.first(where: { $0.planType == plan })?.localizedPriceString
    }
}
