# Ô Ăn Quan — Vietnamese Board Game

Native SwiftUI iOS app for Ô Ăn Quan, the traditional Vietnamese mancala-family board
game. Bundle `com.quyenngo.oanquan`. One app in a 5-app Vietnamese-games lineup (sibling
apps: Fanorona, Dara, SamLoc, ...). Built following the house pattern — read
`~/Projects/Fanorona` and `~/Projects/SamLoc` for the shared conventions this repo mirrors
(PurchaseManager/UpgradeView framing, Core module shape, `Localization.swift`, tooling
scripts).

**Status: 🟢 SUBMITTED, WAITING_FOR_REVIEW (2026-08-01).** App id `6796833584`, version `1.0.0`
(id `02974e1f-0415-4696-9c95-1ba3fc2871b4`), build `df46c053-b79d-4a20-95dc-90506b3ee2af`
attached, reviewSubmission `0cc80d2d-f422-4a7b-9923-ab68fbc6c7e4`. Release type: automatic
(`AFTER_APPROVAL`).

## Deploy / resubmit pattern

No Xcode account/Distribution cert on this machine — pass the ASC API key explicitly to
xcodebuild (see [[feedback_asc_release_and_signing]]):
```
xcodegen generate
xcodebuild -project OAnQuan.xcodeproj -scheme OAnQuan -configuration Release \
  -archivePath build/OAnQuan.xcarchive -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  -authenticationKeyPath /Users/q/.appstoreconnect/private_keys/AuthKey_G85WXB4AF5.p8 \
  -authenticationKeyID G85WXB4AF5 -authenticationKeyIssuerID 2e969722-fc4d-444c-af74-7e0233efd016 \
  archive
xcodebuild -exportArchive -archivePath build/OAnQuan.xcarchive -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates \
  -authenticationKeyPath /Users/q/.appstoreconnect/private_keys/AuthKey_G85WXB4AF5.p8 \
  -authenticationKeyID G85WXB4AF5 -authenticationKeyIssuerID 2e969722-fc4d-444c-af74-7e0233efd016
xcrun altool --upload-app --type ios -f build/export/OAnQuan.ipa \
  --apiKey G85WXB4AF5 --apiIssuer 2e969722-fc4d-444c-af74-7e0233efd016
```
Metadata scripts are idempotent — re-run after copy changes. No `asc_submit_oanquan.py`
exists; submission was done via one-off `reviewSubmissions` → `reviewSubmissionItems` →
`PATCH submitted=true` calls (copy the pattern from `asc_submit_woktonight.py` if
resubmitting).

## The ruleset — read this before touching game logic

This app implements one specific, internally-consistent, commonly-cited variant of Ô Ăn
Quan. **Other sources describe Ô Ăn Quan differently in places** (quan stone value,
capture-chain edge cases, borrowing mechanics). Do NOT "correct" this implementation
against a different source without deliberately re-speccing it — the rules below are the
single source of truth for this app, chosen for being precise and deterministic/testable,
not for being the only real-world variant.

**Board**: 12 cells in a loop, index order (this is the internal `Board.stones` array
order, not necessarily the on-screen layout — see `BoardView.swift`'s doc comment for the
separate visual mapping):

```
[QuanA(0), A1(1), A2(2), A3(3), A4(4), A5(5), QuanB(6), B5(7), B4(8), B3(9), B2(10), B1(11)]
```

Player A owns dân cells 1-5, Player B owns dân cells 7-11. Sowing direction `+1` =
clockwise (increasing index, wrapping mod 12), `-1` = counter-clockwise.

**Setup**: each dân cell starts with 5 stones. Each Quan cell starts with 1 large "quan"
stone worth **10 points at final scoring — this app's specific convention**, documented
in-app on the Rules screen as "Ô Ăn Quan (10-point quan variant)". `Board.stones` only
tracks ordinary stone counts per cell (including any sown into a Quan cell in passing);
the fixed 10-point quan value is NOT stored per-cell since it can never move or be
captured — `GameModel.endGame()` adds it directly at game end.

