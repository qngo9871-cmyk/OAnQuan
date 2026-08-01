import Foundation

enum AIDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"

    var id: String { rawValue }
    var requiresPro: Bool { self == .hard }
}

/// The branching factor per turn is tiny (up to 5 candidate dân cells x 2
/// directions = at most 10 legal moves), so every difficulty just simulates
/// the full legal-move set via `Board.applying(_:)` rather than doing any
/// kind of pruned tree search.
///
///  - Easy: mostly a random legal move, only occasionally taking the best
///    capture — meant to feel beatable, not to actually play badly on
///    purpose in a way that looks broken.
///  - Normal: greedy — the move that captures the most stones this turn.
///  - Hard: 2-ply — for each candidate move, subtract the opponent's best
///    immediate reply (their best captured-stones response to the resulting
///    position), so it avoids handing over an easy big capture.
enum AIEngine {
    private static let easyBestMoveChance = 0.3

    static func bestMove(board: Board, player: Player, difficulty: AIDifficulty) -> Move? {
        let moves = board.legalMoves(for: player)
        guard !moves.isEmpty else { return nil }

        switch difficulty {
        case .easy:
            if Double.random(in: 0..<1) < easyBestMoveChance {
                return greedyMove(board: board, moves: moves)
            }
            return moves.randomElement()
        case .normal:
            return greedyMove(board: board, moves: moves)
        case .hard:
            return minimaxMove(board: board, player: player, moves: moves)
        }
    }

    private static func greedyMove(board: Board, moves: [Move]) -> Move? {
        var best: [Move] = []
        var bestScore = -1
        for move in moves {
            let captured = board.applying(move).captured
            if captured > bestScore {
                bestScore = captured
                best = [move]
            } else if captured == bestScore {
                best.append(move)
            }
        }
        return best.randomElement()
    }

    private static func minimaxMove(board: Board, player: Player, moves: [Move]) -> Move? {
        var best: [Move] = []
        var bestScore = Int.min
        for move in moves {
            let result = board.applying(move)
            let opponentMoves = result.board.legalMoves(for: player.opposite)
            let opponentBestReply = opponentMoves
                .map { result.board.applying($0).captured }
                .max() ?? 0
            let score = result.captured - opponentBestReply
            if score > bestScore {
                bestScore = score
                best = [move]
            } else if score == bestScore {
                best.append(move)
            }
        }
        return best.randomElement()
    }
}
