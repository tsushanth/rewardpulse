import SwiftUI

struct RewardCreditAnimation: View {
    let rewardCents: Int
    let onComplete: () -> Void

    @State private var showParticles = false
    @State private var showAmount = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var amountFormatted: String {
        String(format: "+$%.2f", Double(rewardCents) / 100.0)
    }

    var body: some View {
        ZStack {
            if !reduceMotion && showParticles {
                ForEach(0..<12, id: \.self) { i in
                    ParticleView(index: i)
                }
            }

            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)
                    .scaleEffect(scale)

                Text(amountFormatted)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .scaleEffect(scale)

                Text("Reward Credited!")
                    .font(.title3.bold())

                Text("Your balance has been updated.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(opacity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reward credited: \(amountFormatted)")
        .onAppear {
            if reduceMotion {
                showAmount = true
                opacity = 1
                scale = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    onComplete()
                }
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
                withAnimation(.easeIn(duration: 0.1).delay(0.2)) {
                    showParticles = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    onComplete()
                }
            }
        }
    }
}

private struct ParticleView: View {
    let index: Int
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(particleColor)
            .frame(width: 10, height: 10)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
                let distance: Double = 100
                withAnimation(.easeOut(duration: 0.8)) {
                    offset = CGSize(
                        width: cos(angle) * distance,
                        height: sin(angle) * distance
                    )
                    opacity = 0
                }
            }
    }

    private var particleColor: Color {
        let colors: [Color] = [.yellow, .green, .orange, .mint, .cyan]
        return colors[index % colors.count]
    }
}
