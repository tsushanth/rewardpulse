import SwiftUI

struct LoadingOverlay: View {
    var message: String = "Loading…"

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    var message: String

    func body(content: Content) -> some View {
        ZStack {
            content
            if isLoading {
                LoadingOverlay(message: message)
            }
        }
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool, message: String = "Loading…") -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}
