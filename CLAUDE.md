## Status 2026-08-24 — DEBUG isPro double-gating bug fixed, code-only, NOT YET submitted

Found by the fixed portfolio-wide `~/asc-tools/compliance_gate.py`: `isPro = OQ_CAPTURE !=
"paywall"` defaulted to unlocked on a bare Debug run and on the "home" capture. Fixed to
also exclude "home" explicitly. **Code fixed and committed only — deliberately not built/
archived/uploaded/submitted yet**, staged for a future day per the staggered-submission
pacing (see memory `project_20260824_debug_gating_submission_queue`). Next: bump version,
archive, upload, `new_version.py`, submit.

**2026-08-24 (later same day) — vision QA pass found the same double-gating bug had a
residual instance, plus a stale-screenshot problem.** The fix above excluded `"home"` from
the isPro override but never excluded `"upgrade"` — this app's own paywall screenshot
scenario name (see `capture_shots.py`) — so `04-upgrade.png` was still capturing with
`isPro=true`, showing a fake "You own Ô Ăn Quan Pro ✓" state instead of a real buy button.
A fresh user would never see that screen; this is the same "screenshot doesn't match
reality" issue that got BauCua rejected under Guideline 2.3.6, just on the paywall instead
of the home screen. Fixed:
- `Core/PurchaseManager.swift`: `isPro` override now also excludes `"upgrade"`.
- `Views/UpgradeView.swift`: added a DEBUG-only branch (mirroring Makruk's proven pattern)
  that renders the real "Unlock — $2.99" button when `productLoadFailed` is true and
  `OQ_CAPTURE == "upgrade"` — local StoreKit testing reliably fails to load a real Product
  via a bare `simctl launch`, same known limitation as Janggi/Dara/Makruk.
- `01-home.png` (en + vi) was also stale — captured before the 7-day-trial-lock feature
  existed (footer read v1.0.2(3), current code is v1.0.3), so it showed no trial banner and
  no lock icon on Hard, misrepresenting current app behavior the same way the Dara home
  screenshot incident did earlier today. Recaptured.
- `capture_shots.py` bugs found and fixed while recapturing: (1) never called `simctl
  erase`, so the trial-day count wasn't deterministic across runs — added; (2) the
  `"upgrade"` shot only waited 2s after launch, nowhere near
  `PurchaseManager.loadProduct()`'s 10s StoreKit timeout, so it non-deterministically
  caught the loading spinner instead of the resolved button — bumped to 12s for that shot;
  (3) a freshly-erased simulator surfaced an iOS "Ready for Apple Intelligence" system
  notification banner over the first capture a few seconds after boot — added an 8s
  settle wait after install so it auto-dismisses before any screenshot.
- All 10 screenshots (5 shots × en/vi) regenerated and individually visually verified
  after the fixes — correct locked/trial state, no stray system UI, no truncation.
- Build verified: `xcodegen generate` + `xcodebuild -sdk iphonesimulator build` →
  **BUILD SUCCEEDED**. Not yet archived/submitted — same staged status as above.

# Ô Ăn Quan — Vietnamese Board Game

Native SwiftUI iOS app for Ô Ăn Quan, the traditional Vietnamese mancala-family board
game. Bundle `com.quyenngo.oanquan`. One app in a 5-app Vietnamese-games lineup (sibling
apps: Fanorona, Dara, SamLoc, ...). Built following the house pattern — read
`~/Projects/Fanorona` and `~/Projects/SamLoc` for the shared conventions this repo mirrors
(PurchaseManager/UpgradeView framing, Core module shape, `Localization.swift`, tooling
scripts).

**Status: 🟢 Ready for resubmission (batch 7, scheduled 2026-09-06).**
This app was one of 19 apps from this developer account hit by an account-level Apple
"Developer Code of Conduct — Review Suspended" flag (almost certainly from submitting ~19
similar template-style board/card games within an 8-day window, 2026-08-01 to 2026-08-08),
not a per-app bug. Resubmission is hard-blocked account-wide until 2026-08-18, and this
app is scheduled in the staggered post-hold plan for **2026-09-06** (batch 7, the final
batch — alongside Hanafuda Koi-Koi and Mythsmith) — see
`~/Projects/app-store-rejections/NOTES.md`. Do not resubmit before that date without the
user's explicit go-ahead. Original submission was app id `6796833584`, version `1.0.0` (id
`02974e1f-0415-4696-9c95-1ba3fc2871b4`), build `df46c053-b79d-4a20-95dc-90506b3ee2af`,
reviewSubmission `0cc80d2d-f422-4a7b-9923-ab68fbc6c7e4`, release type automatic
(`AFTER_APPROVAL`). Two local quality passes since: 2026-08-09 (see "Pre-resubmission
quality review" below) and 2026-08-12 (see "Polish pass" below, current version `1.0.2`
build `3`). ASC metadata/keywords/screenshots for `1.0.2` were pushed live on 2026-08-12
onto the still-REJECTED/editable version `02974e1f-...` — no build has been uploaded to
that version yet, and no review-submission script has been run (out of scope/blocked).

