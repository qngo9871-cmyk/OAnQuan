import SwiftUI

struct GameView: View {
    @ObservedObject var game: GameModel
    let vsAI: Bool
    let aiDifficulty: AIDifficulty

    /// The human always plays Player A, in both vs-AI and pass-and-play
    /// modes (Player A also always moves first, per the ruleset).
    private let humanPlayer: Player = .a

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCell: Int?
    @State private var isAIThinking = false
    @State private var showHowToPlay = false
    @State private var showResignConfirm = false

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
        .alert(L("game.outcome.title"), isPresented: .constant(game.outcome != .ongoing)) {
            Button(L("game.newGame")) { selectedCell = nil; game.reset() }
            Button(L("game.done")) { dismiss() }
        } message: {
            Text(outcomeMessage)
        }
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
