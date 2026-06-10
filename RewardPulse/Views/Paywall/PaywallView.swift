import SwiftUI

struct PaywallView: View {
    @StateObject private var vm = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    var source: String = "generic"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: Hero
                    heroSection

                    // MARK: Feature bullets
                    FeatureBulletList()

                    // MARK: Plan picker
                    PlanPickerView(
                        selectedPlan: $vm.selectedPlan,
                        priceForPlan: { vm.price(for: $0) }
                    )

                    // MARK: ROI copy
                    Text(vm.roiDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    // MARK: Pending purchase banner
                    if vm.purchaseState == .pending {
                        pendingBanner
                    }

                    // MARK: Network / loading state
                    if vm.isLoading {
                        ProgressView("Loading plans…")
                            .padding(.vertical, 8)
                    }

                    // MARK: CTA
                    PrimaryButton(
                        title: vm.purchaseButtonTitle,
                        isLoading: vm.isPurchasing
                    ) {
                        Task { await vm.purchase() }
                    }
                    .disabled(vm.isLoading || vm.purchaseState == .pending)
                    .accessibilityHint("Purchases the selected plan")

                    // MARK: Restore
                    Button("Restore Purchases") {
                        Task { await vm.restore() }
                    }
                    .font(.footnote)
                    .disabled(vm.isPurchasing)
                    .accessibilityLabel("Restore previous purchases")

                    // MARK: Legal links
                    legalSection

                    // MARK: Subscription disclaimer
                    Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Cancel anytime in Settings → Apple ID → Subscriptions.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.bottom)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
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

    // MARK: - Sub-views

    private var heroSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
                .padding(.top)

            Text("RewardPulse Premium")
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)

            Text("Earn more. Pay less. Skip the wait.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var pendingBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark.fill")
                .foregroundStyle(.orange)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Purchase Pending")
                    .font(.subheadline.weight(.semibold))
                Text("Waiting for approval (e.g. Family Sharing). You'll be notified when it's approved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Purchase is pending approval")
    }

    private var legalSection: some View {
        HStack(spacing: 20) {
            Link("Privacy Policy", destination: URL(string: "https://rewardpulse.app/privacy")!)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("·")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            Link("Terms of Service", destination: URL(string: "https://rewardpulse.app/terms")!)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
    }
}
