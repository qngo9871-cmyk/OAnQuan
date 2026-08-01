import Foundation

/// The two sides. Player A always moves first.
enum Player: Equatable, Hashable {
    case a
    case b
    var opposite: Player { self == .a ? .b : .a }
}

/// One legal move: pick up all stones from one of your own non-empty dân
/// (small) cells, then sow them in a chosen direction around the loop.
/// `direction` is +1 for clockwise (increasing index) or -1 for
/// counter-clockwise (decreasing index, wrapping mod 12).
struct Move: Equatable, Hashable {
    let cell: Int
    let direction: Int
}

/// The 12-cell circular track: index 0 and 6 are the two "Quan" (mandarin)
/// cells at opposite ends; indices 1-5 are Player A's five "dân" cells,
/// indices 7-11 are Player B's five "dân" cells. Sowing walks this loop by
/// +1 (clockwise) or -1 (counter-clockwise), wrapping mod 12:
///
///   [QuanA, A1, A2, A3, A4, A5, QuanB, B5, B4, B3, B2, B1] -> back to QuanA
///
/// `stones` only tracks ordinary ("dân") stones, one count per cell —
/// including any that have been sown into a Quan cell in passing, which is
/// normal and expected. The large Quan stone itself (fixed 10-point value,
/// this app's specific scoring convention — see CLAUDE.md) is NOT part of
/// this array: it can never be captured or picked up, so it never needs to
/// move. It's added to the owning player's score directly at game end,
/// alongside whatever ordinary stones happen to be sitting in that Quan
/// cell at the time.
struct Board: Equatable {
    static let cellCount = 12
    static let quanA = 0
    static let quanB = 6
    static let aDan: [Int] = [1, 2, 3, 4, 5]
    static let bDan: [Int] = [7, 8, 9, 10, 11]
    static let quanValue = 10

    var stones: [Int]

    static func danCells(for player: Player) -> [Int] { player == .a ? aDan : bDan }
    static func owner(ofDan i: Int) -> Player? {
        if aDan.contains(i) { return .a }
        if bDan.contains(i) { return .b }
        return nil
    }
    static func isQuan(_ i: Int) -> Bool { i == quanA || i == quanB }
    static func step(_ i: Int, _ direction: Int) -> Int { ((i + direction) % cellCount + cellCount) % cellCount }

    static func initial() -> Board {
        var s = [Int](repeating: 0, count: cellCount)
        for i in aDan + bDan { s[i] = 5 }
        return Board(stones: s)
    }

    /// A Quan cell always holds its fixed 10-point stone until end-game
    /// award, so it's never considered "empty" for capture-chain purposes —
    /// even before any ordinary stone has ever been sown into it.
    func isEmpty(_ i: Int) -> Bool {
        if Board.isQuan(i) { return false }
        return stones[i] == 0
    }

    func legalMoves(for player: Player) -> [Move] {
        Board.danCells(for: player).filter { stones[$0] > 0 }.flatMap { cell in
            [Move(cell: cell, direction: 1), Move(cell: cell, direction: -1)]
        }
    }

    /// Walk the capture chain starting from the last cell sown into. Returns
    /// the dân cells captured (a Quan cell is NEVER included — reaching one
    /// mid-chain just ends the chain with no capture of it). Does not mutate
    /// `self`; callers remove the captured stones.
    ///
    /// Rule, precisely: if the last-sown cell is itself a Quan cell, or the
    /// cell right after it is non-empty, there's no capture at all. Otherwise
    /// walk forward two cells at a time (empty, then check the next): a
    /// non-empty cell there is captured and the chain continues from it; an
    /// empty cell there (two empties in a row) or a Quan cell stops the
    /// chain with no further capture.
    func captureChain(lastIndex: Int, direction: Int) -> [Int] {
        guard !Board.isQuan(lastIndex) else { return [] }
        var captured: [Int] = []
        var cur = lastIndex
        while true {
            let p1 = Board.step(cur, direction)
            if Board.isQuan(p1) { break }
            if !isEmpty(p1) { break }
            let p2 = Board.step(p1, direction)
            if Board.isQuan(p2) { break }
            if isEmpty(p2) { break }
            captured.append(p2)
            cur = p2
        }
        return captured
    }

    /// Pure application of one move: pick up, sow, resolve the capture
    /// chain, and return the resulting board plus what was captured. Used by
    /// both `GameModel` (real play) and `AIEngine` (lookahead) so the rules
    /// live in exactly one place.
    func applying(_ move: Move) -> (board: Board, captured: Int, capturedCells: [Int]) {
        var b = self
        let n = b.stones[move.cell]
        guard n > 0 else { return (b, 0, []) }
        b.stones[move.cell] = 0
        var cur = move.cell
        for _ in 0..<n {
            cur = Board.step(cur, move.direction)
            b.stones[cur] += 1
        }
        let capturedCells = b.captureChain(lastIndex: cur, direction: move.direction)
        let total = capturedCells.reduce(0) { $0 + b.stones[$1] }
        for c in capturedCells { b.stones[c] = 0 }
        return (b, total, capturedCells)
    }
}
