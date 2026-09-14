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

`--foreground-attachment-test` is an explicit exception, restricted to
`ui-interaction` and `--timeout` at most 180 seconds. It is **not standing user
authorization**. The original one-off test is finished; the user explicitly
renewed foreground testing for the resumed task. Retain this existing limit,
and do not infer standing permission for an unrelated task. The timeout includes
startup, so reserve time to exit; the prior 180-second test hit the cap during
shutdown and was terminated by the runner.

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

Scenarios require `--load-save` and an explicit budget of at most 600 seconds.
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
