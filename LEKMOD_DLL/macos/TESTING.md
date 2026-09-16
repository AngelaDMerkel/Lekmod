# Native macOS test tools

Read [the current handoff](../../docs/macos-testing-handoff.md) before resuming
this user's tests. [Validation status](../../docs/macos-validation.md) records
what actually passed and what remains untested. These tools are not a full-port
certification suite or part of the installed mod UI.

## Offline checks (do not launch the game)

From the repository root, with Python 3 and Xcode Command Line Tools:

```sh
python3 LEKMOD_DLL/macos/test-configure-ui.py
python3 LEKMOD_DLL/macos/test-automated-playtest.py
python3 LEKMOD_DLL/macos/test-lua-script-data.py
python3 LEKMOD_DLL/macos/test-batch-allocate.py
clang++ -std=c++11 LEKMOD_DLL/macos/test-random-seed.cpp -o /tmp/lekmod-rng-check
/tmp/lekmod-rng-check
```

Product Lua handler regressions use the game's Lua 5.1.4 language version:

```sh
python3 LEKMOD_DLL/macos/bootstrap-test-lua.py
python3 LEKMOD_DLL/macos/test-unit-handlers.py
python3 LEKMOD_DLL/macos/test-scenario-core.py
python3 LEKMOD_DLL/macos/test-lua-unit-position.py
python3 LEKMOD_DLL/macos/test-lua-team-tech.py
python3 LEKMOD_DLL/macos/test-trade-building-cache.py
```

The bootstrap downloads the official `lua-5.1.4.tar.gz` once, verifies SHA-256
`b038e225eaf2a5b57c9bcc35cd13aa8c6c8288ef493d52970c9545074098af3a`, and builds
under Git-ignored `build/macos/test-deps`. It installs no system software. The
tests are offline after bootstrap, or accept `--lua /path/to/lua5.1`. They run
the actual product files with small engine stand-ins; they do not establish
native unit integration, which must also be checked with the release artifact.

The UI tests use isolated template copies, not the installed app. EUI template
assembly/XML tests do not establish runtime EUI compatibility. The sanitizer
tests extract actual binding/allocator code with minimal engine stand-ins;
they do not replace native integration or ABI validation.

## Prerequisites and scope

- Use the default Steam Civ V app/data paths defined at the top of
  `automated-playtest.py`. Review them before use on another machine.
- Civ V must be closed. Steam must already be running and signed in. The runner
  never starts Steam, changes its channel, or interacts with Docker.
- Startup requires an unlocked local graphical session. Do not unlock or
  bypass login automatically.
- The installed GameCore must provide `LekmodMacDiagnostics.h` event logging.
  The runner reads newly appended `LekmodRender.log` records. It does not build
  or install GameCore. The committed diagnostic implementation currently logs
  macOS events unconditionally; it is diagnostic instrumentation, not a claim
  of production-ready logging policy.
- Always pass an explicit mode and time budget. Historical defaults are
  **autorun / 100 turns / two hours**. This user's long turn phase is finished;
  do not invoke those defaults or reinstate the waived quota.
- App/data writes and process inspection may require running outside an agent's
  filesystem sandbox. That is not permission to expand the testing scope.

## Modes and evidence limits

| Mode | Behavior | What it does not establish |
| --- | --- | --- |
| `human-turns` | Human player, automated choices through normal game actions; counts additional consecutive completed turns | Physical input, good strategy, comprehensive gameplay |
| `autorun` | AI/observer turn run | Human/AI UI handoff or mouse interaction |
| `single-player-smoke` | Script-data, focus/growth, tech-tree and production callback checks; no end-turn commands | Physical input, completed production, all gameplay systems |
| `ui-interaction` | Loads a fixture; read-only HUD observer; no automated game choices | Automatic pass/fail classification of manual UI interactions |

