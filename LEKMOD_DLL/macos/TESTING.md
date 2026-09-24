# Native macOS test tools

Read [the current handoff](../../docs/macos-testing-handoff.md) before resuming
this user's tests. [Validation status](../../docs/macos-validation.md) records
what actually passed and what remains untested. These tools are not a full-port
certification suite or part of the installed mod UI.

## Multi-scenario batches

Use [the batch operator guide](../../docs/macos-batch-testing.md) for longer runs.
`batch-playtest.py --preflight-only` validates the comprehensive plan's 16 stages,
81 functional assertions, 16 reload checks and 28-turn aggregate cap. The default
run budget is 60 minutes. Each stage uses an independent hashed fixture and its
own checkpoint; fixture loads stay in one native process. Commissioning limits
and retained pilot failures are recorded in the guide. Do not infer that the full
batch has passed merely from successful preflight or isolated scenario evidence.

## Additional combat and espionage cases

`batch-plans/critical-gaps.json` combines five independent cases: preserved
Defender old-save recovery/actual ZOC movement, Manhattan/missile production,
native fallout cleanup/repair, city nuclear effects and counterspy interception.
It declares 20 checks, five reload comparisons and a 27-turn aggregate cap.
The cases have passing native evidence across separate runs; the original
three-stage commissioning report retains its later cleanup failure. The combined
five-stage plan has been preflighted, not claimed as an untouched full-plan pass.
Use the focused plan files or `--from-stage` when retesting only a changed case.

See the [New Zealand](../../docs/macos-newzealand-validation.md),
[nuclear](../../docs/macos-nuclear-validation.md) and
[counterspy](../../docs/macos-counterspy-validation.md) reports for supplied inputs,
actual outcomes, failure history, hashes and limits. The independent product-code
boundary check is `python3 LEKMOD_DLL/macos/test-counterspy-outcomes.py`.

## Broad unique-unit lifecycle catalogue

`batch-plans/unique-units.json` creates every one of the 125 unique unit types
referenced by the 114 playable civilizations, observes native creation events,
and reloads the exact saved state. `batch-plans/unique-unit-disband.json` pins
that resulting save and uses normal Delete/Yes commands, pre-kill events and
owned/neutral treasury rules for all 125 units, followed by exact reload. Both
use zero ordinary turns. Their per-unit completed assertions keep the existing
stall guard informed; repeated messages do not count as progress. See
[the catalogue report](../../docs/macos-unit-catalogue.md) for proven scope,
artifact hashes, the corrected missing flag and retained commissioning failures.

## All-civilization initialization

See [the startup matrix](../../docs/macos-civilization-start-matrix.md)
for the ten groups covering 114 normal civilization choices and the replay-only
batch mode. All 114 choices passed native initialization/founding and exact
replays across ten games (10 human / 104 AI roles); individual unique mechanics
remain separate. Replay-only stages pin a passing source report
and matching save hash and compare its original snapshot without running setup.

## Unique-building production catalogue

`batch-plans/unique-building-catalogue.json` combines all ten saved civilization
groups in one process (23-turn cap). All 87 regular-production unique buildings
have passing completion/duplicate-rejection/reload evidence across commissioning
and recovery runs; one uninterrupted full-plan pass is not claimed. Research,
prerequisites, resources, legal extra cities and near-complete production are
labeled inputs. The actual engine produces every target. Existing queues are
continued; AI orders run only on the active owner's actual turn. Purchase-only,
holy-city and occupied-city definitions are separate cases. See
[exact evidence and retained fixture failures](../../docs/macos-unique-building-validation.md).

## Special-building acquisition and College reward regression

`batch-plans/unique-building-fixed-regression.json` runs seven stages in one
process: exact baseline replay, Israel gold/faith purchases, Vatican St Peter's,
Jerusalem Outremer after real capture, and College great-person rewards in normal
and post-capture city collections. All 33 checks/seven replays passed on clean
`f33cfd33`; the earlier failures are retained. See
[the exact artifact, inputs and results](../../docs/macos-special-building-validation.md).
The cap is 11 ordinary turns; the passing run used five. Offline reward-block
regression: `python3 LEKMOD_DLL/macos/test-great-person-building-rewards.py`
(128 dense/empty/sparse city, speed and research/overflow cases under sanitizers).

## Religious civilization ability batches

[The Vatican/Israel/Jerusalem report](../../docs/macos-vatican-validation.md)
records pressure/delegate/settlement, capture/conversion Courthouse paths,
14 paired Great Person builds, capped military kill faith/civilian controls,
actual Worker Pastures, raw/working luxury faith and unique-unit acquisition
and kill yields. Seven functional stage/reload pairs plus one baseline replay
have passing evidence (45 assertions across recorded runs). The original failed
commissioning batches retain their verdicts; aggregate one-process success is
not inferred. `religious-terrain-and-units.json` itself passed all 15 checks and
three replays in one 197.1-second native process. Earlier plans retain the exact
fixture hashes for focused reproduction. Only scripted actions/native outcomes
are covered here; there is no new physical mouse coverage.

## Bounded startup/shutdown cycles

