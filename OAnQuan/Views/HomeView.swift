import SwiftUI

struct HomeView: View {
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var purchases = PurchaseManager.shared
    @State private var selectedDifficulty: AIDifficulty = .easy
    @State private var navigateToAI = false
    @State private var navigateToLocal = false
    @State private var showUpgrade = false
    @State private var showHowToPlay = false
    @State private var showRules = false
    @State private var aiGame = GameModel()
    @State private var localGame = GameModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 26) {
                Spacer()

                VStack(spacing: 6) {
                    Text(L("home.title"))
                        .font(.largeTitle.bold())
                    Text(L("home.subtitle"))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 12) {
                    Picker(L("home.difficulty"), selection: $selectedDifficulty) {
                        ForEach(AIDifficulty.allCases) { level in
                            HStack {
                                Text(L("difficulty." + level.rawValue.lowercased()))
                                if level.requiresPro && !purchases.isPro { Image(systemName: "lock.fill") }
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)

                    Button {
                        if selectedDifficulty.requiresPro && !purchases.isPro {
                            showUpgrade = true
                        } else {
                            aiGame.reset()
                            navigateToAI = true
                        }
                    } label: {
                        Label(L("home.playAI"), systemImage: "cpu").frame(maxWidth: 220)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                Button {
                    if !purchases.isPro {
                        showUpgrade = true
                    } else {
                        localGame.reset()
                        navigateToLocal = true
                    }
                } label: {
                    HStack {
                        Label(L("home.playFriend"), systemImage: "person.2").frame(maxWidth: 190)
                        if !purchases.isPro {
                            Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                HStack(spacing: 20) {
                    Button { showHowToPlay = true } label: {
                        Text(L("home.howtoplay")).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Button { showRules = true } label: {
                        Text(L("home.rules")).font(.subheadline).foregroundStyle(.secondary)
                    }
                }

                if !purchases.isPro {
                    Button { showUpgrade = true } label: {
                        Text(L("home.upgrade")).font(.footnote).foregroundStyle(.orange)
                    }
                }

                Spacer()

                Picker("", selection: $loc.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("v\(version) (\(build))").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationDestination(isPresented: $navigateToAI) {
                GameView(game: aiGame, vsAI: true, aiDifficulty: selectedDifficulty)
            }
            .navigationDestination(isPresented: $navigateToLocal) {
                GameView(game: localGame, vsAI: false, aiDifficulty: .easy)
            }
            .sheet(isPresented: $showUpgrade) { UpgradeView() }
            .sheet(isPresented: $showHowToPlay) { OnboardingView(onFinished: { showHowToPlay = false }) }
            .sheet(isPresented: $showRules) { RulesView() }
            .task { await purchases.loadProduct() }
            #if DEBUG
            .onAppear {
                if let capture = ProcessInfo.processInfo.environment["OQ_CAPTURE"], capture != "home" {
                    if capture == "upgrade" {
                        showUpgrade = true
                    } else if capture == "rules" {
                        showRules = true
                    } else if capture == "onboarding" {
                        showHowToPlay = true
                    } else {
                        aiGame.reset()
                        navigateToAI = true
                    }
                }
            }
            #endif
        }
    }
}

#Preview {
    HomeView().environmentObject(LocalizationManager.shared)
}
