# Lekmod macOS native port

Current acceptance and remaining work are tracked in
[`docs/macos-validation.md`](../../docs/macos-validation.md). The user has ended
the long turn campaign; do not restart a 100-turn quota. Historical test details
below are not a claim of full-port certification.

This directory builds and installs Lekmod for Aspyr's 64-bit Steam release of
Civilization V. The game itself is Intel-only, so the library intentionally
targets `x86_64`; Apple silicon runs both through Rosetta 2.

Source builds require Xcode Command Line Tools. Repository and packaged
installs require Python 3 for deterministic standard/EUI configuration.

The port matches the stock `libCvGameCoreDLL_Expansion2_DLL.dylib` ABI:

- deployment target macOS 10.11.6;
- install name and dylib version 1.0.0;
- `DllGetGameContext` as the only exported symbol;
- Aspyr's legacy TR1 container sizes and macOS-only `ICvPreGame1` slot;
- the complete GameCore and Lua source list used by the Windows project.

The Mach-O deployment target matches Aspyr's macOS 10.11.6 minimum, but CI
builds against the current runner SDK. The port is runtime-tested on modern
macOS under Rosetta 2; a release should not claim that 10.11.6 itself was
tested unless it has also passed the smoke matrix below on that OS.

## Build and validate

```sh
python3 ./test-configure-ui.py
./build-macos.sh
./validate-macos.sh --app "/path/to/Civilization V.app"
```

Output is written to
`build/macos/libCvGameCoreDLL_Expansion2_DLL.dylib`. To create a redistributable
directory under `build/macos/package`, run `./package-macos.sh`.
The resulting directory is self-contained: its installer uses the bundled
GameCore and `LEKMOD` payload rather than looking for repository sources. Run
`install-macos.sh --verify-payload` inside an artifact to verify that layout.

## Install

Quit Civilization V, then run:

```sh
./install-macos.sh
```

The installer finds the default Steam app, configures standard UI or detects
EUI, installs the Lekmod DLC data, backs up Aspyr's original GameCore library,
ad-hoc signs the replacement, and validates the installed UI and binary. It
deliberately retains Aspyr's native MainMenu XML because installing a DLC
override for that context crashes the macOS frontend; Lekmod's extra main-menu
buttons are therefore unavailable on macOS. Use `--app` for a non-default
location, `--standard` or `--eui` to force a UI mode, and `--uninstall` to
restore the original library.

Steam's “Verify integrity” operation restores Aspyr's library, so rerun the
installer afterward.

The turn-stability evidence has been accepted by the user; broader single-player
validation is still pending. Earlier hidden-AI visualization and turn-status
suppression experiments did not establish the cause of the reported stall and
have now been removed from source. The installed cleanup passes build/ABI checks
and a focused native three-turn regression (111–113, 12 majors/40 city-states,
no synchronization/Lua errors or new crash reports). Samples of
OpenGL activity alone do not establish that rendering causes a stalled turn.

The 2026-09-12 human-turn repro exposed a separate concrete defect: the LCG
retained a 64-bit `unsigned long` seed on macOS, while Aspyr's
`FDataStream::Write(const unsigned long&)` stores four bytes and `Read` restores
only that 32-bit value. The ensuing RNG sync failure caused `NetForceResync`
and repeated loading/turns even in single-player. `CvRandomSeed.h` enforces the
original 32-bit LCG state without changing class layout or the public ABI.
`test-random-seed.cpp` checks one million transitions and serialized round trips.
Corrected human turns advance without the forced resync; the user accepted the
accumulated turn testing, and the rendering-workaround removal is smoke-tested.

## Unattended native test

With Steam signed in and Civ V closed, run:

```sh
python3 ./automated-playtest.py --mode human-turns --turns 100 --minors 40 --timeout 7200
```

