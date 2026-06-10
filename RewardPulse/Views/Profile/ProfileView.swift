import SwiftUI
import SwiftData

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showPaywall) private var showPaywall

    @State private var showEditProfile = false
    @State private var showNotifPrefs = false
    @State private var showPrivacySettings = false
    @State private var showSubscriptionStatus = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Text((vm.profile?.displayName?.prefix(1) ?? "?").uppercased())
                            .font(.title.bold())
                            .foregroundStyle(Color.accentColor)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.profile?.displayName ?? "RewardPulse User")
                            .font(.headline)
                        Text(vm.profile?.email ?? "No email set")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Profile: \(vm.profile?.displayName ?? "RewardPulse User")")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Profile Completion")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(vm.profileCompletionPct)%")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                    }
                    ProgressView(value: Double(vm.profileCompletionPct), total: 100)
                        .tint(.accentColor)
                        .accessibilityLabel("Profile \(vm.profileCompletionPct) percent complete")
                    Text(vm.completionPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Subscription") {
                if let profile = vm.profile {
                    SubscriptionStatusView(
                        isPremium: profile.isPremium,
                        expiresAt: profile.premiumExpiresAt
                    )
                    .listRowInsets(EdgeInsets())
                }

                if !(vm.profile?.isPremium ?? false) {
                    Button(action: { showPaywall.wrappedValue = true }) {
                        Label("Upgrade to Premium", systemImage: "crown.fill")
                    }
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Upgrade to Premium")
                    .accessibilityHint("Opens the paywall")
                }
            }

            Section("Settings") {
                NavigationLink(destination: EditProfileView(vm: vm)) {
                    Label("Edit Profile", systemImage: "person.fill")
                }
                .accessibilityLabel("Edit profile")

                NavigationLink(destination: NotificationPrefsView(vm: vm)) {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .accessibilityLabel("Notification preferences")

                NavigationLink(destination: PrivacySettingsView(vm: vm)) {
                    Label("Privacy Settings", systemImage: "hand.raised.fill")
                }
                .accessibilityLabel("Privacy settings")
            }

            Section("Support") {
                Link(destination: URL(string: "https://rewardpulse.app/support")!) {
                    Label("Help & Support", systemImage: "questionmark.circle.fill")
                }
                .accessibilityLabel("Help and support")

                Link(destination: URL(string: "https://rewardpulse.app/privacy")!) {
                    Label("Privacy Policy", systemImage: "doc.text.fill")
                }
                .accessibilityLabel("Privacy policy")

                Link(destination: URL(string: "https://rewardpulse.app/terms")!) {
                    Label("Terms of Service", systemImage: "doc.fill")
                }
                .accessibilityLabel("Terms of service")
            }

            Section {
                Button(role: .destructive) {
                    AuthService.shared.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .accessibilityLabel("Sign out of your account")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .task { vm.onAppear(context: modelContext) }
        .errorBanner($vm.errorMessage)
    }
}