`lifecycle-playtest.py` installs a verified package once, then performs 1–5
cold-launch/read-only inventory/save/normal-exit cycles against one hashed fixture.
The first passing inventory becomes the state oracle for later cycles. It retains
the installed product and generated cache between launches, stops at the first
failure, and restores stock through the central installer. It requires stock
initially and checks for an unlocked desktop and existing Steam session before
each launch. It does not advance a campaign or retry a failed cycle.

Before installation and before/after each cycle, it hashes cache files and copies
the `Localization-Merged.db` family into its evidence directory. It never repairs
or removes cache files. The central installer normally invalidates generated
caches when switching products; distinguish that first launch from subsequent
launches with the same installation/cache. Existing diagnostic/activation guards
and dyld image tracing are identical in each cycle. These are instrumented checks,
not physical interaction or original-settings controls.

See [release qualification](../../docs/macos-release-qualification.md) for the
exact candidate command and evidence. Offline checks:

```sh
python3 LEKMOD_DLL/macos/test-playtest-batch.py
python3 LEKMOD_DLL/macos/test-lifecycle-playtest.py
```

Batch and lifecycle wrappers give their owned Python runner a separate session.
On SIGINT they forward one interrupt and allow up to 60 seconds for its settings/UI
restoration before attempting stock restoration. Repeated wrapper interrupts do
not repeatedly interrupt the child's cleanup. An unfinished cleanup is an error;
inspect the recorded PID and evidence before recovery. Offline subprocess tests
exercise both a direct wrapper interrupt and a terminal process-group interrupt;
no interrupted native-game cleanup is claimed from those tests.

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
python3 LEKMOD_DLL/macos/test-trade-countdown.py
python3 LEKMOD_DLL/macos/test-palmyra-events.py
python3 LEKMOD_DLL/macos/test-coup-probability.py
python3 LEKMOD_DLL/macos/test-spy-relocation.py
python3 LEKMOD_DLL/macos/test-inquisitor-owner.py
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


`diplomacy-assets` starts Ancient/Duel Rome with `--scenario-turns 6`. Technologies,
contact and a luxury surplus are inputs; resource/GPT gifts, mutual embassies and
open borders use actual single-player AI trade/reply callbacks. It checks both
sides' accounting, rejection boundaries, ordinary settlement and exact reload.
Explicit diplomacy adapters must take precedence over generic turn handlers, and
accepted replies must be observed in a visible context before normal Back/Goodbye.


`trade-internal` loads the small Congress fixture with `--scenario-turns 6`.
It supplies coastal-city/building/reveal/unit inputs, then uses actual new-home
No/Yes and route popup callbacks for rebasing, internal land food and sea
production. Use its saved report for exact reload. The city accounting checks
compare returned legal route quotes with trade-only yield contributions.


`ideology-inventory` reads saved ideology, influence and public-opinion inputs.
`ideology-pressure` loads the Cuba two-tenet save with `--scenario-turns 5`;
foreign Order/Radio, population 25 and positioned Musicians are explicit inputs.
Concerts run only during the owning AI's actual turn, stay below cultural victory,
and must produce public opinion on an ordinary turn. `ideology-switch` loads
that pressure save and uses the actual SocialPolicyPopup No/Yes callbacks,
checking branch removal, tenet/culture accounting and content-button rejection.
`anarchy-expiry` loads the immediate revolution save with `--scenario-turns 2`;
it never assigns anarchy or turn counters. All four support `--save-and-exit`
and exact `--expected-state` reload; reload does not repeat fixture mutations.


`--activation-only` is a startup diagnostic control: the background activation
guard remains, while process file/stream observers and the log-flush timer are
compiled out. Engine/Lua logs can then remain buffered until normal exit; do
not treat a supervisor stall with incomplete buffered records as a gameplay
verdict. Compare this mode separately and retain failures. It never changes
cache files, game rules, turn counters or synchronization checks.


`venice` starts Ancient/Duel with human and AI `CIVILIZATION_VENEZ` and
`--scenario-turns 3`. Recorded technology grants emit native events; independent
route awards and already-known-tech rejection are checked. A semantic failure
is retained as FAIL while diagnostic save/exit can finish; completion never
overrides that verdict. `venice-known-compass` is read-only: load an affected
save or start Industrial/Duel with the same civilizations. Both support exact
reload; missing-award repair must happen in product initialization.


`italy` starts Ancient/Duel with human and AI `CIVILIZATION_ITALY` and
`--scenario-turns 6`. Prerequisite policies/free choices and Artists are labeled
inputs. Final policies use normal legal adoption; AI actions require the real
owner turn. Golden-age starts use Artist missions. It checks both owners' point
awards and extensions, then supports exact saved-state reload. Alert gating
and unrelated/ineligible/fractional boundaries also have offline tests in
`test-italy-events.py`.


`great-person-builds` loads the saved religion-reconversion fixture without
advancing turns. Five supplied great people use normal Academy, Manufactory,
Customs House, Holy Site and Citadel build actions. The scenario checks actual
completion events, consumption, plot-yield previews, city/water/duplicate
rejection, neutral Citadel claims and the existing used-prophet boundary. The
Holy Site's fresh prophet is created in a religious capital before positioning.
Use `--save-and-exit` and exact `--expected-state` reload; startup failures before
loading are distinct from a saved-state mismatch.


