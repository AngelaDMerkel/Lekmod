# Resumed macOS single-player checks, 2026-09-13

Scope: focused checks against the existing standard-UI installation. No long
turn campaign, multiplayer, EUI deployment, Docker/Steam modification, or
GameCore installation. The user explicitly authorized continued foreground
checks. Each foreground run retained the 180-second supervisor limit.

## Reproduction and configuration

Checkout at resume: `ef173459` on existing `codex/shared-macos-gamecore`, clean.
No branch was created or switched for these tests. The handoff's fourteen dirty files had
already been committed by another task in `0952b9e5`; these and the following
shared-compatibility refactor are preserved.

All foreground runs below use:

```sh
python3 LEKMOD_DLL/macos/automated-playtest.py --mode ui-interaction --turns 3 --timeout 180 --stall-seconds 180 --load-save /Users/duffy/Documents/GitHub/Lekmod/build/macos/playtests/20260913T020332Z/Lekmod-Functional-20260913T020332Z.Civ5Save --foreground-attachment-test
```

`--turns 3` is required argument validation; this mode sends no turn commands.
The fixture starts on turn 214 with Rome, population 4, 134 gold, 12 majors,
40 city-states, and religion disabled. Fixture SHA-256:
`9c4760dda103a62025b5e859ab4dbe10db25537b5d8d7410cbf91eb3a31f1bc6`.
Installed signed GameCore SHA-256:
`ada65581fbe74cce79801c92690923d0a35fd50d1fcbf093cfcabcfc923fa40a`.
The newer local build was not installed; these are not runtime tests of the
shared-compatibility rebuild.

Paths in this report are under `build/macos/playtests/`. Reports, logs, and
screenshots are local Git-ignored evidence. Inputs used the native computer-use
interface and fresh screenshots. The read-only observer does not invoke
production, specialist, city, or exit callbacks. Startup/loading uses the
existing temporary setup adapters, so the whole launch is not a mouse test.

## Actual input and observed outcomes

### `20260913T202937Z`: attachment timeout, no input result

The first native attachment was requested too early and timed out after about
633 seconds despite its shorter requested tool timeout. The supervisor bounded
its game to 183.8 seconds, then used SIGTERM/SIGKILL. Settings/hooks restored;
no Lua runtime errors, sync failures, or new Civ V diagnostics. No physical
input was sent. This remains incomplete, not a gameplay crash or normal exit.
A delayed test-created Aspyr launcher remained; SIGTERM did not close it.

### `20260913T204202Z`: physical normal exit

The actual game was registered and foreground, but native attachment returned
the `AppBundleExe` launcher sharing its bundle ID. Command-Q closed the launcher;
process verification then showed only the supervised game. Reattachment exposed
the game's rasterized window. Do not click PLAY in a leftover launcher.

A city-banner click did not establish a city-control result (the camera moved).
Escape then opened the menu. Actual mouse clicks on Exit to Windows and Yes
closed Civ V with process code 0 at 176.7 seconds. No supervisor stop/signals,
Lua runtime errors, sync failures, or new Civ V diagnostics. Settings/hooks
restored. This verifies the physical exit path, not physical saving or loading.

### `20260913T204544Z`: Worker and Workshop specialist

After `ui-observer-ready`, attachment reached the game without a competing
launcher. Actual mouse sequence: Rome banner → Change Production → Worker;
Workshop specialist slot → Return to Map; Rome banner → filled Workshop slot
→ Manual Specialist Control → Return to Map; Escape → Exit to Windows → Yes.

Expected: Worker replaces Wealth, adding an engineer takes a citizen off a
worked tile and changes production/food, removing it restores the assignment.
Observed engine state: queue `4,0` (Wealth) → `0,1` (Worker); Workshop building
72 specialist count 0 → 1 → 0; worked plot 1 removed then restored. Production
9.9 → 11 → 9.9; gross food 11 → 10 → 11 (displayed surplus +3 → +2 → +3).
Gold output changes 7.47 → 5 when Wealth stops; treasury remains 134 and unit
IDs remain unchanged. This proves selection and assignment, not Worker
completion or a comprehensive yield formula audit.

The preserved `workshop-specialist.png` is 2836×1898, SHA-256
`6396150d099cc31a89b1d3662e3fa65f09a58b0a8eb48169d1cbfc2af4570987`.
The city controls and production/food values are visible. The original HUD
observer recorded changes on returning to the map; subsequent tooling also
observes CityView to retain intermediate changes while that panel is open.
Normal process exit code 0 at 178.8 seconds; no supervisor stop/signals, Lua
runtime errors, sync failures, or new Civ V diagnostics. Settings/hooks restored.

### `20260913T205017Z`: Walls purchase, append and reorder

Actual mouse sequence: Rome banner → Purchase → Walls; Change Production →
Worker; Show Queue → Add to Queue → Water Mill → Back; Water Mill up-arrow.
Expected: gold buys an immediate building without changing the Wealth queue;
appending retains Worker first, and the up-arrow reverses the two orders.
Observed: treasury 134 → 14, real Walls building 22 count 0 → 1, displayed
city defense 56 → 61. Queue remained `4,0` after purchase, then changed to
`0,1`, `0,1;1,20`, and `1,20;0,1` respectively. These states were recorded
inside CityView, confirming the observer now retains intermediate changes.

