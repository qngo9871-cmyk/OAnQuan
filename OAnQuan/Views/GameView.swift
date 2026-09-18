import SwiftUI
import UIKit

struct GameView: View {
    @ObservedObject var game: GameModel
    let vsAI: Bool
    let aiDifficulty: AIDifficulty

    /// The human always plays Player A, in both vs-AI and pass-and-play
    /// modes (Player A also always moves first, per the ruleset).
    private let humanPlayer: Player = .a

    @StateObject private var purchases = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCell: Int?
    @State private var isAIThinking = false
    @State private var showHowToPlay = false
    @State private var showResignConfirm = false
    @State private var showUpgrade = false

    /// Mirrors `HomeView.isLocked(_:)` — without this, tapping "New Game" here
    /// after a match ends bypasses the trial gate entirely (it never routes back
    /// through Home, where the real check lives). Found as a real bug 2026-09-19
    /// while auditing why the Vietnamese lineup gets downloads but no purchases;
    /// the identical bug was already caught and fixed in CoCaNgua's GameView once
    /// before (2026-08-18) but was never ported here.
    private var newGameLocked: Bool {
        if purchases.isPro { return false }
        if !vsAI { return true } // Play vs Friend is always Pro-only, matching HomeView's gate
        if aiDifficulty.requiresPro { return true } // Hard AI is always Pro-only
        return !purchases.trialActive // Easy/Normal lock once the trial expires
    }
    /// Guards against double-recording the same match's outcome into
    /// `MatchStats` (this view's onChange can fire more than once around a
    /// single game-end transition).
    @State private var statsRecorded = false