**Turn**: pick up all stones from one of your own non-empty dân cells, choose a sowing
direction, drop 1 stone per cell around the loop (Quan cells included, as passed-through
stops — normal, not a capture trigger by itself).

**Capture chain** (`Board.captureChain`, the single most spec-sensitive piece of logic):
look at the cell right after the last-sown cell.
- If that's non-empty, OR the last-sown cell was itself a Quan cell → no capture at all.
- If it's empty, look at the cell after *that*: non-empty → capture it, then repeat from
  there (check the cell after the captured one, needing another empty-then-nonempty pair
  to continue).
- Stops at two empty cells in a row, or at a Quan cell reached mid-chain (a Quan cell is
  never captured this way — reaching one just ends the chain silently).
- A Quan cell is treated as *never empty* for this logic (`Board.isEmpty` returns false
  for Quan indices) since it always conceptually holds its 10-point stone until awarded.

**Forced borrowing ("mượn")**: if it becomes a player's turn and all 5 of their dân cells
are empty, the opponent must lend 1 stone from their captured-score pile into each of the
5 empty cells (5 total). If the opponent's pile has fewer than 5, the game ends
immediately instead (`GameModel.resolveTurnStart`).

**Game end**: triggered by (a) the above un-affordable borrow, or (b) both players' rows
being simultaneously empty after any move. On end, each Quan cell's contents (ordinary
stones sown into it + the fixed 10-point stone) go directly to that cell's owner —
**this does not re-run capture logic**, it's a direct award. Any stones left in dân cells
are discarded (standard convention, not scored to either side). Ties are a legitimate
draw result.

**AI** (`AIEngine.swift`): branching factor is tiny (≤5 dân cells × 2 directions ≤ 10
moves), so every difficulty just enumerates `Board.legalMoves(for:)` and evaluates each
via the pure `Board.applying(_:)`, rather than any pruned tree search.
- Easy: ~70% random legal move, ~30% the best immediate capture.
- Normal: greedy — max stones captured this turn.
- Hard: 2-ply — max(this turn's capture − opponent's best immediate reply capture on the
  resulting position).

## Structure

- `OAnQuan/Core/Board.swift` — pure value-type board model: the 12-cell loop, legal moves,
  the capture-chain algorithm, and `applying(_:)` (pure sow+capture, used by both real
  play and AI lookahead so the rules live in exactly one place).
- `OAnQuan/Core/GameModel.swift` — `ObservableObject` driving one match: turn order,
  scoring, forced-borrow/game-end resolution. `#if DEBUG` `captureSetup(_:)` hook for
  screenshot automation.
- `OAnQuan/Core/AIEngine.swift` — the 3-difficulty move selection described above.
- `OAnQuan/Core/PurchaseManager.swift` — StoreKit 2 non-consumable IAP
  `com.quyenngo.oanquan.pro`, copied from the Fanorona/Dara pattern byte-for-byte except
  the product ID and the DEBUG paywall-bypass env var (`OQ_CAPTURE`).
- `OAnQuan/Core/Localization.swift` — copied verbatim from SamLoc: manual bundle-swap
  `LocalizationManager` so the in-app language switches live without relaunching.
- `OAnQuan/Views/` — `HomeView`, `GameView`, `BoardView`, `UpgradeView`, `OnboardingView`,
  `RulesView`. `BoardView.swift` has its own doc comment mapping the *visual* board layout
  (Quan cells at each end, Player A's row on bottom, Player B's on top) to the `Board`
  model's loop-index order — the two are intentionally decoupled.