Startup comparisons can set `--quick-start 0|1` and `--skip-intro 0|1`
independently. QuickStart defaults to 0 because the runner already uses normal
main-menu Start/Load callbacks. `--no-process-adapter` requires an explicitly
authorized `--foreground-ui-test`, supports bounded UI interaction or scripted
single-player checks, and cannot combine with `--activation-only`. It injects
no test library. Foreground execution does not imply physical mouse coverage.

For an ordinary menu control without UI hooks or prelaunch configuration edits:

```sh
python3 LEKMOD_DLL/macos/native-startup-control.py --foreground-authorized --timeout 600
```

Use only with current user foreground authorization. It checks the desktop lock
and existing Steam/game processes, preserves settings and manual saves, and
records the actual process exit. Use CUA for real UI actions; after the app exits,
do not select it again and inadvertently launch another instance. A zero exit
alone does not prove the menu was reached: retain a separate physical observation.


`test-lua-movement-cost.py` extracts the product `MovementCost` binding and runs
30 real-Lua argument cases with AddressSanitizer. Object arguments must use
`CvLuaUnit`/`CvLuaPlot` instance lookup; the generic enum/integer conversion does
not support Lua object tables. The optional remaining movement defaults to zero.
The crowded Atomic fixture in the expanded ledger supplies the native regression.


`--trace-loaded-libraries` records dyld image loading in the test process log
and the report. It can distinguish a startup failure before GameCore loads
from a loaded-core failure. It does not modify cache files, retry a failed
launch, or change any gameplay/synchronization state.


`setup` uses normal `--map-script`, `--game-speed`, `--handicap`, `--start-era`,
world/roster and repeated `--game-option TYPE=0|1` controls. Only the explicitly
listed single-player options are accepted; duplicates and unknown eras fail
before launch. Use `--scenario-turns 2`, then exact reload. The finite inputs
are in `setup-matrix.json`; evidence and limits are in `docs/macos-setup-matrix.md`.
For driver movement checks:

```sh
build/macos/test-deps/lua-5.1.4/src/lua LEKMOD_DLL/macos/test-stacked-movement.lua LEKMOD_DLL/macos/playtest-movement.lua
```

The driver preserves real movement budgets and arrival checks. Its nearby search
never assigns unit position/moves/activity, declares war, or clears a waiting flag.


`uae-raider` starts Industrial/Small Archipelago with human UAE and AI Rome,
`--scenario-turns 6`. Coastal cities/buildings/reveal and the relevant units are
labeled inputs. The AI creates a legal sea route on its real active turn; normal
war/plunder commands must remove it and award the configured XP/movement.
Use normal save/exit and exact reload.


`aksum-heal-domain` starts Aksum/Small Archipelago with religion enabled and
`--scenario-turns 3`, or loads a suitable religion-enabled coastal fixture. It
labels the provided Church, units, damage and native healing deltas. Only the
faith response to real UnitHealed dispatch is certified; this does not claim
ordinary-turn healing or construction. Land/sea/air/distance controls and exact
reload are required.


For physical quicksave checks, the shipped controls use F11 and Ctrl+F11.
Preserve an existing quicksave before any overwrite; use a distinct state
marker before saving and a different unsaved state before loading. The
read-only UI observer can compare the resulting city/unit state. Capture only
the game PID's full-size window, not a thin title-bar surface.

### Overview personality display regression

`test-greeting-personality.py --relationships LEKMOD/Lua/tmp/ui/DiploRelationships.lua.ignore`
executes the actual diplomacy personality block for all ten shipped types. Pass
a preserved native BNW `DiploRelationships.lua` to the same option for the
six-failure baseline. `test-configure-ui.py` checks both assembled UI modes.
The physical observer additionally records met city-state personality types and
the culture-overview option without assigning them. Native physical evidence
is in `docs/macos-ui-overviews.md`.

### Physical Great Work evidence verification

After the recorded mouse sequence, run:

```sh
python3 LEKMOD_DLL/macos/verify-greatwork-ui.py \
  --eui-run build/macos/playtests/20260918T062447Z \
  --standard-run build/macos/playtests/20260918T063242Z
```

The validator checks slot IDs, incompatible selection preservation, occupied
swaps, Museum themes/tourism, exact quickload and cross-UI load, save hash,
normal native exit and restoration. Mouse actions themselves are documented
separately in `docs/macos-ui-overviews.md` and screenshot event records.

### Budget science boundaries

`--scenario budget-science --load-save PATH --save-and-exit` reads native science
queries across supplied treasury balances, restores the original balance and
asserts all research state is untouched. Use a negative-income fixture.
`--scenario budget-settlement --scenario-turns 3 --save-and-exit` supports a new
Ancient Duel setup: the normal driver founds a city, labeled temporary maintenance
inputs create zero science, and two ordinary turns verify deficit and recovery
settlement. Its saved report supports exact `--expected-state` reload.
`test-eui-science-display.py` executes the actual EUI HUD and tooltip rate query;
`--source PATH` accepts the preserved pre-fix template for baseline comparison.
See `docs/macos-economy-boundaries.md` for evidence and coverage limits.

