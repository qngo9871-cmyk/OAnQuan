import Foundation

/// Lightweight local win/loss/draw record for vs-AI matches, persisted via
/// UserDefaults on-device only (no network, no account — consistent with
/// the privacy site's "no data collection" claim). Not present in the
/// original template this app was built from; this is a deliberate small
/// differentiator: it gives a returning player something to track ("your
/// record vs AI") instead of every match being a stateless one-off.
enum MatchOutcome {
    case win, loss, draw
}

final class MatchStats: ObservableObject {
    static let shared = MatchStats()

    @Published private(set) var wins: Int
    @Published private(set) var losses: Int
    @Published private(set) var draws: Int

    private let winsKey = "oq_stats_wins"
    private let lossesKey = "oq_stats_losses"
    private let drawsKey = "oq_stats_draws"

    init() {
        let d = UserDefaults.standard
        wins = d.integer(forKey: winsKey)
        losses = d.integer(forKey: lossesKey)
        draws = d.integer(forKey: drawsKey)
    }

    var hasAnyRecord: Bool { wins + losses + draws > 0 }

    func record(_ outcome: MatchOutcome) {
        let d = UserDefaults.standard
        switch outcome {
        case .win:
            wins += 1
            d.set(wins, forKey: winsKey)
        case .loss:
            losses += 1
            d.set(losses, forKey: lossesKey)
        case .draw:
            draws += 1
            d.set(draws, forKey: drawsKey)
        }
    }
}