- `OAnQuan/{en,vi}.lproj/Localizable.strings` — hand-written bilingual UI strings using
  correct terms: "quan", "dân", "rải" (sow), "ăn" (capture), "mượn" (borrow/lend). Turn
  labels deliberately use dedicated keys per role (`game.turn.yourTurn` /
  `game.turn.aiTurn` / `game.turn.playerATurn` / `game.turn.playerBTurn`) instead of a
  shared `%@`-templated string — this sidesteps the "%@ = You" grammar trap documented in
  SamLoc's CLAUDE.md by construction, rather than by careful wording.
- `capture_shots.py` — drives the simulator via `OQ_CAPTURE`/`OQ_LANG` DEBUG launch args
  for real in-app screenshots (App Review 2.3.3) into `screenshots/final/{en,vi}/`.
  Scenarios: `home`, `midgame`, `capture`, `upgrade`, `rules`.
- `make_icon.py` — real 1024×1024 icon: one bold gold "quan" stone emblem, radially
  shaded, with 8 small cream "dân" stones scattered around it, on a warm wood-brown
  gradient. Replaced the earlier flat-color placeholder — see the App Store readiness
  section below.
- `project.yml` — XcodeGen. Run `xcodegen generate` (or `./rebuild.sh`) after adding or
  removing source files.

## Judgment calls made beyond the literal spec

- **Human is always Player A** in both vs-AI and pass-and-play modes (Player A also
  always moves first per the ruleset, so this keeps the human's first move consistent).
- **Direction UI**: two explicit buttons ("Sow Clockwise" / "Sow Counter-clockwise") below
  the board rather than an in-board gesture, since Ô Ăn Quan's direction choice (unlike
  most mancala games, which are single-direction) needs an unambiguous affordance.
- **Visual board layout vs. model index order are decoupled** (see `BoardView.swift`
  comment) — the loop index order in the spec is followed exactly for game logic, but the
  screen arrangement mirrors B1↔A1 and B5↔A5 spatially (both near the same Quan cell) for
  legibility, which does not match a literal `[..., B5, B4, B3, B2, B1]` left-to-right
  reading of the spec's index list.
- Quan cell "emptiness": since the big 10-point stone is never modeled as an entry in
  `Board.stones`, `Board.isEmpty(_:)` special-cases Quan indices to always return `false`
  — this was necessary to make the capture-chain algorithm correctly treat a Quan cell as
  perpetually non-empty (as the physical game does) without a separate boolean per cell.

## Verification performed

No `@testable` unit test target was added to the Xcode project (none of the sibling apps
have one either). Instead, correctness of `Board`/`GameModel`/`AIEngine` was verified with
a standalone `swiftc`-compiled harness (not checked into this repo) that:
- Unit-tests the capture-chain algorithm directly (basic capture, chained captures,
  two-empties-stop, Quan-cell-stops, immediately-non-empty-next-cell-means-no-capture).
- Runs 300 full games with random legal-move selection to termination, asserting after
  every single move: no negative stone counts, no negative scores, and the combined
  captured score never exceeds the 70-point material cap (50 dân points + 2×10 quan
  points) — confirms no logic path can fabricate or lose material. All 300 games
  terminated cleanly (16–183 moves each) with 400+ forced-borrow events observed across
  the run, confirming that rule fires under normal play, not just in contrived setups.
- Confirms all 3 AI difficulties return only legal moves, and that greedy/hard AI
  correctly prefers a capturing move when one is available.

Also smoke-tested in the simulator via the `OQ_CAPTURE` DEBUG hook (home, onboarding,
midgame board state, upgrade paywall, rules screen, Vietnamese language) — screenshots
visually confirmed correct rendering, no crashes, no layout overflow.

## App Store readiness pass (2026-07-31)

Icon, screenshots, and the legal/privacy site are done. ASC registration/submission is
still a separate, later step (explicitly out of scope for this pass, same as before).

