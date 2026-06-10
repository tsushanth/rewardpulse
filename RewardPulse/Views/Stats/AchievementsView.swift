import SwiftUI
import SwiftData

struct AchievementsView: View {
    let achievements: [Achievement]

    private let columns = [
        GridItem(.adaptive(minimum: 90, maximum: 120), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                Spacer()
                Text("\(achievements.filter(\.isUnlocked).count)/\(achievements.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(achievements, id: \.id) { achievement in
                    BadgeView(achievement: achievement)
                }

                ForEach(AchievementID.allCases.filter { id in
                    !achievements.map(\.id).contains(id)
                }, id: \.self) { id in
                    BadgeView(achievement: Achievement(id: id))
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
    }
}
