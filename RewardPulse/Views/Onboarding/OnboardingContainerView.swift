import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            TabView(selection: $vm.currentStep) {
                OnboardingValueView { vm.advance() }
                    .tag(0)

                OnboardingNotifView { vm.advance() }
                    .tag(1)

                OnboardingProfileView(vm: vm) {
                    Task {
                        await vm.saveProfileAndCreditWelcomeBonus(context: modelContext)
                        vm.advance()
                    }
                }
                .tag(2)

                OnboardingWelcomeView(bonusCents: Constants.welcomeBonusCents) { vm.advance() }
                    .tag(3)

                OnboardingDashTourView {
                    vm.completeOnboarding()
                }
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .disabled(true)

            VStack {
                HStack(spacing: 8) {
                    ForEach(0..<vm.totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step <= vm.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: step == vm.currentStep ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: vm.currentStep)
                    }
                }
                .padding(.top, 60)
                .accessibilityLabel("Step \(vm.currentStep + 1) of \(vm.totalSteps)")

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $vm.onboardingComplete) {
            MainTabView()
        }
        .errorBanner($vm.errorMessage)
    }
}