- **Icon**: `make_icon.py` rewritten (was a flat gold-circle-on-green placeholder) into
  the real emblem described above — one dominant bold gold "quan" stone, radially shaded
  for a 3D stone look, 8 small "dân" stones scattered around it, warm wood-brown gradient
  background (`#4a2e18` → `#180e08`) instead of the felt-green used by SamLoc/Fanorona, to
  read as a wooden game board rather than a card table. Verified output is a real
  1024×1024 RGB PNG at
  `OAnQuan/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
- **Screenshots**: `capture_shots.py` ran successfully as-is (no plumbing fixes needed) —
  built the simulator app, drove all 5 scenarios (`home`, `midgame`, `capture`,
  `upgrade`, `rules`) in both `en` and `vi` via the `OQ_CAPTURE`/`OQ_LANG` DEBUG hooks, and
  wrote 10 composited PNGs to `screenshots/final/{en,vi}/`. All 10 were visually
  inspected. Findings:
  - The board layout is correct — all 12 cells (2 Quan + 10 dân) render at consistent
    size with no overlap and no cell blowing up to fill the screen; the earlier
    build-report layout bug is confirmed fixed in these real captures.
  - Vietnamese text renders correctly throughout (proper diacritics, no mojibake), and
    each locale's shots show the correct language with no cross-locale leakage.
  - **Found and fixed a real bug**, not just a screenshot cosmetic issue: the `upgrade`
    scenario screenshot showed a broken-looking "Unable to load purchase option / Try
    Again" error instead of a proper paywall. Root cause: `PurchaseManager`'s DEBUG
    bypass (`isPro = OQ_CAPTURE != "paywall"`) already set `isPro = true` for the
    `upgrade` capture scenario, matching the SamLoc/Fanorona convention — but unlike
    those sibling apps' `UpgradeView`, OAnQuan's `UpgradeView.swift` never actually
    checked `purchases.isPro`, so it fell through to the StoreKit product-load-failed
    state instead of showing an owned confirmation. The `upgrade.owned` localization
    string already existed in both `Localizable.strings` files but was unused — this was
    an accidental omission, not a deliberate design choice. Fixed by adding an
    `if purchases.isPro { Text(L("upgrade.owned"))... }` branch to `UpgradeView.swift`
    (mirroring SamLoc's `UpgradeView`), which also fixes the same broken state for real
    paying users who reopen the paywall after purchasing/restoring — not just a
    screenshot-only fix. Re-ran `capture_shots.py` after the fix and reverified both
    `04-upgrade.png` shots now show "You own Ô Ăn Quan Pro ✓" / "Bạn đã sở hữu Ô Ăn Quan
    Pro ✓" correctly.
- **Legal site**: created `~/Projects/oanquan-legal` (`index.html`, `privacy.html`,
  `support.html`), following the `fanorona-legal` template exactly — same CSS/structure,
  content adapted for Ô Ăn Quan (traditional Vietnamese mancala-family description in
  `index.html`; same no-data-collection/StoreKit-only-IAP/children/contact sections in
  `privacy.html`; a rules-accurate "How to play" section in `support.html` covering the
  sowing-direction choice, the empty-then-full capture-chain rule, the forced-borrowing
  ("mượn") rule, and the 10-point quan-stone convention — plus difficulty levels (Easy/
  Normal free, Hard AI + Play vs Friend paid) and restoring purchases). Pushed to a public
  GitHub repo and GitHub Pages enabled, same config as the sibling `*-legal` repos
  (`source.branch=main`, `source.path=/`). Live at
  **https://qngo9871-cmyk.github.io/oanquan-legal/** (all three pages verified returning
  HTTP 200).

## TODOs for the App Store Connect step (explicitly out of scope here)

- Register `com.quyenngo.oanquan` bundle ID and get a provisioning profile before
  `rebuild.sh`'s device/archive step will succeed.
- No App Store Connect metadata/IAP/pricing work has been done (no `asc_push_oanquan*.py`
  scripts exist yet, unlike SamLoc's).