**2026-08-18 — 7-day trial, then everything locks (no permanent free tier).** Portfolio-wide
standing rule now: no app should offer free play at any difficulty forever, only a capped
trial (siblings ChineseChess and SamLoc already carry this pattern; SamLoc's version is the
reference implementation). Before this change, Easy and Normal AI difficulty were free
forever — only Hard AI and Play vs Friend ever required Pro. `PurchaseManager.swift` gained
`trialActive`/`trialDaysRemaining` backed by a `firstLaunchDate` UserDefaults key (7-day
`trialDuration`), with `evaluateTrialStatus()` called from `init()` alongside the existing
transaction-listener setup (merged in, not replacing it). `HomeView.isLocked(_:)` is a new
helper: Pro users always unlocked, Hard always locked (unchanged), Easy/Normal now lock once
the trial expires — previously they never locked at all. Play vs Friend was already
Pro-only in all cases and is unaffected. Existing installs with no stored `firstLaunchDate`
get the clock started by this update rather than being locked out immediately. Added a
"Free trial — %d day(s) left" caption and switched the Home upgrade footnote and
`UpgradeView`'s new subtitle line (previously `upgrade.subtitle` existed in the strings
files but wasn't actually rendered anywhere in `UpgradeView.swift` — added the missing
`Text`) to "trial ended" copy once expired. New keys `home.trialdays`,
`home.upgrade.trialended`, `upgrade.subtitle.trialended` added to both `en.lproj` and
`vi.lproj` `Localizable.strings`. Checked `PurchaseManager.updateEntitlementStatus()`'s
`#if DEBUG isPro = ProcessInfo...["OQ_CAPTURE"] != "paywall"` bypass — it already has a
capture-mode exemption (not the bare unguarded pattern seen in some sibling apps), consistent
with the 2026-08-09 review's finding of "no double-gating bug present," so left untouched.
Clean Debug simulator build succeeded after the change. **Not yet archived/submitted — this
is a real product change to a not-yet-live app still mid-suspension-recovery, holding for the
user's explicit go-ahead, same as the rest of this app's resubmission timeline** (see the
Status note above; this is a code-only change layered on top of the existing batch-7
2026-09-06 plan, not a change to that schedule).

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

## Pre-resubmission quality review (2026-08-09)

Full local code/build/logic review done ahead of the 2026-08-18 Guideline 5.6 resubmission
window — no ASC/App Store Connect access touched (hard-blocked; entirely a local
code/build/git pass). `xcodegen generate` + a clean Debug build for iOS Simulator
(iPhone 17, iOS 26.5) succeeded with **zero errors and zero warnings**.

- **Game logic**: re-verified `Board.swift`/`GameModel.swift`/`AIEngine.swift` line-by-line
  against this file's own ruleset spec above (board layout, sowing, the empty-then-full
  capture chain, Quan-cell-never-empty handling, forced borrowing, game-end scoring). It's
  a complete, correct implementation matching the documented spec exactly — not a stub.
  No changes needed here.