### Mexico first-turn discovery

Run `test-mexico-discovery.lua` with the pinned Lua 5.1 interpreter and a product
`Lekmod_mexico.lua` path. Native `--scenario mexico-discovery --scenario-turns 1`
requires normally selected human/AI Mexico on separate single-player teams and
nearby/distant minor starting plots. Tiny Pangaea with eight minors supplies the
recorded fixture. The test observes opening locations, real minor foundations
and distance controls without assigning visibility; use its saved report for
exact `--expected-state` reload. See `docs/macos-mexico-validation.md`.

### Exact initial hook sources

New runs preserve the full initially injected Lua bytes under `ui-injected/`,
using paths relative to the app bundle. The report's `initial_ui_hooks` entries
record each adapter, byte count and SHA-256 after run-specific placeholders are
rendered. `ui-original/` continues to hold restoration backups. This is initial
launch evidence; a later live driver refresh is a separate revision. The files
remain local, ignored artifacts, including any privately installed EUI context.

`--scenario mexico-pottery --scenario-turns 1` loads a human/AI Mexico fixture
with separate teams, existing capitals and Pottery unknown. It supplies only
the technology inputs, checks native Worker creation for each owner and rejects
a repeated award from already-known technology. The turn allowance installs
ordinary technology-popup handling; the successful action run advanced no turn.
Its saved report supports exact reload.

`--scenario mexico-ranchero --scenario-turns 1` loads a Mexican capital. It
supplies population 4, a Granary and near-growth food, uses normal focus and
Ranchero production orders, checks base-Settler rejection, and verifies one
ordinary growth turn while the Ranchero remains under construction. Its complete
snapshot supports exact reload.

`--scenario mexico-hacienda --scenario-turns 1` loads a Mexican capital without
a Hacienda. It supplies technology, selects four distinct compatible owned
resource plots (clearing forest/jungle as labeled input only if required), and
supplies production one hammer short of completion. Normal construction must
apply bonus-gold, luxury-production and both strategic-class food increases,
leave other plot yields unchanged and add no maintenance. The snapshot supports
exact reload of the resulting building/resource/yield state.

`--scenario mexico-influence --scenario-turns 1` loads the early Mexico fixture.
It supplies contact, one neutral-tile military unit, uranium and upkeep gold,
then verifies the native tribute-eligibility rate, one ordinary influence turn
and an actual tribute command/cutoff. The friendship getter exposes whole
points; the report distinguishes those observations from quoted hundredths.
The complete minor/treasury/unit snapshot supports exact reload.

`--scenario phoenicia-founding --scenario-turns 2` supports normally selected
human/AI Phoenicia and a non-Phoenician third major. It stages normal Settler
founding before/after supplied Optics, excludes nearby ruins from those sites,
checks no retroactive reward and observes the AI/other-owner outcomes after an
ordinary turn. Population/founding events are logged read-only. Its saved report
supports exact reload; see `docs/macos-phoenicia-validation.md`.

### Philippines founding history

`test-philippines-quota.lua PRODUCT_LUA` checks the actual handler against
capital, first-two, later, lost-city, owner and legacy-DLL boundaries. Native
`--scenario philippines-founding --scenario-turns 2` supports a normal human
Philippines/other-AI opening with three supplied Settlers at legal ruin-free sites.
`--scenario philippines-loss --scenario-turns 3` loads that baseline, provides
one AI attacker/uranium/upkeep budget, and requires an actual war/move-attack
capture before testing a later normal founding. Native lifetime-counter checks
distinguish owned, founded and captured city counts. Snapshots support exact
reload; see `docs/macos-philippines-validation.md`.

`native-startup-control.py --foreground-authorized --logging-enabled 0|1` is
an optional one-setting comparison: all other original settings/UI are retained
and no process library is injected. The report distinguishes intentional input
from changes made by the game, then restores the original bytes. Foreground
authorization must already exist in the conversation. Both native and functional
runners now recheck desktop lock state immediately before process launch, after
artifact preparation.

`--scenario philippines-movement --scenario-turns 1` supplies three civilian
classes on distinct owned/neutral land plus combat/other-owner controls. It
checks each actual base-plus-two limit, then normal turn refresh without any
movement setter. The full unit snapshot supports exact reload. This does not
cover embarked or foreign-open-border movement.

`--scenario philippines-church --scenario-turns 2` uses the currently referenced
Help/data (no building prerequisite, Compass, +1 culture/+2 faith/+15 training XP).
It supplies research and near-complete production, then requires normal Church
construction and a normally trained combat unit with the quoted XP. The resulting
building/yield/unit snapshot supports exact reload.

`--scenario philippines-gerilya --scenario-turns 1` supplies a Gerilya and
Expeditionary Force control, then requires normal embarkation and an ordinary
refresh of the three-extra-move difference. `philippines-gerilya-return` loads
that saved state and uses normal disembark moves to verify equal land limits
while retaining unique strength/promotion. Both snapshots support exact reload.
Neither scenario sets an embark flag or movement counter.

