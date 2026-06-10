import SwiftUI

struct OnboardingProfileView: View {
    @ObservedObject var vm: OnboardingViewModel
    let onSave: () -> Void

    private let genderOptions = ["male", "female", "nonbinary", "prefer_not"]
    private let employmentOptions = ["employed_full", "part", "self_employed", "student", "retired", "unemployed"]
    private let incomeOptions = ["$0-25k", "$25-50k", "$50-75k", "$75-100k", "$100k+"]
    private let educationOptions = ["high_school", "some_college", "associate", "bachelor", "graduate", "doctorate"]
    private let interestOptions = SurveyCategory.allCases.map(\.displayName)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Build Your Profile")
                        .font(.largeTitle.bold())
                    Text("Answer a few questions to unlock better-matching surveys.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 80)

                ProgressView(value: Double(vm.profileCompletionScore), total: 100)
                    .tint(.accentColor)
                    .accessibilityLabel("Profile \(vm.profileCompletionScore) percent complete")

                Group {
                    labeledField("Your Name") {
                        TextField("Display name (optional)", text: $vm.displayName)
                            .textContentType(.name)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }

                    labeledField("Birth Year") {
                        Picker("Birth Year", selection: $vm.birthYear) {
                            ForEach((1940...Calendar.current.component(.year, from: .now) - 18).reversed(), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    labeledField("Gender") {
                        Picker("Gender", selection: $vm.gender) {
                            Text("Select…").tag("")
                            ForEach(genderOptions, id: \.self) { g in
                                Text(genderDisplayName(g)).tag(g)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    labeledField("Employment Status") {
                        Picker("Employment Status", selection: $vm.employmentStatus) {
                            Text("Select…").tag("")
                            ForEach(employmentOptions, id: \.self) { e in
                                Text(employmentDisplayName(e)).tag(e)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    labeledField("Annual Income Range") {
                        Picker("Income Range", selection: $vm.annualIncomeRange) {
                            Text("Select…").tag("")
                            ForEach(incomeOptions, id: \.self) { i in
                                Text(i).tag(i)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    labeledField("Education Level") {
                        Picker("Education", selection: $vm.educationLevel) {
                            Text("Select…").tag("")
                            ForEach(educationOptions, id: \.self) { e in
                                Text(educationDisplayName(e)).tag(e)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    labeledField("Postal Code (optional)") {
                        TextField("ZIP or postal code", text: $vm.postalCode)
                            .textContentType(.postalCode)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(.roundedBorder)
                    }

                    labeledField("Interests (select all that apply)") {
                        FlowLayout(spacing: 8) {
                            ForEach(SurveyCategory.allCases, id: \.self) { category in
                                let isSelected = vm.selectedInterests.contains(category.displayName)
                                Button(action: {
                                    if isSelected {
                                        vm.selectedInterests.remove(category.displayName)
                                    } else {
                                        vm.selectedInterests.insert(category.displayName)
                                    }
                                }) {
                                    Label(category.displayName, systemImage: category.iconName)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.bordered)
                                .tint(isSelected ? .accentColor : .secondary)
                                .accessibilityLabel(category.displayName)
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                            }
                        }
                    }
                }

                PrimaryButton(
                    title: vm.isSaving ? "Saving…" : "Continue",
                    isLoading: vm.isSaving,
                    action: onSave
                )
                .padding(.bottom, 40)
                .accessibilityHint("Saves your profile and credits welcome bonus")
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemBackground))
    }

    private func labeledField(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.semibold))
            content()
        }
    }

    private func genderDisplayName(_ raw: String) -> String {
        switch raw {
        case "male": return "Male"
        case "female": return "Female"
        case "nonbinary": return "Non-binary"
        case "prefer_not": return "Prefer not to say"
        default: return raw
        }
    }

    private func employmentDisplayName(_ raw: String) -> String {
        switch raw {
        case "employed_full": return "Employed full-time"
        case "part": return "Employed part-time"
        case "self_employed": return "Self-employed"
        case "student": return "Student"
        case "retired": return "Retired"
        case "unemployed": return "Not currently employed"
        default: return raw
        }
    }

    private func educationDisplayName(_ raw: String) -> String {
        switch raw {
        case "high_school": return "High school / GED"
        case "some_college": return "Some college"
        case "associate": return "Associate's degree"
        case "bachelor": return "Bachelor's degree"
        case "graduate": return "Graduate degree"
        case "doctorate": return "Doctorate"
        default: return raw
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct RowItem { let view: LayoutSubview; let size: CGSize }
    private struct Row { let items: [RowItem]; let height: CGFloat }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var rowItems: [RowItem] = []
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width + (rowItems.isEmpty ? 0 : spacing) > maxWidth && !rowItems.isEmpty {
                rows.append(Row(items: rowItems, height: rowHeight))
                rowItems = []
                rowWidth = 0
                rowHeight = 0
            }
            rowItems.append(RowItem(view: view, size: size))
            rowWidth += size.width + (rowItems.count > 1 ? spacing : 0)
            rowHeight = max(rowHeight, size.height)
        }
        if !rowItems.isEmpty {
            rows.append(Row(items: rowItems, height: rowHeight))
        }
        return rows
    }
}
