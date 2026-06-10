import SwiftUI

/// A compact "PRO" badge shown next to premium-gated features.
///
/// Usage:
///   Label("Full Analytics", systemImage: "chart.xyaxis.line")
///   ProBadgeView()
struct ProBadgeView: View {
    var style: ProBadgeStyle = .standard

    var body: some View {
        Text("PRO")
            .font(style.font)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, style.hPadding)
            .padding(.vertical, style.vPadding)
            .background(style.background)
            .clipShape(Capsule())
            .accessibilityLabel("Premium feature")
    }
}

enum ProBadgeStyle {
    case standard
    case small

    var font: Font {
        switch self {
        case .standard: return .caption2
        case .small:    return .system(size: 9, weight: .heavy)
        }
    }

    var hPadding: CGFloat {
        switch self {
        case .standard: return 7
        case .small:    return 5
        }
    }

    var vPadding: CGFloat {
        switch self {
        case .standard: return 3
        case .small:    return 2
        }
    }

    var background: AnyShapeStyle {
        switch self {
        case .standard:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.orange, Color(red: 0.93, green: 0.50, blue: 0.13)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .small:
            return AnyShapeStyle(Color.orange)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HStack {
            Text("Full Analytics")
            ProBadgeView()
        }
        HStack {
            Text("Streak Insurance")
            ProBadgeView(style: .small)
        }
    }
    .padding()
}
