import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    var ringColor: Color = .accentColor
    var backgroundColor: Color = Color.secondary.opacity(0.2)
    var lineWidth: CGFloat = 12
    var showPercentage: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)

            if showPercentage {
                Text("\(Int(min(progress, 1.0) * 100))%")
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel("Progress: \(Int(min(progress, 1.0) * 100)) percent")
        .accessibilityValue("\(Int(min(progress, 1.0) * 100)) of 100")
    }
}

#Preview {
    HStack(spacing: 24) {
        ProgressRingView(progress: 0.35)
            .frame(width: 80, height: 80)
        ProgressRingView(progress: 0.75, ringColor: .green)
            .frame(width: 80, height: 80)
        ProgressRingView(progress: 1.0, ringColor: .yellow)
            .frame(width: 80, height: 80)
    }
    .padding()
}
