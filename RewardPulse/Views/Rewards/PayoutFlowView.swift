import SwiftUI
import SwiftData

struct PayoutFlowView: View {
    @StateObject private var vm = RewardsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMethod: PayoutMethod = .paypal
    @State private var destination: String = ""
    @State private var step: PayoutStep = .method

    enum PayoutStep { case method, confirm, sent }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .method:
                    methodView
                case .confirm:
                    confirmView
                case .sent:
                    sentView
                }
            }
            .navigationTitle("Cash Out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel payout")
                }
            }
        }
        .task { await vm.onAppear(context: modelContext) }
        .errorBanner($vm.errorMessage)
    }

    private var methodView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(vm.balanceFormatted)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("Available to Cash Out")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose Payout Method")
                        .font(.headline)

                    ForEach([PayoutMethod.paypal, .giftCardAmazon, .giftCardStarbucks], id: \.self) { method in
                        Button(action: {
                            selectedMethod = method
                            destination = (try? KeychainService.load(.paypalEmail)) ?? ""
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: method.iconName)
                                    .font(.title2)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 36)
                                    .accessibilityHidden(true)
                                Text(method.displayName)
                                    .font(.body.weight(.medium))
                                Spacer()
                                if selectedMethod == method {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .accessibilityHidden(true)
                                }
                            }
                            .padding(16)
                            .background(selectedMethod == method
                                        ? Color.accentColor.opacity(0.08)
                                        : Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selectedMethod == method ? Color.accentColor : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(minHeight: Constants.minTapTarget)
                        .accessibilityLabel(method.displayName)
                        .accessibilityAddTraits(selectedMethod == method ? .isSelected : [])
                    }

                    if selectedMethod == .paypal {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PayPal Email")
                                .font(.subheadline.weight(.semibold))
                            TextField("Enter your PayPal email", text: $destination)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("PayPal email address")
                        }
                    }
                }
                .padding(.horizontal)

                PrimaryButton(
                    title: "Continue",
                    isLoading: false,
                    isDisabled: !vm.canRedeem || destination.isEmpty
                ) {
                    step = .confirm
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
                .accessibilityHint("Proceed to confirmation")
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var confirmView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Confirm Payout")
                    .font(.title2.bold())
                Text("Review the details below")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                detailRow("Amount", vm.balanceFormatted)
                Divider()
                detailRow("Method", selectedMethod.displayName)
                Divider()
                detailRow("To", destination)
                Divider()
                detailRow("Processing Time", "1–3 business days")
            }
            .padding(20)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            PrimaryButton(
                title: "Send \(vm.balanceFormatted)",
                isLoading: vm.payoutInProgress
            ) {
                Task {
                    await vm.initiatePayoutRequest(
                        method: selectedMethod,
                        destination: destination,
                        context: modelContext
                    )
                    if vm.errorMessage == nil {
                        if selectedMethod == .paypal {
                            try? KeychainService.save(destination, for: .paypalEmail)
                        }
                        step = .sent
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    private var sentView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Payout Initiated!")
                    .font(.title.bold())
                Text("\(vm.balanceFormatted) is on its way to your \(selectedMethod.displayName) account.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("Processing typically takes 1–3 business days.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            PrimaryButton(title: "Done", isLoading: false) {
                dismiss()
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}
