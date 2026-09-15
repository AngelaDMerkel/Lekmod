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

The desktop locked before the EUI attempt could launch a game. The inner runner
refused, and wrapper evidence at `build/macos/eui-tests/20260915T105302Z/state.json`
confirms restoration of the standard package, EUI text and EUI options. No EUI
mouse pass is claimed for that attempt. Testing permission remains in effect;
the desktop must be unlocked before continuation.

The wrapper now checks desktop/Steam readiness before changing the installation,
and the inner runner still rechecks immediately before launch. Offline tests
cover refusal without installer calls and preservation after a failed child run.