- **Grep for TODO/FIXME/placeholder/Lorem ipsum/dummy text**: none found anywhere in
  `OAnQuan/`.
- **Found and fixed a real bug**: `LocalizationManager`'s in-app language switcher was
  broken. `HomeView`'s segmented Picker binds directly to `$loc.language`; the property's
  `didSet` only persisted the choice to `UserDefaults` but never re-resolved `bundle` —
  only the separate `setLanguage(_:)` method did that, and it was reachable solely via the
  DEBUG `OQ_LANG` screenshot-automation launch arg, never from the real UI. Net effect: a
  live user tapping "Tiếng Việt"/"English" saw the toggle move but no strings actually
  changed until the app was relaunched — directly contradicting this class's own doc
  comment ("...so the in-app language switches live without relaunching") and this
  developer's standing bilingual-in-app rule. Fixed by moving the bundle re-resolution into
  `language`'s `didSet`; `setLanguage(_:)` is now a thin wrapper. Verified via simulator
  screenshots: launching with `OQ_LANG=vi` (which now exercises the exact same `didSet`
  code path as the live Picker) correctly renders all Vietnamese strings with no relaunch.
- **Localization**: `en.lproj`/`vi.lproj` `Localizable.strings` key sets verified identical
  (83 keys each before this pass, 84 after adding `home.record`), both real hand-written
  translations, no missing/stale keys.
- **Onboarding**: real 4-page first-launch walkthrough (`OnboardingView.swift`) covering
  board layout, pick-up/sow, capture chain, and borrowing/scoring — also reachable anytime
  from Home ("How to Play") and in-game (toolbar `?` button). Confirmed present and correct,
  no changes needed.
- **DEBUG isPro/paywall gating**: checked for the double-gating bug pattern seen elsewhere
  in this developer's apps. `PurchaseManager`'s `#if DEBUG isPro = OQ_CAPTURE != "paywall"`
  bypass is intentional (screenshot automation) and consistent — all gate checks
  (`HomeView`'s Hard-AI lock, Play-vs-Friend lock, `UpgradeView`'s owned/buy/restore states)
  read the single `purchases.isPro` published flag with no redundant/conflicting second
  gate found. No double-gating bug present in this app.
- **Small differentiation work** (not a redesign, scoped intentionally small):
  - Added `Core/MatchStats.swift` — a local, on-device-only (UserDefaults, no network) win/
    loss/draw record for vs-AI matches, shown on `HomeView` under the subtitle once a
    player has at least one recorded match ("Your record vs AI: %d W · %d L · %d D" /
    Vietnamese equivalent). Recorded once per match via a new `onChange(of: game.outcome)`
    handler in `GameView`, guarded against double-recording and skipped for pass-and-play
    games (a "win" there isn't a personal record).
  - Added haptic feedback (`UIImpactFeedbackGenerator` on capture,
    `UINotificationFeedbackGenerator` on win/loss/draw) to `GameView` — previously entirely
    absent from the app.
- **Version bump**: `project.yml` `MARKETING_VERSION` `1.0.0` → `1.0.1`,
  `CURRENT_PROJECT_VERSION` `1` → `2`. Verified in a running simulator build (footer shows
  "v1.0.1 (2)").
- **Not done / still open**: no automated UI test for the live language-Picker tap
  specifically (verified indirectly via the shared code path, not a literal tap
  simulation); App Store screenshots (`screenshots/final/`) were not regenerated for
  1.0.1 — still reflect 1.0.0's UI, which is visually unchanged except the new (initially
  hidden, since no match history exists on a fresh install) record line, so this is low
  priority but should be revisited before the actual resubmission if screenshots are
  refreshed for other reasons.

## Polish pass (2026-08-12)

