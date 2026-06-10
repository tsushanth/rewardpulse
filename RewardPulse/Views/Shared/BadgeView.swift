import SwiftUI

struct BadgeView: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? Color.yellow.opacity(0.15)
                          : Color.secondary.opacity(0.1))
                    .frame(width: 64, height: 64)

                Image(systemName: achievement.id.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(achievement.isUnlocked ? .yellow : .secondary)

                if !achievement.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .offset(x: 20, y: 20)
                }
            }

            Text(achievement.id.title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .lineLimit(2)

            if let unlockedAt = achievement.unlockedAt {
                Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text(achievement.id.description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 90)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(achievement.isUnlocked
                            ? "Achievement unlocked: \(achievement.id.title)"
                            : "Achievement locked: \(achievement.id.title). \(achievement.id.description)")
    }
}