`--scenario oman-minaa --scenario-turns 2` supports a normal Oman/other-AI
Industrial Archipelago setup. It supplies a distant coastal city/building and
units/health/embark inputs at the observed empty barbarian-turn boundary after
the opposing AI finishes. The next real Oman turn must apply exact damage with
lethal-stack and own/land/distance controls. `test-oman-minaa.lua PRODUCT_LUA`
adds isolated filter cases, labeled separately from native outcomes. The
persistent surviving-unit/building/war snapshot supports exact reload.

### Explicit AI control civilizations

`--slot-civilization 2=CIVILIZATION_ROME` selects a normal civilization for an
additional enabled AI slot. Repeat for distinct slots 1–11; slot 0 remains the
human `--civilization`. Disabled slots, duplicate slots and overlap with
`--opponent-civilization` are rejected before launch. Slot status remains AI and
this does not enable multiplayer. The normal `GAMEOPTION_NO_GOODY_HUTS` setting
is also allowed for controlled single-player reward tests. Thirty-two runner
regressions pass; the Ottoman three-owner case validates normal slot 2 selection.

`--scenario ottoman-promotions --scenario-turns 4` supports human/AI Ottomans
and Roman slot 2, with the normal no-ruins option. Supplied XP must become ready
through ordinary unit turns; human promotion actions and normal AI promotions
must produce the event-time faith reward, while Rome gains none. All owner unit
levels/XP/promotions and faith values support exact reload.

`test-moors-era.lua LEKMOD/Lua/Civilizations/Lekmod_moors.lua` executes fourteen
offline handler cases for Medieval/Renaissance counts, later-era clearing,
human/AI team routing, unrelated/dead-owner exclusions, per-owner-turn updates
and immediate founding-event registration/routing. Native production modifiers
and first-playable founding behavior are verified separately. All 26 civilization Lua files also pass the pinned Lua 5.1 syntax check.


`test-unit-owner-boundaries.lua LEKMOD/Lua/Civilizations` runs 57 isolated
actual-handler cases using Lua 5.1 and the C++ event argument order: Swiss
creation/movement promotions; Polynesian creation cleanup; New Zealand meeting
rewards, Battalion influence and Defender city-radius/friendship filtering.
Minor/barbarian index guards reject major-only friendship queries in the mocks.
Each case loads the product into a fresh environment. These tests establish
callback behavior only; native terrain/pathing, event timing, conversion/upgrade
and persistence remain separate tests.


`test-city-policy-boundaries.lua LEKMOD/Lua/Civilizations` runs 29 isolated
actual-handler cases for Romanian capture rewards, Vatican courthouses and
Yugoslav tenets. Capture events pass the recipient in argument five; conversion
events pass owner/religion/x/y; ideology events pass owner/branch. The Romanian
integer mock follows the positive-number truncation of the Lua binding and
checks the four normal speed inputs (Quick 80%, Standard 100%, Epic 125%,
Marathon 200%). Native capture/liberation/gift distinctions, disposition timing,
revolution timing and persistence remain open. No product code was changed.


`test-tonga-exploration.lua LEKMOD/Lua [OLD_TONGA_LUA]` executes the real
starting-exploration callback and shipped plot iterators on a controlled axial
hex grid. Thirteen island/coast/owner cases catch the excluded-center one-tile
island defect. Grid conversion, area identity and visibility are stand-ins;
native generated-map and persistence checks remain required. The optional old
source argument reproduces the five pre-fix failures. See the Tonga report.


`test-kilwa-routes.lua LEKMOD/Lua` loads the actual utility and Kilwa script
for seventeen route-filter and owner/city refresh cases. It checks major/minor
international destinations, internal routes, domain zero, incoming/other-origin
exclusion, absent targets, stale-count removal and the real UnitPrekill argument
order. Route lists and city identities are supplied stand-ins. Native route
creation/expiry/plunder timing, food settlement and persistence remain pending.


`--scenario ottoman-diversity --load-save PATH --save-and-exit` loads the
three-owner Ottoman promotion fixture. Population, pantheon, three world
religions with non-happiness beliefs and pressure transfers are supplied inputs.
Native follower counts and local/empire happiness must follow one/two/three
religions, reject pantheon/other-owner awards and remove expired bonuses. A
minority-only addition must not emit a majority-conversion event. Its final
snapshot supports exact reload. No turn or happiness value is assigned.

`test-religion-diversity-cache.py [--source OLD_CPP]` compiles the actual product
`RecomputeFollowers` method under AddressSanitizer and UndefinedBehaviorSanitizer.
Nine cases exercise minority addition/removal, no-majority diversity, unchanged
and pantheon controls, and the existing majority-conversion paths. Cache/event
sinks are stand-ins; the native Ottoman fixture supplies the engine evidence.


`--scenario tonga-vision --save-and-exit` starts normal human/AI Tonga plus
Roman slot 2 on Small Archipelago. It only observes native generated terrain,
area identity and team visibility; no visibility or terrain input is supplied.
A suitable fixture must contain a singleton island at distance 7–12 and Roman
distant-island controls. Missing preconditions fail explicitly. A failing
visibility verdict can still be saved for exact-map retesting; it remains FAIL.
The full per-owner revealed-plot snapshot supports exact reload.


