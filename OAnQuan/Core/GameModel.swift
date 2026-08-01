import Foundation

enum GameOutcome: Equatable {
    case ongoing
    case win(Player)
    case draw
}

/// Drives one match: turn order, move application, the forced-borrowing
/// rule, and end-of-game detection/scoring. iOS 16 target, so
/// `ObservableObject`/`@Published`, not the Observation macro.
final class GameModel: ObservableObject {
    @Published private(set) var board: Board = .initial()
    @Published private(set) var current: Player = .a
    @Published private(set) var scoreA: Int = 0
    @Published private(set) var scoreB: Int = 0
    @Published private(set) var outcome: GameOutcome = .ongoing
    @Published private(set) var lastCapturedCells: [Int] = []
    @Published private(set) var lastCapturedCount: Int = 0
    @Published private(set) var lastBorrowRecipient: Player?
    @Published private(set) var moveCount: Int = 0

    func score(_ player: Player) -> Int { player == .a ? scoreA : scoreB }

    func legalMoves(for player: Player) -> [Move] { board.legalMoves(for: player) }

    /// Apply one move for the current player: pick up `cell`'s stones and
    /// sow them in `direction`. No-op if it's not a legal move for whoever's
    /// turn it is right now.
    func play(cell: Int, direction: Int) {
        guard outcome == .ongoing else { return }
        let move = Move(cell: cell, direction: direction)
        guard board.legalMoves(for: current).contains(move) else { return }

        lastBorrowRecipient = nil
        let (newBoard, captured, capturedCells) = board.applying(move)
        board = newBoard
        lastCapturedCells = capturedCells
        lastCapturedCount = captured
        if captured > 0 {
            addScore(current, captured)
        }
        moveCount += 1
        current = current.opposite
        resolveTurnStart()
    }

    private func addScore(_ player: Player, _ amount: Int) {
        if player == .a { scoreA += amount } else { scoreB += amount }
    }

    /// Runs whenever a new player is about to move: checks the
    /// simultaneous-empty-rows end condition, then the forced-borrowing rule
    /// for whoever's turn it now is.
    private func resolveTurnStart() {
        guard outcome == .ongoing else { return }

        let aEmpty = Board.aDan.allSatisfy { board.stones[$0] == 0 }
        let bEmpty = Board.bDan.allSatisfy { board.stones[$0] == 0 }

        if aEmpty && bEmpty {
            endGame()
            return
        }

        let currentEmpty = current == .a ? aEmpty : bEmpty
        guard currentEmpty else { return }

        // Forced borrowing: the opponent lends 1 stone from their captured
        // pile into each of the current player's 5 empty dân cells. If the
        // opponent can't afford all 5, the game ends instead.
        let opponent = current.opposite
        if score(opponent) < 5 {
            endGame()
        } else {
            addScore(opponent, -5)
            for c in Board.danCells(for: current) { board.stones[c] += 1 }
            lastBorrowRecipient = current
        }
    }

    /// Awards whatever is still sitting in the two Quan cells (the fixed
    /// 10-point quan stone plus any ordinary stones sown into it along the
    /// way) to its owning player. This never re-triggers capture logic — a
    /// Quan cell's contents are simply handed over directly. Any stones
    /// still sitting in dân cells at this point are discarded per the
    /// standard convention (left on the board, not scored to either side).
    private func endGame() {
        scoreA += board.stones[Board.quanA] + Board.quanValue
        scoreB += board.stones[Board.quanB] + Board.quanValue
        board.stones[Board.quanA] = 0
        board.stones[Board.quanB] = 0

        if scoreA == scoreB {
            outcome = .draw
        } else {
            outcome = .win(scoreA > scoreB ? .a : .b)
        }
    }

    func reset() {
        board = .initial()
        current = .a
        scoreA = 0
        scoreB = 0
        outcome = .ongoing
        lastCapturedCells = []
        lastCapturedCount = 0
        lastBorrowRecipient = nil
        moveCount = 0
    }

    #if DEBUG
    /// Debug-only screenshot/verification hook: jump straight to a scripted
    /// board state by name. Never invoked outside DEBUG launch-arg handling.
    func captureSetup(_ scenario: String) {
        switch scenario {
        case "midgame":
            var s = [Int](repeating: 0, count: Board.cellCount)
            for i in Board.aDan + Board.bDan { s[i] = 5 }
            s[1] = 0; s[2] = 8; s[3] = 3; s[7] = 0; s[8] = 6
            s[Board.quanA] = 2; s[Board.quanB] = 1
            board = Board(stones: s)
            scoreA = 12
            scoreB = 7
            moveCount = 9
        case "capture":
            var s = [Int](repeating: 0, count: Board.cellCount)
            for i in Board.aDan + Board.bDan { s[i] = 5 }
            s[3] = 0
            s[4] = 0
            s[5] = 6
            board = Board(stones: s)
            scoreA = 5
            scoreB = 3
            lastCapturedCells = [7, 8]
            moveCount = 5
        default:
            break
        }
    }
    #endif
}
