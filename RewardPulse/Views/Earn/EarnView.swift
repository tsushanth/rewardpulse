import SwiftUI

struct EarnView: View {
    @StateObject private var vm = EarnViewModel()
    @State private var selectedSurvey: Survey? = nil
    @State private var showSurveyDetail = false
    @State private var showSurveyPlayer = false
    @State private var showDailyPoll = false
    @Environment(\.showPaywall) private var showPaywall

    var body: some View {
        Group {
            if vm.isLoading && vm.surveys.isEmpty {
                ProgressView("Loading surveys…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if let poll = vm.todaysPoll, !poll.isAnswered {
                        Section {
                            Button(action: { showDailyPoll = true }) {
                                HStack(spacing: 14) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.purple)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Daily Poll")
                                            .font(.subheadline.weight(.semibold))
                                        Text(poll.questionText)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(poll.rewardFormatted)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.green)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .accessibilityHidden(true)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Daily Poll: \(poll.questionText). Earn \(poll.rewardFormatted)")
                            .accessibilityHint("Tap to answer")
                        } header: {
                            Text("Today's Poll")
                        }
                    }

                    if vm.sortedSurveys.isEmpty {
                        Section {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                                Text("No surveys available right now")
                                    .font(.subheadline.weight(.medium))
                                Text("Check back soon — new surveys arrive throughout the day.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }
                    } else {
                        Section {
                            ForEach(vm.sortedSurveys, id: \.id) { survey in
                                SurveyCard(survey: survey) {
                                    vm.startSurvey(survey)
                                    selectedSurvey = survey
                                    showSurveyPlayer = true
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    selectedSurvey = survey
                                    showSurveyDetail = true
                                }
                            }
                        } header: {
                            Text("\(vm.sortedSurveys.count) Surveys Available")
                        }
                    }

                    if !vm.lockedPremiumSurveys.isEmpty {
                        Section {
                            ForEach(vm.lockedPremiumSurveys.prefix(3), id: \.id) { survey in
                                HStack(spacing: 14) {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.orange)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(survey.title)
                                            .font(.subheadline.weight(.medium))
                                            .lineLimit(1)
                                        Text(survey.rewardFormatted)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.green)
                                    }
                                    Spacer()
                                    Label("Premium", systemImage: "crown.fill")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.orange)
                                }
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                                .onTapGesture { showPaywall.wrappedValue = true }
                                .accessibilityLabel("\(survey.title): \(survey.rewardFormatted). Premium required.")
                                .accessibilityHint("Tap to upgrade to Premium")
                            }
                        } header: {
                            Text("Premium Surveys")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await vm.onAppear() }
            }
        }
        .navigationTitle("Earn")
        .navigationBarTitleDisplayMode(.large)
        .task { await vm.onAppear() }
        .sheet(isPresented: $showDailyPoll) {
            if let poll = vm.todaysPoll {
                DailyPollView(poll: poll) {
                    showDailyPoll = false
                    Task { await vm.onAppear() }
                }
            }
        }
        .sheet(isPresented: $showSurveyDetail) {
            if let survey = selectedSurvey {
                NavigationStack {
                    SurveyDetailView(survey: survey) {
                        showSurveyDetail = false
                        vm.startSurvey(survey)
                        showSurveyPlayer = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showSurveyPlayer) {
            if let survey = selectedSurvey {
                SurveyPlayerView(survey: survey)
            }
        }
        .errorBanner($vm.errorMessage)
        .onChange(of: vm.showPremiumLock) { _, newValue in
            if newValue { showPaywall.wrappedValue = true; vm.showPremiumLock = false }
        }
    }
}
