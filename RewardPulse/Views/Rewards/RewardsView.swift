import SwiftUI
import SwiftData

struct RewardsView: View {
    @StateObject private var vm = RewardsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showPaywall) private var showPaywall

    @State private var showPayoutFlow = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Your Balance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(vm.balanceFormatted)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }

                    ProgressView(value: vm.progressToPayoutPct)
                        .tint(vm.canRedeem ? .green : .accentColor)
                        .accessibilityLabel("Progress to payout: \(Int(vm.progressToPayoutPct * 100))%")

                    HStack {
                        Text(vm.canRedeem ? "Ready to cash out!" : "\(vm.balanceFormatted) of \(vm.minimumPayoutFormatted) minimum")
                            .font(.caption)
                            .foregroundStyle(vm.canRedeem ? .green : .secondary)
                        Spacer()
                        if !vm.isPremium {
                            Button("Upgrade to $2.50 minimum") {
                                showPaywall.wrappedValue = true
                            }
                            .font(.caption.weight(.semibold))
                            .accessibilityLabel("Upgrade to Premium for $2.50 minimum payout")
                        }
                    }

                    Button(action: { showPayoutFlow = true }) {
                        Label("Cash Out", systemImage: "arrow.right.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(vm.canRedeem ? .green : .accentColor)
                    .disabled(!vm.canRedeem)
                    .accessibilityLabel(vm.canRedeem ? "Cash out your balance" : "Cash out — not enough balance")
                    .accessibilityHint(vm.canRedeem ? "Opens payout flow" : "Earn more to reach the minimum")
                }
                .padding(.vertical, 8)
            }

            if !vm.payoutHistory.isEmpty {
                Section("Payout History") {
                    ForEach(vm.payoutHistory, id: \.id) { payout in
                        PayoutHistoryRow(payout: payout)
                    }
                }
            }

            if !vm.earningHistory.isEmpty {
                Section("Earning History") {
                    ForEach(vm.earningHistory, id: \.id) { event in
                        EarningHistoryRow(event: event)
                    }
                }
            }

            if vm.earningHistory.isEmpty && vm.payoutHistory.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("No earnings yet")
                            .font(.subheadline.weight(.medium))
                        Text("Complete surveys and daily polls to see your history here.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Rewards")
        .navigationBarTitleDisplayMode(.large)
        .task { await vm.onAppear(context: modelContext) }
        .refreshable { await vm.onAppear(context: modelContext) }
        .sheet(isPresented: $showPayoutFlow) {
            PayoutFlowView()
        }
        .errorBanner($vm.errorMessage)
    }
}