Second, deeper pre-resubmission pass (batch 7, scheduled 2026-09-06) — building on the
2026-08-09 pass above, not redoing it. `xcodegen generate` + a clean Debug simulator build
(iPhone 17 Pro, iOS 26.5) still succeeds with **zero errors and zero warnings**.

- **Re-verified the 2026-08-09 language-switcher fix, specifically mid-session (not just
  cold launch)**: `LocalizationManager.language`'s `didSet` now re-resolves `bundle`
  directly, so the segmented Picker's `$loc.language` binding (which writes straight to
  that property, no `setLanguage(_:)` indirection) exercises the exact same code path a
  real tap does. Verified live in the running simulator process — no OS-level Accessibility
  automation permission was available on this machine to literally tap the control (the
  sandboxed shell isn't Accessibility-trusted; `osascript`/System Events returned error
  -25200 on every attempt), so verification used a temporary `#if DEBUG` hook
  (`OQ_LIVE_SWITCH_TEST`, added to `HomeView`, screenshotted, then fully removed —
  `git diff` is clean of it) that waits ~2.5s after launch and then does the identical
  `loc.language = ...` write the Picker's binding performs. Screenshots before/after in the
  same process (no relaunch) confirm every visible string — title, subtitle, difficulty
  labels, both buttons, the "How to Play"/"Full Rules" links, and the language picker's own
  selected-segment label — re-rendered correctly in Vietnamese with proper diacritics,
  immediately, with no relaunch. The only thing that correctly stayed unlocalized was the
  `v1.0.2 (3)` version footer (by design — it's not a translatable string).
- **Found and fixed a real bug — same class flagged in Janggi this batch**: the `01-home`
  App Store screenshot (both `en` and `vi`) showed the onboarding "The Board" walkthrough
  screen instead of the actual Home screen. Root cause in `ContentView.swift`: the DEBUG
  `OQ_CAPTURE` dispatch explicitly excluded `capture == "home"` from the onboarding-bypass
  branch (`if let capture = ..., capture != "home" { ... }`), so on a fresh
  simulator/install (`hasSeenOnboarding == false`) the `home` scenario fell through to the
  normal first-launch onboarding gate instead of showing `HomeView()` — while every other
  scenario (`midgame`, `capture`, `upgrade`, `rules`, `onboarding` itself) correctly bypassed
  it. Fixed by handling `capture == "home"` explicitly inside the dispatch (returns
  `HomeView()` directly), consistent with how the other scenarios are handled. Confirmed by
  erasing the dedicated capture simulator to a genuinely fresh state and re-running
  `capture_shots.py` — `01-home.png` now correctly shows Home in both locales.
- **Screenshot capture — dedicated simulator device**: created a per-app-named
  `OAnQuan-Capture` simulator (`xcrun simctl create`) instead of using
  `capture_shots.py`'s generic `find_device()` (which regex-matches on device *name*
  "iPhone ... Pro Max" — this session had multiple concurrently-running agents' simulators
  matching that same generic name, e.g. a shared `iPhone 17 Pro Max` already booted by
  another app's capture run). Ran a locally-modified copy of the script (device hardcoded to
  the dedicated UDID) rather than mutating the checked-in `capture_shots.py`. All 10
  regenerated screenshots (`en` + `vi` × 5 scenarios) were visually inspected and confirmed
  to show genuinely OAnQuan's own UI (board, "Ô Ăn Quan" branding, no cross-app leakage),
  correct language per locale, no dead-space/layout bugs, and the `upgrade` scenario still
  correctly shows "You own Ô Ăn Quan Pro ✓" (the 2026-07-31 fix holds).
- **Other UI/onboarding/IAP-gating checks**: `UpgradeView`, `OnboardingView`, and
  `GameView` re-read line-by-line — no dead-space/top-hugging layout bug (`GameView` already
  pins content to the top via `.frame(..., alignment: .top)` + a trailing `Spacer`, the
  correct structure), no `isPro` double-gating (single source of truth, same as the
  2026-08-09 finding), onboarding still a real 4-page walkthrough reachable from Home and
  in-game. No changes needed beyond the `ContentView.swift` fix above.