New functional fixtures found a capital using a legal settler action. Loading
an autosave may finish the stored turn before tests begin. `--start-era` uses
ordinary setup options for new matches; it is ignored when loading a save.
Modern-era starts disable religion and cannot be used to certify it.

Useful functional options:

- `--city-controls`: use all nine actual CityView focus callbacks and
  avoid-growth toggle/restore, instead of the shorter direct-command checks.
- `--capture-panels`: hold panels briefly for game-window-only screenshots.
- `--save-and-exit`: create a uniquely named **local** `Lekmod-Functional-…`
  save, then invoke the existing save/exit confirmation callbacks.
- `--expected-state /path/to/prior/report.json`: compare that report's saved
  fingerprint on reload before test mutations. A partial fingerprint match is
  not byte-for-byte verification of every serialized game subsystem.
- A `SKIP` for a production category means the fixture has no legal item.
  It must remain untested, even if the overall status says available checks passed.

Example bounded callback suite (replace the fixture path):

```sh
python3 LEKMOD_DLL/macos/automated-playtest.py \
  --mode single-player-smoke --turns 3 --timeout 300 --stall-seconds 180 \
  --load-save /absolute/path/to/test.Civ5Save \
  --city-controls --capture-panels --save-and-exit
```

`--turns` is ignored for functional/UI-interaction completion; the current
shared argument validation still requires at least 3. It counts **additional**
turn ends only in turn modes. A new run's `--majors/--minors` report fields are
requested settings; for a loaded save, verify the actual `loaded-roster` log.

## Background and native UI control

The default helper blocks game activation and raises no windows. Capture uses
only a specified Civ V process, not the entire desktop. The fallback capture
helper requires macOS 14+ and existing screen-recording permission. Build it
if the binary is absent; the runner currently builds the other helpers itself:

```sh
mkdir -p build/macos
clang -fobjc-arc -mmacosx-version-min=14.0 \
  -framework AppKit -framework Foundation -framework CoreGraphics \
  -framework ScreenCaptureKit -framework ImageIO \
  LEKMOD_DLL/macos/capture-test-window.m -o build/macos/capture-test-window
```

Native control successfully attached with the game foregrounded and the guard
disabled. Attachment with the guarded background fixture timed out. This does
not isolate which condition is necessary. Do not silently remove the guard.

`--foreground-ui-test` (legacy alias `--foreground-attachment-test`) requires
`ui-interaction` and an explicit `--timeout` no greater than 3600 seconds. The
user restored permission on 2026-09-15 and allowed sessions as long as required;
the previous 180-second limit describes older sessions. A 1200-second recovery
timeout is used for current checks, with normal exit as soon as they finish.
The flag never grants user permission. Desktop-lock and existing-Steam checks
remain mandatory; no synchronization or GameCore wait flag may be bypassed.

Use the provided native computer-use interface for actual UI input. App ID:
`com.aspyr.civ5xp.steam`. Do not try to attach using the direct executable path;
the interface rejected it. `getApp` can launch the launcher if no game exists,
so check process state first and do not call it after successfully quitting.
The app exposes a window, not separate accessibility nodes for its rasterized
game controls. Derive coordinates from fresh screenshots, not this document.

Wait for the runner's `ui-observer-ready` event and verify that the registered
process is `Contents/MacOS/Civilization V` before attaching. `AppBundleExe`
shares the bundle ID and can misdirect attachment. In the resumed tests an
early attachment timed out, then left a launcher after the game had exited;
closing that test-created launcher allowed attachment to the actual game.
Do not click PLAY in a leftover launcher or terminate a user-owned instance.

The read-only observer records full queue order, gold, built buildings,
specialist assignments, yields in hundredths, worked/locked plot indices, and
unit IDs/types/positions when they change. These records are retained in
`report.json` as `ui_observations`; they do not automatically certify mouse
actions, correct yield accounting, or production completion. Record actual
inputs and expected/observed outcomes separately.