The later Worker-remove/Return/Escape attempt reached the time cap before an
observed removal or normal exit. No removal pass is claimed. The supervisor
terminated its own game at 184.2 seconds using SIGTERM/SIGKILL; settings/hooks
restored, no Lua runtime errors, synchronization failures, or new diagnostics.
This is a set of observed purchase/queue results inside an interrupted session,
not an overall passing manual session or a successful production-completion test.
Unit purchasing remains untested: the displayed Worker purchase was disabled
in the crowded starting capital, and no unit purchase was attempted.

## Scripted production outcomes and driver regressions

Reproduction uses the same untouched Modern save:

```sh
python3 LEKMOD_DLL/macos/automated-playtest.py --mode human-turns --turns 3 --timeout 300 --stall-seconds 180 --load-save /Users/duffy/Documents/GitHub/Lekmod/build/macos/playtests/20260913T020332Z/Lekmod-Functional-20260913T020332Z.Civ5Save --production-completion
```

The fixture sets Worker then Water Mill through the normal synchronized order
API. It grants no resources, technology, units, buildings, or production. The
ordinary driver makes required research/policy/ideology decisions and invokes
the standard end-turn handler; none of these are physical input claims.
Completion requires both `CityTrained`/`CityConstructed` engine hooks with gold
and faith flags false, plus the resulting new Worker ID and real building count.
This excludes purchase or a free policy Worker from masquerading as production.

- `20260913T205741Z` reproduced a driver defect before any end turn: its
  unstacking fallback rejected every occupied tile, even legal civilian/military
  sharing. Removing that extra restriction while retaining the engine's
  `CanMoveOrAttackInto` query enabled the ordinary move of settler 16385 to
  (24,57). Live refresh was acknowledged in the log. A second unhandled required
  decision was ideology (blocking type 23). The second refresh submitted the
  same `Network.SendIdeologyChoice` used by Aspyr's confirmation callback,
  selected Freedom (branch 9), and verified `GetLateGamePolicyTree`. No decision,
  semaphore or synchronization check was bypassed. Both items then completed
  within three turns. The report retains its original driver error, hold and
  two refresh acknowledgments; it is not a clean replay from final sources.
- `20260913T210313Z` reloaded the untouched save using the fixed driver from
  startup. No driver errors, holds or refreshes occurred. Engine events and
  state checks identify new Worker 90112 (type 1) on turn 215 and Water Mill
  (building 20, city 8192) on turn 217. Turns 215–217 completed consecutively and
  returned to the human player. Freedom was selected and verified on turn 215.
  Runtime was 122.9 seconds. This is the reproduction without intervention.

Both background runs preserved the activation guard, recorded no Lua runtime
errors, synchronization failures or new Civ V diagnostics, and restored
settings/UI hooks. After verifying the outcomes the supervisor terminated its
own process with SIGTERM/SIGKILL; these are not normal-exit results. These six
focused turn completions across two replays do not reopen or extend the accepted
long campaign. Wonder completion, unit purchases, religion, trade routes,
espionage, Congress and broader late-game correctness remain outside this result.

## Yield accounting limit and unresolved warning

The initial fixture records base production 9 and multiplier 110%. Worked plot
1 supplies one food and one production; the Workshop tooltip advertises two
production for its engineer. The narrow expected change is therefore
`(9 - 1 + 2) × 1.10 = 11`, compared with `9 × 1.10 = 9.9`; removing one food
from gross 11 gives gross 10. This matches the specialist run and its inverse.
Other modifiers, specialist types, focus effects and tile assignments still
need separate checks.

Background logs also contain `Lekmod_improvements` messages saying the
`Improvement_Adjacency_Yields` table does not exist. A repository search found
only this Lua consumer, with no table definition or data rows. Its guarded
handler returns without applying adjacency rules. The warning is preserved;
these passes do not establish that this generic adjacency feature works or
that the warning is a macOS-specific regression. No speculative schema or
balance rules were added, and no warning was suppressed.

## Verification and cleanup

Focused local commits: `82a57031` fixes the two test-driver defects;
`13f9c622` adds the city observer, bounded completion fixture, classifier checks
and operator guide. These are test-tool changes, not new GameCore defect fixes.
The earlier Lua city-state/barbarian exclusions and shared compatibility work
remain unchanged.

The final runner/classifier suite has 17 passing checks (including completion
versus selection, skipped outcomes and bounded argument validation), and the
five isolated UI-configuration checks pass. Native outcomes above test the Lua
adapters and driver in the installed game. The offline suite is not an EUI
runtime pass, a fresh GameCore build, or certification of the newer local DLL.
The two handoff saves and installed GameCore retain their original hashes.
No manual save was written or overwritten in these runs; rotating autosaves are
preserved in each run's before/after directories. No push was performed.
Final process inspection found no game, launcher or supervisor remaining, Steam
still at PID 99607 and inactive, and Codex frontmost. A scan of the installed
standard/expansion UI directories found no leftover test-hook markers. Original
UI/configuration bytes, the Aspyr backup, and both fixture hashes were verified.
