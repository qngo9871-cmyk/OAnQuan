import SwiftUI

/// Renders the 12-cell Ô Ăn Quan loop as a rectangle: a large Quan cell at
/// each end, Player A's 5 dân cells along the bottom, Player B's 5 dân
/// cells along the top. This is purely a display arrangement — the
/// underlying `Board` index order used for sowing/capture math is
/// documented on `Board` itself and does not need to match visual layout.
///
/// Top row is displayed left-to-right as [11, 10, 9, 8, 7] so index 11
/// (adjacent to QuanA in the loop) sits above index 1, and index 7
/// (adjacent to QuanB) sits above index 5 — mirroring the bottom row
/// visually across the board, even though the two rows sow in opposite
/// spatial directions around the loop.
struct BoardView: View {
    @ObservedObject var game: GameModel
    let interactive: Bool
    @Binding var selectedCell: Int?

    private let topRow = [11, 10, 9, 8, 7]
    private let bottomRow = [1, 2, 3, 4, 5]

    var body: some View {
        HStack(spacing: 8) {
            quanCell(Board.quanA)
            VStack(spacing: 8) {
                HStack(spacing: 8) { ForEach(topRow, id: \.self) { danCell($0) } }
                HStack(spacing: 8) { ForEach(bottomRow, id: \.self) { danCell($0) } }
            }
            quanCell(Board.quanB)
        }
        .padding(8)
    }

    private func quanCell(_ index: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "crown.fill").font(.caption2).foregroundStyle(.yellow)
            Text("\(game.board.stones[index])")
                .font(.title3.bold().monospacedDigit())
        }
        .frame(width: 46, height: 92)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.brown.opacity(0.35)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brown, lineWidth: 1.5))
    }

    private func danCell(_ index: Int) -> some View {
        let owner = Board.owner(ofDan: index)
        let isMine = interactive && owner == game.current && game.board.stones[index] > 0
        let isSelected = selectedCell == index
        let wasCaptured = game.lastCapturedCells.contains(index)

        return Text("\(game.board.stones[index])")
            .font(.title3.bold().monospacedDigit())
            .frame(width: 42, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(owner == .a ? Color.blue.opacity(0.18) : Color.red.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.yellow : (wasCaptured ? Color.red.opacity(0.7) : Color.secondary.opacity(0.3)),
                            lineWidth: isSelected || wasCaptured ? 3 : 1)
            )
            .opacity(isMine || !interactive ? 1.0 : 0.85)
            .contentShape(Rectangle())
            .onTapGesture {
                guard isMine else { return }
                selectedCell = (selectedCell == index) ? nil : index
            }
    }
}

#Preview {
    BoardView(game: GameModel(), interactive: true, selectedCell: .constant(nil))
}