The observer is appended to both ActionInfoPanel and CityView: the HUD's update
callback pauses while the city panel is visible. `context` identifies the source.
Base yields, yield multipliers, worked-plot food/production/gold and manual
specialist mode are also recorded. Observations wait for an active human turn
and normal message processing to finish; they never clear processing flags.

## Bounded production completion

The Modern manual fixture listed in the handoff supports a one-turn Worker
followed by a two-turn Water Mill. To verify actual production outcomes:

```sh
python3 LEKMOD_DLL/macos/automated-playtest.py \
  --mode human-turns --turns 3 --timeout 300 --stall-seconds 180 \
  --load-save /absolute/path/to/the/Modern-fixture.Civ5Save \
  --production-completion
```

This option requires a loaded human fixture, exactly three as the turn bound,
and at most 600 seconds. It replaces the queue through normal synchronized
orders; no gold, units, buildings, production or technology are granted. The
ordinary driver resolves legal stacking moves and required research/policy/
ideology choices, and calls the normal end-turn handler. Both completion events
must have gold/faith purchase flags false, then the new Worker ID and actual
Water Mill count must be observed. It stops after both outcomes or fails after
three turns; selection callbacks, elapsed time, or skipped items cannot pass it.
This is a focused outcome check, not a restart of the accepted long campaign.

## Focused system scenarios

`single-player-smoke --scenario inventory` records a read-only inventory of
religions, cities, spies and routes in a loaded save. It does not certify those
systems. `--scenario espionage` uses an existing unassigned spy and the game's
available-city list to test home/foreign deployment, recall and diplomat role
selection through ordinary network commands. It grants no spies or resources.
Travelling state is checked; intelligence generation is a separate outcome.

Scenarios require `--load-save` and an explicit budget of at most 1800 seconds.
`--save-and-exit` uses the same normal local save/exit adapters. Reload the new
unique save with the same scenario and `--expected-state prior/report.json` to
compare its scenario snapshot before changes. Reload reports only the state
check, not another pass of the original action sequence. Scenario snapshots use
deterministic JSON with escaped strings; snapshots describe their selected
subsystems rather than every serialized game field.

## Supervision and recovery

Every run has a unique `build/macos/playtests/<UTC>/` directory containing
original settings/UI copies, before/after logs and rotating autosaves, process
output, `run-state.json`, and final `report.json`. `build/` is Git-ignored.
Existing user manual saves are not overwritten. Functional tests can create new
uniquely named manual test saves, with copies also retained in their evidence.

Prefer normal in-game exit. To interrupt an automated run, send SIGINT to the
**verified `runner_pid`** in its `run-state.json`, not a guessed PID or all
Python/game processes. Its `finally` block closes only its own game, escalating
to TERM/KILL if needed, and restores settings/hooks. Do not SIGKILL the runner;
that prevents restoration. If it did die, first verify no game/test is running,
then inspect that run's `config.ini.original`, `UserSettings.ini.original`,
`ui-original/`, and the exact templates selected by its mode. Restore only those
known files; do not overwrite user changes blindly. Check the fullscreen
preference separately if final cleanup did not execute.

`ui-interaction` deliberately does not classify idle human turns as stalls and
does not automatically award a pass. Normal/manual-ended sessions can return
nonzero from the CLI; read the report. Conversely, a process exit code of -9
with `runner_requested_stop`/SIGKILL is not proof of a game crash. Check new
diagnostic reports, log errors, event continuity, and your observed interactions.

For human-driver errors/prompts, `--refresh-driver /absolute/evidence/directory`
updates only a live test's temporary driver. Wait for the game's
`driver-reloaded` acknowledgment. It does not update separate diplomacy contexts.
Do not clear GameCore wait flags or suppress synchronization checks to resume.

Known tool limitations: startup's separate timeout does not cover every stage
of asset loading; the overall timeout is the reliable bound. Live functional
metadata in `run-state.json` is incomplete until the report is finalized. The
human bot is not a strategy evaluator and can make economically poor choices.

