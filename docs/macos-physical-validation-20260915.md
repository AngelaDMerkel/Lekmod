# macOS physical UI validation — 2026-09-15

The user restored foreground permission and explicitly allowed sessions as long
as required. The old three-minute limit is historical. These tests use a
20-minute recovery timeout and close normally as soon as the checks finish.
No multiplayer or further long-turn campaign is included.

## Standard UI

Run: `build/macos/playtests/20260915T104347Z`. The actual game used the clean
standard package documented in [the system report](macos-single-player-systems.md),
with signed GameCore SHA-256
`04904d1ff7d8db789816b8fe900d4518ed77bb5a5e1032f727b180a84e60b40c`.
Requested window size was 1280×800, captured at 2560×1656 backing pixels.

The prepared save was
`build/macos/playtests/20260914T041903Z/Lekmod-Functional-20260914T041903Z.Civ5Save`,
SHA-256 `596f3151a32f222d516ed08b8ef25c0c9f87fce384c2fff0b7c181b54579c7dc`.
It already contained ordinary Worker and Water Mill orders. Loading-screen
dismissal was scripted. All actions below were actual CUA mouse/key input;
the separate Lua observer only read state and did not replace UI update handlers.

| Action | Observed result |
| --- | --- |
| Click Rome, Show Queue, Water Mill X | Queue changed from Worker + Water Mill to Worker alone. Treasury, unit state and yields stayed unchanged. |
| Click unworked plot 2 | Plot 2 became forced-worked and displaced plot 1. Both plots yield one food/one production, so city yields stayed unchanged. |
| Click unworked plot 3 | Plots 2 and 3 became forced-worked; plot 5 was displaced. Gross food fell 11 → 10; base production rose 9 → 10 and total production rose 9.9 → 11 at the observed 110% modifier. |
| Click Reset Tiles | Original worked set 0,1,4,5,6 returned, with every forced flag false. Original food, production and all other recorded yields were restored. |
| Click Return to Map, Choose Research, Open Technology Tree, Close | The full Close button was visible at the smaller size and the physical click returned to the map/research panel. |
| Escape → Exit to Windows → Yes | Game exited with code 0, without a supervisor stop or termination signals. |

The session lasted 419.2 seconds including startup and instrumentation. No turn
was ended and no manual save was overwritten. Settings, graphics configuration
and temporary UI hooks were restored; all prior manual saves were preserved.
There were no Lua runtime errors, synchronization failures or new diagnostics.

`physical-validation.json` contains assertions against the observer records and
image hashes. Captures are `standard-queue-removed.png`,
`standard-tile-assigned.png`, `standard-tile-yields.png`, and
`standard-tech-tree-small.png` in the run directory. The original runner report
retains its `ended-manual-ui-session` classification; the supplemental record
identifies only these verified physical checks.

## EUI

### Earlier locked-desktop attempt

The desktop locked before the EUI attempt could launch a game. The inner runner
refused, and wrapper evidence at `build/macos/eui-tests/20260915T105302Z/state.json`
confirms restoration of the standard package, EUI text and EUI options. No EUI
mouse pass is claimed for that attempt. Testing permission remains in effect;
the desktop must be unlocked before continuation.

The wrapper now checks desktop/Steam readiness before changing the installation,
and the inner runner still rechecks immediately before launch. Offline tests
cover refusal without installer calls and preservation after a failed child run.

### Completed foreground session

Run `build/macos/playtests/20260915T222014Z` used EUI 1.28g at requested
1280×800 with the same signed GameCore. The private EUI package was
`Lekmod-native-eui128g-test.zip` (SHA-256
`14e27217075bdf99f99f1c21faba2801472a605a932f3ea4806c2ed98002b73d`).
The wrapper restored the clean standard package after the session.

| Actual input | Verified result |
| --- | --- |
| City banner and Water Mill queue X | City opened; Water Mill alone was removed, leaving Worker queued. |
| Food Focus, then Default Focus | Focus enum changed −1 → 0 → −1 through the visible radio controls. |
| Workshop engineer slot, then removal | Specialist count 0 → 1 → 0; gross food 11 → 10 → 11 and production 9.9 → 11 → 9.9. Automatic specialist management was explicitly restored. |
| Two tile assignments, then Reset Tiles | Forced-work flags and food/production changed as in the standard test; reset restored the complete initial worked set and all recorded yields. |
| Aqueduct's 120-gold button | Treasury 134 → 14; building 67 appeared with count 1. No turn was needed and no resource budget was supplied. |
| Caravansary list entry, then queue drag | Added building 38 after Worker, then dragged it ahead: `0,1;1,38` → `1,38;0,1`. This is selection/reordering, not completed production. |
| Choose Research, then technology-tree Close | EUI's tree opened at the current era, with Close in bounds; the mouse click returned to the map. |
| Save Game, typed unique filename, Save | Created `EUI-Mouse-20260915.Civ5Save`; no overwrite confirmation was used. |
| Post-save Food Focus, then Load Game / select new save / Load | Reload restored saved Default Focus and exactly matched the pre-save observed treasury, buildings, queue, worked plots, units and yields. Loading-screen dismissal was scripted. |
| Escape / Exit to Windows / Yes | Normal exit code 0, with no supervisor stop or termination signals. |

The new save's SHA-256 is
`109403c6c01822122636ac7d6bb46f77b60e77bb672c5cd0ecebeb74a427d63d`; a copy is
in the run directory. Ordinary text entry and forward Delete produced the
verified filename. Select-all/End shortcut behavior was not established, so no
shortcut pass is claimed. The post-save focus change makes the reload check
distinguishable from merely observing unchanged state.

The session lasted 1007.7 seconds and did not advance a turn. The original report
remains `ended-manual-ui-session`. `physical-validation.json` asserts the state
transitions and exact post-reload observation match and indexes seven screenshots.
No Lua runtime errors, synchronization failures or new diagnostics were recorded.
All prior manual saves, settings, graphics and UI hooks were preserved/restored.
Wrapper `build/macos/eui-tests/20260915T222005Z/state.json` confirms restoration of
the standard payload, EUI text and EUI options database/journals. Independent
checks matched the standard payload and DLL to the clean archive, preserved the
Aspyr backup, found no EUI folder or Civ V process, and verified Steam inactive.

These selected standard/EUI mouse workflows are now complete. They do not prove
every EUI popup, every civilization ability, every victory route, other macOS
versions or multiplayer support. The broader limitations in the system report
remain explicit.