- **ASO/keyword refresh**: pulled the live ASC listing first — description and promotional
  text in both locales are already strong, specific, and accurate (no rewrite needed, per
  house guidance to only touch weak copy). Refreshed **keywords only**: dropped terms
  redundant with the already-indexed app name/subtitle (`o an quan`, `ô ăn quan`,
  `vietnamese mancala` — all literally in the en-US name; `ô ăn quan`, `o an quan`,
  `cờ dân gian`, `trò chơi dân gian`, `rải quân`, `ăn quân` — all literally in the vi
  name/subtitle), freeing up the 100-char budget for non-redundant, higher-value
  mancala-family/regional terms: en-US now `board game,offline,strategy,two player,
  congkak,sungka,mancala family,vietnamese folk,ai game` (92 chars); vi now
  `cờ chiến thuật,hai người,offline,cờ truyền thống,trò chơi trẻ em,giải trí gia đình,
  cờ gánh,mancala` (98 chars).
- **`asc_push_oanquan.py` bugs found and fixed before trusting it** (same bug classes
  flagged elsewhere in this batch's push scripts):
  - `find_app_info` picked the *first* appInfo in an editable state with no fallback
    ordering — harmless today (this app has only one appInfo) but the same shape as the
    Janggi/Omweso bug where a locked appInfo could get picked over an editable one when
    multiple exist. Rewritten to try genuinely-editable states first, locked states only as
    a fallback (mirrors Omweso's already-fixed version).
  - `find_or_create_version` hardcoded the target version string to the stale `"1.0.0"` —
    would have silently re-pushed 1.0.0 instead of bumping to this pass's `1.0.2`. Pulled
    into a `TARGET_VERSION` constant kept in sync with `project.yml`. The function only ever
    matches draft/rejected states (never a live version), so — unlike Janggi's version of
    this bug — there was no risk of clobbering a `READY_FOR_SALE` version, just a stale
    target string.
  - `set_iap_localization` and `set_iap_price` had no error handling — confirmed this is a
    real, live failure mode (not hypothetical): running the fixed script hit real `409`s
    ("Version is not in modifiable state" / "IS_FAMILY_SHAREABLE can not be modified") on
    the IAP, which is presumably still attached to the original rejected review submission.
    Without the fix, this would have crashed the script before it ever reached the Pricing
    section below it, silently skipping the app-base-price and IAP-price pushes too. Now
    wrapped in `try/except RuntimeError`, reports and continues (mirrors Omweso's fix); app
    base price (Free) and IAP price ($2.99) both confirmed set successfully in the same run.
- **ASC push confirmed**: ran `asc_push_oanquan.py`, then re-read the listing via
  `asc_inspect_listing.py` — landed on `v1.0.2 [REJECTED]` at the same version id
  `02974e1f-0415-4696-9c95-1ba3fc2871b4` (confirmed still the editable one, not a new/live
  version), with the refreshed keywords present on both locales. Then ran
  `asc_push_oanquan_screenshots.py` — all 10 screenshots uploaded successfully to that same
  version/locale pair.
- **Version bump**: `project.yml` `MARKETING_VERSION` `1.0.1` → `1.0.2`,
  `CURRENT_PROJECT_VERSION` `2` → `3` (both the project-level and target-level blocks).
  Verified in the running simulator build and in the regenerated screenshots (footer shows
  "v1.0.2 (3)").
- **Not done / still open**: no build has been uploaded to ASC for `1.0.2` yet (archive/
  export/upload step, plus ticking the IAP into the version, are both still needed before
  actual submission — same as before, out of scope for this metadata-only pass); the IAP's
  own localization/price are apparently still locked to the original rejected review
  submission (see the 409s above) — worth a fresh look right before the 2026-09-06
  resubmission in case that clears on its own once the review-submission item is
  cancelled/recreated (see `~/asc-tools/asc_submit_woktonight.py` for the pattern, and
  [[asc_resubmit_after_rejection]]).

## Build staged for resubmission (2026-08-13)

Archived, exported, and uploaded a Release build ahead of the staggered resubmission — still
blocked until 2026-08-18 by the Guideline 5.6 account-level hold, this app resubmits
**2026-09-06** (batch 7). Build **1.0.2 (3)** uploaded via
`xcrun altool --upload-app` (Delivery UUID `16cf9903-cb03-4283-8489-e57ac0048010`), processed to `VALID` by Apple, and
attached to the existing `REJECTED` appStoreVersion (id `02974e1f-0415-4696-9c95-1ba3fc2871b4`) via a direct
`PATCH appStoreVersions/{id}/relationships/build` API call — independently re-verified via a
follow-up `GET` on the same relationship, not just trusted from the PATCH's 204 response.

**Deliberately NOT done yet** — waiting for the user's explicit go-ahead on this app's
scheduled date, per the staggered resubmission plan:
1. Tick the Pro IAP into this version in the App Store Connect **web UI** — the API has no
   way to do this; it must be done from the version's own page (not the IAP's own page, which
   creates an orphaned draft submission — a mistake this portfolio hit once before).
2. Submit for review.

## Build 4 (v1.0.3) archived/exported/uploaded — 2026-08-18, NOT attached, NOT submitted

Today's trial-clock commit (`9f85c74`, "Add 7-day trial clock, lock all AI difficulties after
trial expires") landed as new code on top of the already-uploaded build 3 (v1.0.2, attached to
version `02974e1f-...` since 2026-08-13). Since ASC already had build number `3` in use and
`git status`/`git diff` were otherwise clean (no other uncommitted changes found), this pass
bumped past it for a fresh build carrying the trial-clock code:

- **Version bump**: `project.yml` (both `settings.base` and target `settings.base` blocks)
  `MARKETING_VERSION` `1.0.2` → **`1.0.3`**, `CURRENT_PROJECT_VERSION` `3` → **`4`** — higher
  than both the local prior value and ASC's highest existing versionString (`1.0.2`) / build
  number (`3`). `xcodegen generate` re-run, `project.pbxproj` confirmed updated (4/4
  occurrences each key).
- **Archive/export/upload**: `xcodebuild archive` → `** ARCHIVE SUCCEEDED **`; `-exportArchive`
  (existing `ExportOptions.plist`, `method=app-store`, unchanged) → `** EXPORT SUCCEEDED **`;
  `xcrun altool --upload-app` → `UPLOAD SUCCEEDED`, Delivery UUID
  `3158d1ca-1fe6-410b-b9ea-a3e429c3b50e`.
- **Processing**: polled `GET /v1/apps/6796833584/builds` — build
  `3158d1ca-1fe6-410b-b9ea-a3e429c3b50e` (`version: "4"`) reached **`processingState: VALID`**.
- **Deliberately NOT done**: no `appStoreVersion` created, build not attached to anything, no
  `reviewSubmission` touched, **not submitted for review**. This app is still scheduled for
  batch-7 resubmission on **2026-09-06** — nothing here changes that schedule; this build is
  just staged and available in ASC for whenever the user proceeds.

## TODOs for the App Store Connect step (explicitly out of scope here)

- Register `com.quyenngo.oanquan` bundle ID and get a provisioning profile before
  `rebuild.sh`'s device/archive step will succeed — already done (the app has a live ASC
  record and this repo has archived/uploaded a build before), noted here only because an
  earlier version of this doc said otherwise.
- App Store Connect metadata (name/subtitle/keywords/description/promo/support URL),
  categories, IAP, and pricing are all live-pushed via `~/asc-tools/asc_push_oanquan.py`
  (idempotent — re-run after any copy change) and
  `~/asc-tools/asc_push_oanquan_screenshots.py`. No review-submission script exists yet for
  this app (see the "Deploy / resubmit pattern" section at the top) — that's the remaining
  step before the 2026-09-06 resubmission.
