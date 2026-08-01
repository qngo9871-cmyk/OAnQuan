import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        #if DEBUG
        if let lang = ProcessInfo.processInfo.environment["OQ_LANG"], let l = AppLanguage(rawValue: lang) {
            LocalizationManager.shared.setLanguage(l)
        }
        if let capture = ProcessInfo.processInfo.environment["OQ_CAPTURE"], capture != "home" {
            if capture == "onboarding" {
                return AnyView(OnboardingView(onFinished: {}))
            }
            if capture == "upgrade" {
                return AnyView(UpgradeView())
            }
            if capture == "rules" {
                return AnyView(RulesView())
            }
            let game = GameModel()
            game.captureSetup(capture)
            return AnyView(NavigationStack { GameView(game: game, vsAI: true, aiDifficulty: .normal) })
        }
        if ProcessInfo.processInfo.environment["OQ_SKIP_ONBOARDING"] != nil {
            return AnyView(HomeView())
        }
        #endif
        if !hasSeenOnboarding {
            return AnyView(OnboardingView(onFinished: { hasSeenOnboarding = true }))
        }
        return AnyView(HomeView())
    }
}

#Preview { ContentView() }