`--scenario diversity-yields --load-save PATH --save-and-exit` loads the
corrected Ottoman diversity fixture, supplies a Candi then a Gurdwara and uses
pressure transfers with unchanged majority/followers. Native faith and science
religion caches must update, minority removal must clear the Candi bonus, and
the other-owner control must stay unchanged. The two-religion Gurdwara snapshot
supports exact reload. This is not construction, purchase or turn settlement.


`--scenario maori-movement --scenario-turns 6` uses normal human/AI Māori and
Roman control on an Ancient start. It supplies units/upkeep and observes early
limits, recon/air exclusions, ordinary turn-five expiry and late creation/next
turn expiry. A read-only `maori-refresh --scenario-turns 1` replay of the retained
post-turn-five fixture takes two stable observations and can save a failing
budget for diagnosis. `maori-stack --scenario-turns 1` loads a turn-six fixture,
supplies Worker/Akkad and General/Hakkapeliitta stacks and checks that expiry
preserves their legitimate escort allowances. All support exact snapshot reload.
Test adapters never set unit movement or promotions to obtain a pass.

`test-maori-expiry.lua PRODUCT_LUA` runs twenty-four isolated actual-handler cases
for expiry, spent movement, donor iteration order, owner filters and legacy-DLL
compatibility. `test-lua-stack-moves.py` runs 22 actual-binding Lua/sanitizer
cases with the land-stack feature both enabled and disabled. The new query is
read-only; the product expiry callback only reduces excess movement after
removing the expired promotions. These tests do not bypass synchronization.


`maori-trained --scenario-turns 2` loads a post-opening Māori fixture, selects
a legal city training order and supplies production one hammer short. Actual
CityTrained and first-playable/next-turn states verify birth-turn protection.
`maori-era --scenario-turns 5` uses a normally selected later-era start (the
recorded case is Classical), supplies two land probes and checks all elapsed
turns 0–4 plus normal expiry at elapsed five. Neither scenario assigns unit
promotions, movement or turn counters. Both support exact snapshot reload.


`test-cuba-capital-culture.lua PRODUCT_LUA` runs sixteen isolated actual-handler
cases for culture thresholds, per-capital rounding, met/unmet/self exclusions,
team/player ID routing, missing capitals, independent AI-owner updates, clearing
stale counts and non-stacking. Capital culture is a supplied quote: this does
not establish native yield settlement, capital transfer or feedback between
multiple Cuban capitals. Existing native ideology/Dance Hall evidence is separate.


`maori-gift --scenario-turns 2` loads the turn-six Māori fixture, supplies three
units/peaceful staging positions and uses actual gift commands to Māori/Roman
AI recipients. Real recipient turns must expire inherited bonuses. It follows
unit-conversion IDs and saves the full three-owner state for exact reload.
`maori-gift-repair --scenario-turns 1` loads the retained affected save and
requires the next normal Roman turn to clear the stale promotions. No test
adapter sets movement, promotions or ownership to obtain those outcomes.


`cuba-capital --scenario-turns 5` supports a normal human Cuba/Roman AI/Cuban
AI opening. It supplies Monument/Amphitheater inputs and contact, captures source
quotes on real owner turns, and verifies unmet exclusion, met-capital increases,
source-reduction decreases and the Roman no-marker control. It requires an
initially unmet Roman source. Snapshot reload includes rates, marker counts,
contacts, buildings and turn. This does not claim normal building construction
or culture-bank settlement.


`moors-founding` starts a normal Medieval human/AI Moors plus Roman-control
fixture and uses the starting Settler's actual Found action. The first playable
city state must have two markers, +30% Market/Library modifiers and no Great
Library bonus. `moors-eras --scenario-turns 2` loads that save, observes normal
AI foundations, supplies Acoustics/Scientific Theory research and one Settler,
and checks native era events, team isolation, immediate Renaissance founding
and Industrial expiry. Both snapshots support exact reload.


`admiral-repair --load-save PATH --scenario-turns 1 --save-and-exit` uses a
coastal fixture. Units/health/positions and one embarked-state input are labeled.
The normal Repair Fleet action must heal owned sea/embarked targets, preserve
foreign/land/radius-two/healthy controls and consume the Admiral. The turn
allowance enables ordinary popup handlers; the passing run advanced no turn.
The live-unit snapshot supports exact reload.


`nuclear --load-save PATH --scenario-turns 1 --save-and-exit` supplies a missile,
uranium, full-health barbarian targets, target visibility and a compatible Farm
in an isolated unowned region. It checks range/self/non-nuclear restrictions,
level-two radius outcomes, shipped GDR immunity, fallout/pillage and consumption.
The own-city-overlap query is allowed by this engine and is never executed.
The scenario waits for the missile's actual EndCombatSim event before returning
for save; visible damage alone is not sufficient. The passing run advances no
turn, and the outcome snapshot supports exact reload. City/population effects,
weapon production and natural cleanup are separate coverage.