The runner requires Steam to already be running with a confirmed signed-in
session and an unlocked local desktop at startup; it refuses to implicitly
start Steam, unlock the computer, or foreground applications. Launch attempts
that exited with code 255 before gameplay were observed while the Mac was
locked; the supervisor should wait for unlock before retrying. It backs up
configuration, logs, and single-player autosaves under
`build/macos/playtests/<UTC timestamp>`, temporarily appends backed-up Lua
test hooks to the loaded menu/UI scripts, and launches the installed game
with a process-only background activation guard. It must not foreground its
windows. The default stress scenario is a huge map, 12 major civilizations,
40 city-states, 100 turns, with a two-hour time budget. It counts
consecutive `game-turn.end` records from the diagnostic GameCore, rejecting
duplicate/decreasing turn numbers. It captures a process sample on a stall or
timeout and restores configuration and UI files after stopping only its test
instance. A time budget exhausted while turns are still advancing is incomplete,
not a successful test and not by itself a hang.
Original autosaves are retained in `autosaves-before`; test autosaves may
replace the game's rotating autosave slots, but manual saves are untouched.

`--mode autorun` moves the human to a spare observer slot and tests AI play.
`--mode human-turns` keeps player 0 human, founds a city, submits and checks
production orders, chooses research/policies, skips units, and invokes the
normal end-turn button handler. Neither mode certifies physical mouse hitboxes,
all UI panels, or the full smoke matrix below. Harness errors and unhandled
decision prompts must not be mislabeled as game hangs.

The test temporarily dismisses technology awards and a whitelist of other
informational dialogs using their existing close callbacks. These dialogs own
turn-timer semaphores and are not all suppressed by `UI.SetDontShowPopups`.
The normal popup show/hide bookkeeping remains active; required gameplay
choices are not silently dismissed. Temporary Lua hooks are restored afterward.

Human-mode tests now prepare a separately reloadable driver and command file.
On a recognized driver error or ordinary decision prompt, the runner preserves
evidence and holds its own game open instead of force-quitting it. After a
scoped driver correction, `--refresh-driver <evidence-directory>` requests a
reload through Civ V's Lua include mechanism without changing the GameCore or
resetting the turn history. The refresh is not acknowledged until the game logs
`driver-reloaded`. Live refresh was verified in the human HUD, including
closing a newly handled city-state greeting without restarting or resetting
the game. Diplomacy has separate UI contexts: their temporary adapters invoke
the original trade Back/Refuse and enabled discussion callbacks. Human-HUD
refresh does not update hidden diplomacy contexts. Genuine synchronization failures, rollbacks, and crashes
remain failures. The overall time budget is still bounded.

`--load-save <Civ5Save>` resumes a preserved test save in human mode. `--turns`
means that many additional consecutive completed turns, not a target turn
number; loading turn 20 with `--turns 100` targets 100 completions through turn
120. A save load and subsequent progression have been observed with the RNG fix.

On 2026-09-12, a small-map AI-only harness check completed turns 1–10. A huge-map
12-major/24-city-state observer run completed turns 1–7 in four minutes, then
exhausted its time budget without a rollback or crash report. Neither result
establishes that the reported human end-turn hang is fixed. The requested
100-turn, 40-city-state stress test remains to be completed.

The corrected RNG build subsequently completed 16 consecutive human turns with
12 majors and 40 verified city-states, with production/research/policy choices
and no RNG resync or rollback. The run stopped on the ordinary Who's Winning
dialog; that dialog has since been added to the temporary test adapter. A
separate Lua binding correction now returns the real `CanMoveOrAttackInto`
result instead of discarding it. The combined build still needs the full run.

Steam's startup blockage was traced to its synchronous `lsof` socket lookup
walking Docker's large regular-file descriptor table. The separate
[`steam-compat`](steam-compat/README.md) workaround successfully launched the
stable client without restarting Docker. It is not a Lekmod gameplay fix.

## Release smoke matrix

Current user-directed sequence: finish the large turn runs and removal/retest of
experimental suppressions, then complete the remaining single-player checks.
Multiplayer (including hotseat, cross-platform play, and PBEM) is deferred by the
user and must remain marked untested; do not treat it as a passed release gate.

Before describing a build as fully supported, test all of the following with
logging enabled and no new crash report:

- standard UI and a supported EUI release;
- founding a city and selecting unit, building, wonder, and process production;
- save, quit, reload, and advance at least one turn;
- Golden Age focus/yield controls, diplomacy, religion, espionage, trade routes,
  World Congress, and a late-game save;
- hotseat, macOS-to-macOS multiplayer, and Windows-to-macOS multiplayer without
  an out-of-sync event;
- PBEM setup if that mode is part of the release claim.
