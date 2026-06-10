import SwiftUI
import SwiftData

struct PrivacySettingsView: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var analyticsEnabled = true
    @State private var personalizedSurveys = true
    @State private var doNotSell = false
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Section("Data Sharing") {
                Toggle("Analytics & Performance", isOn: $analyticsEnabled)
                    .accessibilityLabel("Analytics and performance data sharing")

                Toggle("Personalized Survey Matching", isOn: $personalizedSurveys)
                    .accessibilityLabel("Personalized survey matching toggle")

                Toggle("Do Not Sell or Share My Personal Information", isOn: $doNotSell)
                    .accessibilityLabel("California CCPA Do Not Sell toggle")
            }

            Section("Your Data") {
                Button {
                    // Data export would be handled server-side
                } label: {
                    Label("Request Data Export", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Request a copy of your data")
                .accessibilityHint("Opens a data export request")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Account", systemImage: "trash.fill")
                }
                .accessibilityLabel("Delete your account")
                .accessibilityHint("Permanently deletes all data and signs you out")
            } footer: {
                Text("Account deletion is permanent and cannot be undone. All earnings, survey history, and personal data will be removed.")
                    .font(.caption)
            }
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task { await vm.deleteAccount(context: modelContext) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account, all earnings, and survey history. This cannot be undone.")
        }
        .loadingOverlay(vm.isDeleting, message: "Deleting account…")
        .errorBanner($vm.errorMessage)
    }
}
