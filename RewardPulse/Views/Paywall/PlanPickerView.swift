import SwiftUI
import StoreKit

struct PlanPickerView: View {
    @Binding var selectedPlan: ProductPlanType
    /// Localized price resolver — ask the VM to avoid duplicating logic.
    var priceForPlan: (ProductPlanType) -> String

    private let plans: [(plan: ProductPlanType, label: String, isBestValue: Bool)] = [
        (.weekly,   "Flexible",   false),
        (.yearly,   "Best Value", true),
        (.lifetime, "One-Time",   false)
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(plans, id: \.plan) { item in
                PlanRow(
                    plan: item.plan,
                    label: item.label,
                    price: priceForPlan(item.plan),
                    isBestValue: item.isBestValue,
                    isSelected: selectedPlan == item.plan
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPlan = item.plan
                    }
                    HapticManager.shared.trigger(.light)
                }
            }
        }
    }
}

// MARK: - PlanRow

private struct PlanRow: View {
    let plan: ProductPlanType
    let label: String
    let price: String
    let isBestValue: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.accentColor : Color.secondary.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 13, height: 13)
                    }
                }
                .accessibilityHidden(true)

                // Plan name + price
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text(price)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Best value badge
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
                isSelected
                    ? Color.accentColor.opacity(0.08)
                    : Color(uiColor: .secondarySystemBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .frame(minHeight: Constants.minTapTarget)
        .accessibilityLabel("\(plan.displayName): \(price)\(isBestValue ? ". Best value." : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