`test-trade-tooltip-precision.py [--source OLD_CPP]` compiles the actual outgoing
and incoming tooltip bindings with sanitizer-backed numeric/localization sinks.
It checks 183 yield-precision and route-filter cases across origin, destination
and incoming paths. The sinks do not test locale rendering. Native
`trade-tooltip --load-save PATH --save-and-exit` uses the two-route internal
fixture to require real localized 1.75 food/3.5 production strings and unchanged
175/350-hundredths route data. Its snapshot supports exact reload.


`test-trade-incoming-owner.py` executes actual incoming route identity field
assignments under ASan/UBSan. Native scenario `trade-incoming` uses preserved
internal-route fixture `20260916T080553Z`, two explicitly supplied AI caravans
and a legal supplied city, then at most two ordinary turns to create incoming
routes on the AI's active turn. On its saved two-route fixture it performs only
read-only checks; `--expected-state` compares the exact recorded snapshot. The
legacy creation check name then means route presence, not new creation. See
[the incoming report](../../docs/macos-incoming-trade-validation.md) for commands,
evidence limits, affected-save compatibility and physical standard/EUI coverage.

`test-trade-incoming-tourism.py` executes the actual incoming tourism expressions
with distinct owner/recipient targets. `trade-incoming` additionally compares both
query directions; use the preserved `20260916T050343Z` Great Works fixture for
nonzero tourism. Zero-only comparisons are labeled in the recorded event and do
not establish nonzero routing. The incoming report includes the failed baseline,
correction, affected-save retest and exact reload.


`test-great-work-swap-ui.py` runs actual CultureOverview swap callbacks against
stock, zero-based and permuted class IDs. `greatwork-exchange-prep` uses the
preserved two-artwork save `20260916T050343Z`, supplied AI great people/buildings
and at most two ordinary turns to prepare real foreign works and scripted
offers. `greatwork-exchange-verify` reads the specific physical Self portrait /
Dutch men-o'-war exchange result with no setup mutations or turns. Both use a
temporary shared snapshot module, removed by normal runner cleanup. See
[the exchange report](../../docs/macos-great-work-exchange.md) for hashes and
evidence limits. Preserve the current quicksave before physical F11 and restore
it only after copying the test result and verifying the owned game has exited.


`kilwa-routes` uses the preserved Industrial opening documented in the
[Kilwa report](../../docs/macos-kilwa-validation.md). It founds the capital with
the normal Settler action, explicitly supplies fixture cities/buildings/caravans
and issues the trade popup's ordinary synchronized mission message. Direct human
`Unit:PushMission` is invalid outside a game-network message and produced a
retained protocol failure; do not use it to manufacture a pass. The accepted
scenario checks route markers/rates, internal exclusion/four-gold accounting and
one ordinary food-storage settlement. Use a two-turn bound for setup and zero
turns with `--expected-state` for exact reload.

`kilwa-expiry` observes the three preserved contracts through their quoted ends
with a 19-turn maximum. Its fixture requires the explicitly supplied single-player
Always Peace/no-barbarian options, because the first uncontrolled expiry attempt
was interrupted by a normal Roman declaration of war. It never changes duration
or forces a returned unit; it verifies marker removal, caravan return and cargo
removal, then supports exact zero-turn reload. This functional bound does not
reopen the accepted long turn campaign.

`kilwa-war` sends a normal synchronized war command from the unrestricted
three-route Kilwa save and takes three stable observations without requesting
a turn. `kilwa-war-continue` loads its preserved pre-fix wartime save and permits
at most one ordinary owner turn, distinguishing saved-marker recovery from
immediate cancellation. Both support exact zero-turn reload. The native
DeclareWar callback receives team IDs; its multi-owner routing/exclusions are
covered by the 23-case actual Lua handler suite.


`test-trade-removal-event.py` executes actual EmptyTradeRoute code with sanitizer
checks for post-clear event ordering and owner arguments. The new normal hook is
`TradeRouteRemoved(originPlayerID, destinationPlayerID)`; UnitPlundered remains a
pre-removal event and must not be treated as completion. `kilwa-sea-plunder`
prepares an explicitly supplied AI sea-route fixture and uses real AI owner-turn
mission processing plus synchronized human war/plunder actions. The human side
never invokes Unit:PushMission directly. `kilwa-sea-continue` loads the preserved
pre-fix sea-plunder save for at most one ordinary AI turn. See the
[removal report](../../docs/macos-trade-removal-validation.md) for exact scope and
artifact hashes.


`polynesia-upgrade` uses supplied coastal homes, Compass/gold and Galleys, then
normal human/AI paid upgrades and synchronized ocean movement. AI probes pending
deletion are not revived: fresh controlled inputs are supplied on the real owner
turn and still must pass all upgrade gates. `polynesia-gifts` checks real
human/AI gift commands and received-ship movement. `polynesia-load` reads the
preserved failed upgrade save and attempts only normal ocean movement, with no
fixture mutation or turn. All support exact reload; see
[the Polynesian report](../../docs/macos-polynesia-validation.md). The owner-boundary
suite contains 13 Polynesia cases within 47 total Swiss/Polynesia/New Zealand cases.