    var body: some View {
        VStack(spacing: 10) {
            header
            borrowBanner
            capturedBanner

            BoardView(game: game, interactive: canAct, selectedCell: $selectedCell)
                .padding(.horizontal)
                .padding(.top, 32)

            if canAct {
                Text(L("game.selectPrompt"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            directionControls

            Button(L("game.resign"), role: .destructive) { showResignConfirm = true }
                .buttonStyle(.bordered)
                .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(L("game.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showHowToPlay = true } label: {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            OnboardingView(onFinished: { showHowToPlay = false })
        }
        .confirmationDialog(L("game.resign.confirm"), isPresented: $showResignConfirm, titleVisibility: .visible) {
            Button(L("game.resign"), role: .destructive) { dismiss() }
            Button(L("game.resign.cancel"), role: .cancel) {}
        }
        .onAppear { maybeTriggerAI() }
        .onChange(of: game.current) { _ in maybeTriggerAI() }
        .onChange(of: game.outcome) { newOutcome in handleOutcomeChange(newOutcome) }
        .alert(L("game.outcome.title"), isPresented: .constant(game.outcome != .ongoing)) {
            Button(L("game.newGame")) { startNewGame() }
            Button(L("game.done")) { dismiss() }
        } message: {
            Text(outcomeMessage)
        }
        .sheet(isPresented: $showUpgrade) { UpgradeView() }
        #if DEBUG
        .onAppear {
            if let capture = ProcessInfo.processInfo.environment["OQ_CAPTURE"],
               capture != "home", capture != "upgrade", capture != "rules", capture != "onboarding" {
                game.captureSetup(capture)
            }
        }
        #endif
    }

    private var canAct: Bool {
        guard game.outcome == .ongoing, !isAIThinking else { return false }
        if vsAI { return game.current == humanPlayer }
        return true
    }

    private var header: some View {
        HStack {
            Text("\(scoreLabel(.a)): \(game.score(.a))")
            Spacer()
            Text(turnLabel).font(.subheadline.bold())
            Spacer()
            Text("\(scoreLabel(.b)): \(game.score(.b))")
        }
        .padding(.horizontal)
        .font(.footnote)
    }

    @ViewBuilder private var borrowBanner: some View {
        if let recipient = game.lastBorrowRecipient {
            Text(borrowText(recipient))
                .font(.caption2)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    @ViewBuilder private var capturedBanner: some View {
        if game.lastCapturedCount > 0 {
            Text(String(format: L("game.captured"), game.lastCapturedCount))
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }

    private var directionControls: some View {
        HStack(spacing: 16) {
            Button {
                commitMove(direction: -1)
            } label: {
                Label(L("game.sow.counterclockwise"), systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .disabled(!canAct || selectedCell == nil)

            Button {
                commitMove(direction: 1)
            } label: {
                Label(L("game.sow.clockwise"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAct || selectedCell == nil)
        }
        .font(.caption)
        .padding(.horizontal)
    }

    private func commitMove(direction: Int) {
        guard let cell = selectedCell else { return }
        game.play(cell: cell, direction: direction)
        selectedCell = nil
        if game.lastCapturedCount > 0 {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    /// Fires a haptic for the match result and records a vs-AI outcome into
    /// `MatchStats` exactly once per game (pass-and-play games aren't
    /// recorded — a "win" there isn't the human's personal record).
    private func handleOutcomeChange(_ newOutcome: GameOutcome) {
        guard newOutcome != .ongoing else { return }

        let feedback = UINotificationFeedbackGenerator()
        switch newOutcome {
        case .win(let winner):
            let humanWon = !vsAI || winner == humanPlayer
            feedback.notificationOccurred(humanWon ? .success : .error)
        case .draw:
            feedback.notificationOccurred(.warning)
        case .ongoing:
            break
        }

        guard vsAI, !statsRecorded else { return }
        statsRecorded = true
        switch newOutcome {
        case .win(let winner):
            MatchStats.shared.record(winner == humanPlayer ? .win : .loss)
        case .draw:
            MatchStats.shared.record(.draw)
        case .ongoing:
            break
        }
    }

    private func scoreLabel(_ player: Player) -> String {
        if vsAI {
            return player == humanPlayer ? L("game.score.you") : L("game.score.ai")
        }
        return player == .a ? L("game.score.playerA") : L("game.score.playerB")
    }

    private func borrowText(_ recipient: Player) -> String {
        if vsAI {
            return recipient == humanPlayer ? L("game.borrow.toYou") : L("game.borrow.toAI")
        }
        return recipient == .a ? L("game.borrow.toPlayerA") : L("game.borrow.toPlayerB")
    }

    private var turnLabel: String {
        if isAIThinking { return L("game.turn.aiThinking") }
        switch game.outcome {
        case .ongoing:
            if vsAI {
                return game.current == humanPlayer ? L("game.turn.yourTurn") : L("game.turn.aiTurn")
            }
            return game.current == .a ? L("game.turn.playerATurn") : L("game.turn.playerBTurn")
        case .win(let winner):
            if vsAI {
                return winner == humanPlayer ? L("game.outcome.youWin") : L("game.outcome.aiWin")
            }
            return winner == .a ? L("game.outcome.playerAWin") : L("game.outcome.playerBWin")
        case .draw:
            return L("game.outcome.draw")
        }
    }

    private var outcomeMessage: String {
        guard game.outcome != .ongoing else { return "" }
        let scoreLine = String(format: L("game.finalScore"), game.score(.a), game.score(.b))
        return turnLabel + "\n" + scoreLine
    }

    private func startNewGame() {
        if newGameLocked {
            showUpgrade = true
            return
        }
        selectedCell = nil
        statsRecorded = false
        game.reset()
    }

    private func maybeTriggerAI() {
        guard vsAI, game.outcome == .ongoing, game.current != humanPlayer else { return }
        isAIThinking = true
        let board = game.board
        let player = game.current
        DispatchQueue.global(qos: .userInitiated).async {
            let move = AIEngine.bestMove(board: board, player: player, difficulty: aiDifficulty)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAIThinking = false
                guard let move else { return }
                game.play(cell: move.cell, direction: move.direction)
            }
        }
    }
}

#Preview {
    NavigationStack { GameView(game: GameModel(), vsAI: true, aiDifficulty: .normal) }
}
