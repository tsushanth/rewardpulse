import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .background(isDisabled || isLoading ? Color.accentColor.opacity(0.5) : Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "")
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Get Started", isLoading: false) {}
        PrimaryButton(title: "Loading", isLoading: true) {}
        PrimaryButton(title: "Disabled", isLoading: false, isDisabled: true) {}
    }
    .padding()
}