`test-nabatea-exploration.lua` executes the actual Zabonah reward handler with
13 owner/reveal/lifecycle cases. `nabatea-disband` uses the ordinary delete action
and Yes confirmation to verify off-map removal without Lua errors; a disposal
assertion alone is insufficient if the runner records a runtime error.
`nabatea-discovery` uses real synchronized Scout/Zabonah moves, supplied city and
position inputs, and exact gold/reveal checks. Both support zero-turn exact
reload. See [the Nabataean report](../../docs/macos-nabatea-validation.md).
Do not reactivate MC_NabateaAddin for these tests: its old purchase UI is disabled
in the shipped InGame loader and is not the current farming trait.


`test-tech-trait-yield-cache.py [--source OLD_CPP]` tests the actual trait-refresh
statements and owned-plot refresh under sanitizers with controlled trait/plot/city
sinks. Native `nabatea-farms` supplies legal fresh/dry Farms and technologies,
then compares cached/calculated yields for Nabataean and Roman owners at
Mathematics/Civil Service. Three observations follow each transition, with no
yield setters. Its exact Farm/technology snapshot supports zero-turn reload.
See the Nabataean report for evidence and remaining natural-research boundaries.

`nabatea-research --scenario-turns 2` loads the retained Mathematics-only Farm
save, supplies near-complete research and uses ordinary research/plot-assignment
commands. A native technology event, exact worked-city yield increase and next
turn food-storage settlement are required. Setup never sets yield or city food.
The outcome snapshot supports exact zero-turn reload.

`nabatea-tomb --scenario-turns 2` loads the Farm research outcome. Supplied
Horseback Riding/near-complete production and a normal avoid-growth command
control a real Tomb construction. Native building yields/resources, six
type/domain contribution queries and an actual external land route are checked
separately. The route table has no FromFood field: use the native total-value
query and independently verify the origin city's actual gross food. The
complete two-owner city/resource/route snapshot supports exact zero-turn reload.

`zabonah-ai-minor --scenario-turns 3` starts two Roman majors/two city-states
on Small Ancient Pangaea with Always Peace/no barbarians/no huts. On the real
AI owner turn, supplied Scout and Zabonah units use normal AI PushMission
movement. The driver verifies no Scout reward, exactly ten gold for a previously
unrevealed minor capital beyond ordinary sight, and no repeat reward. It never
uses direct missions on a human unit or alters synchronization state. Its
AI treasury/unit/city-state visibility snapshot supports exact reload.

`test-player-color-holes.py [--source OLD_CPP]` executes the actual initial
player-color allocator using shipped XML defaults and sparse color IDs under
ASan/UBSan. Native `newzealand-meeting` also verifies twelve duplicate-civilization
players have distinct valid color rows and components, with exact color persistence
on reload. See `docs/macos-player-color-validation.md` for both preserved native
SIGSEGV baselines, the correction and unchanged-database evidence.

`newzealand-meeting` uses two New Zealand players and ten Roman controls on
Standard Ancient Pangaea. One supplied Scout/Warrior boundary produces a real
movement-triggered TeamMeet; further explicitly supplied native engine contacts
sample the unchanged RNG rewards. Both-owner, unrelated-Roman and repeat-contact
checks require exact balances and native event counts. Twelve valid distinct
colors and the complete contact/balance snapshot support exact reload.

`newzealand-research` reuses the meeting checks after a normal initial Found,
supplied Astronomy prerequisites and ordinary research selection. Naturally
drawn science rewards must add12 progress without changing human overflow;
the AI no-selected-research control uses overflow. No research progress is
assigned in this variant. The shared temporary helper is guarded and restored,
and the extended progress/overflow snapshot supports exact reload.

`newzealand-science-completion` loads the retained twelve-major initial save,
uses normal Found/research selection and supplies progress six points short
of Astronomy. Native first contacts must naturally draw science, complete the
tech through TeamTechResearched and carry exactly six excess points to overflow.
Known-contact and unrelated-owner controls plus exact reload are required;
no RNG/tech-completion flag is assigned.

`newzealand-battalion` uses the two-Rome/two-city-state saved fixture. Supplied
units and standing are measured immediately before/after the actual PlayerDoTurn
handler via a temporary read-only observers placed before and after real registrations.
Human two-unit and AI one-unit influence, normal-unit/unfriendly/unowned controls
and foreign owners are distinct checks; no product handler is called manually.
The runner restores the original civilization script. Exact unit/influence
state supports zero-turn reload.

`test-optional-options-control.py [--source OLD_LUA]` executes the actual
AI-deals checkbox binding/update/callback fragments with present/absent box and
checkbox controls. The missing-control path must preserve the game option and
suppress its change notification; present controls retain normal behavior.
The shared frontend script can initialize during single-player reloads. These
checks do not establish multiplayer lobby or gameplay support.

The New Zealand observer adapter has an explicit prefix and suffix. The prefix
emits a test-only before-owner-turn signal ahead of the product registrations;
the suffix emits the after signal. This preserves ordering when a batch stage
subscribes after world initialization. The runner restores the original product
file bytes. Gameplay handlers are still dispatched only by the native engine.
