import SwiftUI

struct PaywallView: View {
    @StateObject private var vm = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    var source: String = "generic"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                            .padding(.top)

                        Text("RewardPulse Premium")
                            .font(.title.bold())
                            .accessibilityAddTraits(.isHeader)

                        Text("Earn more. Pay less fees. Skip the wait.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    FeatureBulletList()

                    PlanPickerView(
                        selectedPlan: $vm.selectedPlan,
                        products: vm.products
                    )

                    if let roi = vm.roiDescription {
                        Text(roi)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    PrimaryButton(
                        title: vm.purchaseButtonTitle,
                        isLoading: vm.isPurchasing
                    ) {
                        Task { await vm.purchase() }
                    }
                    .accessibilityHint("Purchases the selected plan")

                    Button("Restore Purchases") {
                        Task { await vm.restore() }
                    }
                    .font(.footnote)
                    .disabled(vm.isPurchasing)
                    .accessibilityLabel("Restore previous purchases")

                    Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Cancel anytime in Settings.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.bottom)
                }
                .padding(.horizontal, 20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityLabel("Close paywall")
                }
            }
            .alert("Purchase Error", isPresented: $vm.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "Something went wrong. Please try again.")
            }
        }
        .task { await vm.onAppear(source: source) }
    }
}
