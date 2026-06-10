import SwiftUI
import SwiftData

struct EditProfileView: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var birthYear: Int = 1990
    @State private var gender: String = ""
    @State private var postalCode: String = ""
    @State private var householdSize: Int = 2
    @State private var employmentStatus: String = ""
    @State private var annualIncomeRange: String = ""
    @State private var educationLevel: String = ""
    @State private var selectedInterests: Set<String> = []

    private let genderOptions = ["male", "female", "nonbinary", "prefer_not"]
    private let employmentOptions = ["employed_full", "part", "self_employed", "student", "retired", "unemployed"]
    private let incomeOptions = ["$0-25k", "$25-50k", "$50-75k", "$75-100k", "$100k+"]
    private let educationOptions = ["high_school", "some_college", "associate", "bachelor", "graduate", "doctorate"]

    var body: some View {
        List {
            Section("Personal Info") {
                TextField("Display Name", text: $displayName)
                    .textContentType(.name)
                    .accessibilityLabel("Display name")

                Picker("Birth Year", selection: $birthYear) {
                    ForEach((1940...2006).reversed(), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .accessibilityLabel("Birth year")

                Picker("Gender", selection: $gender) {
                    Text("Select…").tag("")
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                    Text("Non-binary").tag("nonbinary")
                    Text("Prefer not to say").tag("prefer_not")
                }
                .accessibilityLabel("Gender")

                TextField("Postal Code", text: $postalCode)
                    .textContentType(.postalCode)
                    .keyboardType(.numbersAndPunctuation)
                    .accessibilityLabel("Postal code")
            }

            Section("Household") {
                Stepper("Household Size: \(householdSize)", value: $householdSize, in: 1...10)
                    .accessibilityLabel("Household size: \(householdSize)")
            }

            Section("Professional") {
                Picker("Employment Status", selection: $employmentStatus) {
                    Text("Select…").tag("")
                    Text("Employed full-time").tag("employed_full")
                    Text("Employed part-time").tag("part")
                    Text("Self-employed").tag("self_employed")
                    Text("Student").tag("student")
                    Text("Retired").tag("retired")
                    Text("Not employed").tag("unemployed")
                }
                .accessibilityLabel("Employment status")

                Picker("Annual Income", selection: $annualIncomeRange) {
                    Text("Select…").tag("")
                    ForEach(incomeOptions, id: \.self) { i in Text(i).tag(i) }
                }
                .accessibilityLabel("Annual income range")

                Picker("Education", selection: $educationLevel) {
                    Text("Select…").tag("")
                    Text("High school / GED").tag("high_school")
                    Text("Some college").tag("some_college")
                    Text("Associate's").tag("associate")
                    Text("Bachelor's").tag("bachelor")
                    Text("Graduate degree").tag("graduate")
                    Text("Doctorate").tag("doctorate")
                }
                .accessibilityLabel("Education level")
            }

            Section("Interests") {
                FlowLayout(spacing: 8) {
                    ForEach(SurveyCategory.allCases, id: \.self) { category in
                        let isSelected = selectedInterests.contains(category.displayName)
                        Button(action: {
                            if isSelected { selectedInterests.remove(category.displayName) }
                            else { selectedInterests.insert(category.displayName) }
                        }) {
                            Label(category.displayName, systemImage: category.iconName)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .tint(isSelected ? .accentColor : .secondary)
                        .accessibilityLabel(category.displayName)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveAndDismiss() }
                    .disabled(vm.isSaving)
                    .accessibilityLabel("Save profile changes")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .loadingOverlay(vm.isSaving, message: "Saving…")
        .errorBanner($vm.errorMessage)
        .onAppear { loadFromProfile() }
    }

    private func loadFromProfile() {
        guard let profile = vm.profile else { return }
        displayName = profile.displayName ?? ""
        birthYear = profile.birthYear ?? 1990
        gender = profile.gender ?? ""
        postalCode = profile.postalCode ?? ""
        householdSize = profile.householdSize ?? 2
        employmentStatus = profile.employmentStatus ?? ""
        annualIncomeRange = profile.annualIncomeRange ?? ""
        educationLevel = profile.educationLevel ?? ""
        selectedInterests = Set(profile.interestCategories)
    }

    private func saveAndDismiss() {
        let updates = ProfileUpdates(
            displayName: displayName.isEmpty ? nil : displayName,
            birthYear: birthYear,
            gender: gender.isEmpty ? nil : gender,
            postalCode: postalCode.isEmpty ? nil : postalCode,
            householdSize: householdSize,
            employmentStatus: employmentStatus.isEmpty ? nil : employmentStatus,
            annualIncomeRange: annualIncomeRange.isEmpty ? nil : annualIncomeRange,
            educationLevel: educationLevel.isEmpty ? nil : educationLevel,
            interestCategories: Array(selectedInterests)
        )
        Task {
            await vm.saveProfile(updates: updates, context: modelContext)
            if vm.errorMessage == nil {
                dismiss()
            }
        }
    }
}