### Explicit turn allowance and scenario setup

Scenarios default to zero end-turn commands. `--scenario-turns N` (0–30) lets
that scenario request steps from the ordinary human driver; its remaining
research/policy/unit decisions and end-turn checks stay intact. The scenario
supervisor rejects requests beyond that bound. The total scenario budget is at
most 1800 seconds. The extended recovery time follows the user's authorization
for longer sessions; the thirty-turn bound remains. These are functional
fixtures, not a resumed long campaign. Turn-using scenarios temporarily request
an autosave every turn so recovery does not repeat a ten-turn block. The original
autosave preference bytes are restored with the other settings.

Religion records supplied faith/prophets and a missionary staging position,
then tests real founding/enhancement/purchase/spread actions. Trade records its
range-building, prerequisite/reveal and gold setup, then uses real unit-purchase
and route callbacks. Setup is not earned gameplay evidence. `fixture-setup`
records distinguish these inputs from the asserted outcomes.

The Congress fixture can start a new ordinary Industrial/Duel game with two
majors and four city-states. It waits through the unchanged session countdown;
its proposal result is cross-checked against the native `league-enact.*` log
and active resolution state. It also produces a real world wonder and measures
Wealth against actual settled gold history. Other scenario files may be in active
development: consult the system-validation report for their current evidence.

### Window size and manual saves

`--window-size 1280x800` changes only the temporary window dimensions in
`GraphicsSettingsDX9.ini`, preserves its original bytes in the run directory,
and restores them in cleanup. An initial game-window screenshot is retained for
UI-interaction runs. Inspect its actual dimensions rather than assuming the
requested dimensions equal the Retina backing buffer size.

Every run also backs up root single-player manual saves under
`manual-saves-before`, reports whether all originals remain byte-identical, and
lists newly created saves separately. Never use overwrite confirmation to replace
an earlier manual save for a test. In recovery after a supervisor failure, include
the graphics INI backup when that run requested a window size.

### End-game and EUI fixtures

`--scenario endgame --scenario-turns 2` starts a new ordinary game with a two-turn
setup limit. It observes the actual score-victory/game-over event, captures the
end-game panel and uses normal exit confirmation. Do not pass a save or
`--save-and-exit`; it does not assign scores, winners or turn/wait flags. Use a
small Duel setup for this fixture. This does not cover every victory condition.

`temporary-eui-test.py` runs a bounded test with a private EUI 1.28g dependency.
It requires an EUI-configured LEKMOD package, the exact currently installed
standard package for restoration, and the central installer. It refuses to
replace an existing UI_bc1 folder or a mismatched standard installation. EUI
text files and its existing options database/journals are restored byte for byte;
new test files are removed. Restoration evidence is under
`build/macos/eui-tests/<UTC>/state.json`. The EUI code/assets are not committed or
redistributed. Obtain the author's archive and verify the hash in the system
validation report.

```sh
python3 LEKMOD_DLL/macos/temporary-eui-test.py \
  --installer /absolute/path/to/Civ5ModDlcPacker/civ5_dlc_installer.py \
  --eui-root /absolute/path/to/extracted/eui-1.28g \
  --package /absolute/path/to/private-eui-configured-package.zip \
  --restore-package /absolute/path/to/current-standard-package.zip \
  -- --mode human-turns --turns 3 --timeout 300 --load-save /absolute/path/to/fixture.Civ5Save
```

The production, city and system-popup adapters target standard UI. EUI permits
bounded human-turn/observer modes plus read-only `--scenario inventory` using
the shared save/exit callbacks. Use its saved report with `--expected-state` for
exact EUI reload comparison. The observer runs in its own Lua context and does
not replace either city screen's update/show handlers. Actual mouse input remains
a separate test. Do not silently apply
standard production/city callbacks to EUI's different contexts. A configurator
unit test alone is not an EUI runtime pass.

