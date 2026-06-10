import SwiftUI

struct SurveyPlayerView: View {
    @StateObject private var vm: SurveyViewModel
    @Environment(\.dismiss) private var dismiss

    init(survey: Survey) {
        _vm = StateObject(wrappedValue: SurveyViewModel(survey: survey))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ProgressView(value: vm.progress)
                    .tint(.accentColor)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .accessibilityLabel("Survey progress: \(Int(vm.progress * 100))%")

                if let question = vm.currentQuestion {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack {
                                Text("Question \(vm.currentQuestionIndex + 1) of \(vm.survey.questions.count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(vm.survey.rewardFormatted)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.green)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)

                            questionView(for: question)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.interactively)
                } else if vm.outcome != .inProgress {
                    SurveyCompletionView(
                        outcome: vm.outcome,
                        rewardCents: vm.rewardCredited,
                        onDismiss: { dismiss() }
                    )
                } else {
                    Spacer()
                    ProgressView("Loading survey…")
                    Spacer()
                }
            }

            if vm.isSubmitting {
                LoadingOverlay(message: "Submitting…")
            }

            if vm.showCompletionAnimation {
                RewardCreditAnimation(rewardCents: vm.rewardCredited) {
                    vm.showCompletionAnimation = false
                }
                .background(Color(uiColor: .systemBackground))
                .ignoresSafeArea()
            }
        }
        .navigationTitle(vm.survey.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(vm.currentQuestionIndex > 0)
        .toolbar {
            if vm.currentQuestionIndex > 0 && vm.outcome == .inProgress {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { vm.goToPreviousQuestion() }
                        .accessibilityLabel("Go to previous question")
                }
            }
        }
        .errorBanner($vm.errorMessage)
        .interactiveDismissDisabled(vm.currentQuestionIndex > 0)
    }

    @ViewBuilder
    private func questionView(for question: SurveyQuestion) -> some View {
        switch question.questionType {
        case .singleChoice:
            SingleChoiceView(question: question, onAnswer: vm.submitAnswer)
        case .multiChoice:
            MultiChoiceView(question: question, onAnswer: vm.submitAnswer)
        case .ratingScale:
            RatingScaleView(question: question, onAnswer: vm.submitAnswer)
        case .openText:
            OpenTextView(question: question, onAnswer: vm.submitAnswer)
        case .ranking:
            RankingView(question: question, onAnswer: vm.submitAnswer)
        case .imageChoice, .matrix:
            SingleChoiceView(question: question, onAnswer: vm.submitAnswer)
        }
    }
}
