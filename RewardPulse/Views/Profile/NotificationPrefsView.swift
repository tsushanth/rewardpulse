import SwiftUI
import SwiftData

struct NotificationPrefsView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var vm: ProfileViewModel

    var prefs: NotificationPreference? { vm.notificationPrefs }

    var body: some View {
        List {
            Section("Notification Types") {
                if let prefs {
                    Toggle("New Surveys Available", isOn: Binding(
                        get: { prefs.surveysAvailable },
                        set: { prefs.surveysAvailable = $0; vm.saveNotificationPrefs(context: modelContext) }
                    ))
                    .accessibilityLabel("New surveys notification")

                    Toggle("Daily Poll Reminder", isOn: Binding(
                        get: { prefs.dailyPollReminder },
                        set: { prefs.dailyPollReminder = $0; vm.saveNotificationPrefs(context: modelContext) }
                    ))
                    .accessibilityLabel("Daily poll reminder notification")

                    Toggle("Streak Reminder", isOn: Binding(
                        get: { prefs.streakReminder },
                        set: { prefs.streakReminder = $0; vm.saveNotificationPrefs(context: modelContext) }
                    ))
                    .accessibilityLabel("Streak reminder notification")

                    Toggle("Payout Confirmations", isOn: Binding(
                        get: { prefs.payoutConfirmation },
                        set: { prefs.payoutConfirmation = $0; vm.saveNotificationPrefs(context: modelContext) }
                    ))
                    .accessibilityLabel("Payout confirmation notification")

                    Toggle("Achievement Unlocked", isOn: Binding(
                        get: { prefs.achievementUnlocked },
                        set: { prefs.achievementUnlocked = $0; vm.saveNotificationPrefs(context: modelContext) }
                    ))
                    .accessibilityLabel("Achievement unlocked notification")
                }
            }

            Section("Quiet Hours") {
                if let prefs {
                    HStack {
                        Text("Start")
                        Spacer()
                        Picker("Start quiet hours", selection: Binding(
                            get: { prefs.quietHoursStart },
                            set: { prefs.quietHoursStart = $0; vm.saveNotificationPrefs(context: modelContext) }
                        )) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(hourLabel(hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Quiet hours start time")
                    }

                    HStack {
                        Text("End")
                        Spacer()
                        Picker("End quiet hours", selection: Binding(
                            get: { prefs.quietHoursEnd },
                            set: { prefs.quietHoursEnd = $0; vm.saveNotificationPrefs(context: modelContext) }
                        )) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(hourLabel(hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Quiet hours end time")
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now)!
        return date.formatted(.dateTime.hour())
    }
}