Human-turn reports distinguish `new_order_verified` from
`inherited_order_observed`. A loaded Wealth queue can permit ordinary turns
without any new production command; observing its queue/active-production
agreement is not a production-click or new-order pass. The engine's completed
turn records remain mandatory.

### Expanded single-player scenarios

The current-Mac completion ledger is `docs/macos-expanded-coverage.md`.
`--civilization CIVILIZATION_TYPE` selects player zero through normal setup for
new fixtures; loaded saves retain their own civilization. The `bolivia` and
`mughals` scenarios permit new Duel games with explicit `--scenario-turns 4`.
Bolivia uses supplied units and normal great-person actions; Mughals uses
scripted religion/conversion inputs and observes actual engine events. Neither
is mouse interaction or a claim that the supplied inputs were earned.

`science-prelaunch` loads the documented small Congress fixture, supplies the
prerequisites and near-complete production, and completes Apollo and all parts
through normal orders/turns. Use `--scenario-turns 15 --save-and-exit`, then
reload with `--expected-state` to compare the saved state. `science-launch`
loads the prelaunch save with `--scenario-turns 3 --capture-panels`, without
`--save-and-exit`, and checks the final normal assembly action and victory.

`domination` loads the same Duel fixture with `--scenario-turns 6
--capture-panels` and no save/expected-state options. It supplies an attacker,
uranium and a staging position, then uses ordinary war/combat commands. It never
sets damage, ownership or a winner. Victory adapters preserve the original
presentation and use normal exit confirmation.

The human driver waits for technology-award popups to finish through their
real Continue/show-hide callbacks before counting notification-result waits.
It resolves Congress prompts by submitting eligible proposals or abstaining
through the normal network commands. The foreground/background helper also
retains a call stack for nonzero `exit` calls without changing the exit status;
this helps investigate startup failures that create no OS crash report.

`culture-prelaunch` creates a Great Work through its normal action, closes the
real animated popup, observes one ordinary tourism turn and performs concert
actions until the next concert would cross the cultural threshold. It supplies
the great people and staging positions explicitly. Save/reload that snapshot,
then use `culture-launch --scenario-turns 3 --capture-panels` for the final
concert and actual victory.

Diplomatic fixtures use `diplo-victory-prelaunch`, `diplo-victory-resume` and
`diplo-victory-launch`. The initial fixture supplies technology/gold, verifies
actual gift spending/influence and isolationist gift rejection, and follows the
unchanged UN countdown. `resume` requires an existing UN save and supplies no
additional technology/gold. Failed World Leader ballots can earn the normal
extra delegates. Save before the winning ballot, compare with `--expected-state`,
then cast the final normal vote. Prefer an explicit `--timeout 900` or `1200`
for the longer session preparation and retain the thirty-turn limit. These
scenarios never assign votes, alliances or a winner.

`endgame --expect-human-victory` adds an assertion that the ordinary two-turn
score result selects the human. It does not set scores or choose a winner.

For startup exit 255 with merged-localization errors, consult
`docs/macos-startup-cache.md`. The cache-recovery tool defaults to read-only
inspection and preserves/removes only a confirmed empty generated cache with
explicit `--repair-empty`; it does not silently retry a test.

`unit-actions` uses the small loaded Congress fixture with
`--scenario-turns 15 --save-and-exit`. It supplies a Warrior/XP/iron/damage and
staging positions, then tests normal promotion, upgrade, healing and coastal
movement plus terrain/territory rejection. `worker` permits a new ordinary
Ancient/Duel game with the same turn bound. It supplies a worker, Wheel
prerequisites and a pillaged-farm input, then observes farm, road and repair
completion and yield changes. Reload either saved report with `--expected-state`
to compare its snapshot. These are action/outcome tests, not physical input or
proof that the supplied inputs were earned.


