import SwiftUI

struct EarningHistoryRow: View {
    let event: EarningEvent

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rowColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: sourceIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(rowColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.source.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(event.eventDescription.isEmpty ? event.source.displayName : event.eventDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(event.amountFormatted)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
                if event.isStreakBonus {
                    Label("×\(String(format: "%.1f", event.multiplierApplied))", systemImage: "flame.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.source.displayName): \(event.amountFormatted) on \(event.createdAt.formatted(date: .abbreviated, time: .omitted))")
    }

    private var rowColor: Color {
        switch event.source {
        case .survey:          return .accentColor
        case .surveyDQPartial: return .orange
        case .dailyPoll:       return .purple
        case .dailyCheckIn:    return .secondary
        case .streakBonus:     return .orange
        case .weeklyChallenge: return .blue
        case .referralBonus:   return .green
        case .welcomeBonus:    return .accentColor
        case .achievementBonus: return .yellow
        }
    }

    private var sourceIcon: String {
        switch event.source {
        case .survey:          return "doc.text.fill"
        case .surveyDQPartial: return "doc.badge.clock"
        case .dailyPoll:       return "questionmark.circle.fill"
        case .dailyCheckIn:    return "checkmark.circle.fill"
        case .streakBonus:     return "flame.fill"
        case .weeklyChallenge: return "trophy.fill"
        case .referralBonus:   return "person.2.fill"
        case .welcomeBonus:    return "gift.fill"
        case .achievementBonus: return "star.fill"
        }
    }
}
