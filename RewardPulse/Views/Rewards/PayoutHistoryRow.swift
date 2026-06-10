import SwiftUI

struct PayoutHistoryRow: View {
    let payout: PayoutRequest

    private var statusColor: Color {
        switch payout.status {
        case .initiated:  return .orange
        case .processing: return .orange
        case .completed:  return .green
        case .failed:     return .red
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: payout.method.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(payout.method.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(payout.destinationIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(payout.initiatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(payout.amountFormatted)
                    .font(.subheadline.weight(.bold))

                Text(payout.status.displayText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(payout.method.displayName) payout: \(payout.amountFormatted). Status: \(payout.status.displayText)")
    }
}