`buganda-lake` starts an Industrial/Duel Buganda game with `--scenario-turns 15
--save-and-exit`. It supplies a worker and, if needed, a legal secondary city
beside naturally dry terrain. Normal construction must make the lake and its
neighbors fresh water; permanent-improvement restrictions are queried without
forcing pillage flags. `combat` loads the small Congress fixture without end-turn
allowance, supplies full-health units/resources, then submits actual attack/capture
missions. Both support exact `--expected-state` reload comparisons. These checks
use scripted callbacks/missions, not actual mouse input.


`unit-utility` loads the same small Congress fixture and exercises actual disband
No/Yes confirmation closures, gifts and Merchant/Scientist/Engineer actions.
`air-operations` exercises real air strikes, ground-AA sweeps, three carrier
rebases, capacity rejection and ship movement with cargo. Use no end-turn
allowance, `--save-and-exit`, then exact `--expected-state` reload. Air strikes
must use `MISSION_MOVE_TO`, matching WorldView; `MISSION_RANGE_ATTACK` invokes a
different combat path. Ground-AA sweeps deliberately give the attacker no XP and
use Lekmod's zero damage multiplier. See the ledger's failed-test corrections.


`pillage-road` loads the recorded Ancient worker save with `--scenario-turns 15`.
It rejects own-tile pillage, supplies an abandoned farm/road, tests actual pillage,
then normal neutral-territory repairs and road travel. `georgia` starts an
Industrial/Duel Georgia game with the same turn bound, tests real Artist-driven
and newly created Khevsur bonuses, then lets the golden age expire normally.
Both support saved-state comparison. Supplied terrain improvements, resources,
units and staging are labeled separately from observed action outcomes.


`georgia-upgrade` starts a Medieval/Duel Georgia fixture with
`--scenario-turns 6 --save-and-exit`. It supplies prerequisites, units and any
required gold/iron, then uses a normal Artist action and a paid Warrior→Khevsur
upgrade. A separate Khevsur is gifted to another civilization through the normal
command to verify new-owner cleanup. Its snapshot retains both owners' units;
reload with `--expected-state` to compare bonus and non-bonus state.

The synchronized `UnitConverted` event arguments are old owner, new owner, old
unit ID, new unit ID and upgrade boolean. It is emitted at the end of
`CvUnit::convert`, after copied promotions/state and before delayed removal of
the old unit. It does not replace or reorder the existing `UnitUpgraded` event.


`greatworks` loads the small Congress fixture, supplies a second city, Museums
and Artists, then tests normal work creation, compatible slot swaps, cross-city
moves, exact tourism/theming changes and saved-state comparison. `cuba-greatworks`
starts Industrial/Duel Cuba with `--scenario-turns 3`: it supplies two cities,
uncapped population inputs, holding buildings and Musicians, then tests Dance
Hall culture/happiness removal, restoration, occupied swaps and tooltip values.
Its collected semantic mismatches always fail the scenario; diagnostic collection
does not turn them into passes. Both use actual commands/Close callbacks, not
mouse input. Use `--save-and-exit`, then exact `--expected-state` reload.


`archaeology` loads the recorded two-Museum great-work fixture with
`--scenario-turns 20 --timeout 900 --capture-panels --save-and-exit`. It supplies
technology and archaeologists at natural sites away from nearby enemies. Real
build completion events, normal notification activation and the actual archaeology
No/Yes callbacks are required. A queued build must be acknowledged before the
human turn driver runs, or an immediate Skip can cancel it. Landmark assertions
follow the mod's science/gold and age-based culture rules. The older-site yield
preview is a read-only API check, not an earned or worked Landmark outcome.


`cuba-ideology` starts Modern/Duel Cuba with `--scenario-turns 6`. It waits for
the normal ideology notification and exercises actual ideology and tenet No/Yes
callbacks, first-tenet unit rewards, non-repeat, costs and rejection conditions.
Use `--save-and-exit`, followed by exact `--expected-state` reload. The content
revolution-button rejection does not establish switching under ideological
pressure. All multiplayer branches remain outside this test scope.
