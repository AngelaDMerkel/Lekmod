# Lekmod macOS single-player testing handoff

Last updated: 2026-09-13. This is a same-machine, same-workspace handoff, not a
claim that the macOS port is fully certified. No new task or schedule was created.

## Start here

Workspace: `/Users/duffy/Documents/GitHub/Lekmod`. The original handoff used
`main`; the current existing branch is `codex/shared-macos-gamecore`, checked
out by the intervening task. The resumed testing did not switch branches.
At the resumed 2026-09-13 inspection, `HEAD` was `ef173459` and the worktree
was clean. Another task had committed the fourteen changes below in `0952b9e5`,
then extracted/pinned the shared compatibility layer in `ee1f207f`/`ef173459`.
Those commits are preserved. The installed GameCore and both fixture hashes
still match this handoff; the current local build hash is
`c4c149630d34260bd4a30647c8f89c3313ee35175da4d3a5096f3a067e1beb78` and has
not been installed or runtime-certified by these resumed tests.

The user explicitly renewed foreground-testing permission in the resumed
conversation. The runner's 180-second foreground cap remains in force. The
original one-off permission and original dirty-file inventory below describe
the earlier handoff state, not the current checkout or authorization.

Read this document, [validation status](macos-validation.md), and the
[test-tool operator guide](../LEKMOD_DLL/macos/TESTING.md) before taking actions.
The historical 100-turn requirements do not override the user's decisions;
the README's stale instructions have now been corrected.

Suggested prompt for the next task:

> Resume the remaining Lekmod macOS single-player testing in
> /Users/duffy/Documents/GitHub/Lekmod. First read docs/macos-testing-handoff.md,
> docs/macos-validation.md, docs/macos-single-player-20260913.md, and
> LEKMOD_DLL/macos/TESTING.md. Preserve the current checkout and existing edits.
> Do not resume the completed long turn campaign, test multiplayer,
> restart Docker, change Steam's channel, or enable a schedule. The one-off
> foreground permission in the original handoff was later renewed for that task;
> check the current conversation's authorization before another foreground session.
> Use evidence-backed checks and commit verified
> fixes in focused local commits without pushing.

### Non-negotiable scope and permission boundaries

- The user accepted the accumulated turn-stability evidence and ended that
  phase. The previous uninterrupted 100-additional-turn target was **not met**
  and is not claimed as passed. Do not reinstate it or start another long run.
- Remaining work is single-player functionality. Network/cross-platform
  multiplayer, hotseat, and PBEM are explicitly deferred and untested.
- Keep Steam and Civ V in the background by default. Foreground testing is now
  authorized for this resumed task; retain the existing 180-second session cap.
  A CLI flag or this historical handoff alone is not authorization for a new
  unrelated task.
- Do not disrupt Docker, alter Steam's channel, or undo the accepted Steam
  workaround casually. Do not bypass synchronization checks, clear GameCore
  wait flags, or dismiss required gameplay decisions to manufacture progress.
- No new launches while the desktop is locked. Do not unlock the Mac.
- Scheduled testing was canceled/paused at the user's request. No automation
  configuration remained in the local automation directory at handoff. Do not
  recreate `lekmod-extended-background-testing` or the older monitor.
- Commit confirmed changes; do not push. Preserve unrelated edits and manual
  saves. Do not use blanket staging, resetting, or cleaning of the worktree.

## State at original handoff

- Civ V and the Python test supervisor are closed. Last native run's temporary
  configuration/UI hooks were restored, and a source scan found no leftover
  test-hook markers in the installed UI directories.
- Steam is running (PID 99607 at inspection; always recheck). The existing
  socket helper is present and both libraries match its recorded patched hashes.
  No Steam or game installation was changed while preparing this handoff.
- The game installation is **standard UI**, not EUI. Native-control inventory
  requests work. Foreground attachment/input worked; guarded background
  attachment timed out. Foregrounding and disabling the guard changed together,
  so their individual effects have not been isolated.
- The user paused testing to review uncommitted files, then requested that the
  testing tools be committed and this handoff be produced. Do not treat that as
  approval for the previously proposed longer foreground session.

### Installed app, data, and binaries

App:
`/Users/duffy/Library/Application Support/Steam/steamapps/common/Sid Meier's Civilization V/Civilization V.app`

Data:
`/Users/duffy/Library/Application Support/Sid Meier's Civilization 5`

The actual game is `Contents/MacOS/Civilization V`. `AppBundleExe` is its launcher;
do not confuse its presence with a running game or kill an unrelated user instance.
Native-control app ID: `com.aspyr.civ5xp.steam`.

Installed GameCore:
`Contents/MacOS/libCvGameCoreDLL_Expansion2_DLL.dylib`

| Artifact | SHA-256 |
| --- | --- |
| Installed, signed, smoke-tested cleanup binary | `ada65581fbe74cce79801c92690923d0a35fd50d1fcbf093cfcabcfc923fa40a` |
| `build/macos/libCvGameCoreDLL_Expansion2_DLL.dylib` (unsigned counterpart) | `bb31cfa89c413b1188ea9a4a91fc5c5bfa4bc4fbc0cd8cc2dbaf40bc28b646d2` |
| `build/macos/pre-render-cleanup.dylib` (previous signed build) | `ccc945046a9fab534029c6f5ffa0d016c5fbe11a07fd2d5aca37bd927ce1c97e` |

Aspyr's original backup remains beside the installed DLL as
`libCvGameCoreDLL_Expansion2_DLL.dylib.lekmod-original`. Preserve it.
The installed binary includes some remaining uncommitted compatibility changes;
it is not asserted to be a reproducible build of clean `HEAD`. The committed
test tools can resume against this identified local installation, but a clean
release rebuild/install is separate work. Do not reinstall just to start a test.

## What is committed

Confirmed fixes predating this handoff:

- `1024d1e8`: normalize RNG arithmetic/state to Windows' 32-bit behavior.
- `5deafa1d`: return actual `CanMoveOrAttackInto` eligibility to Lua.
- `e7cc7580`: preserve the temporary string until Lua copies unit script data.
- `ded7a74d`: use pointer-width integers in batch allocator alignment.
- `c05a602d`: standard tech-tree vertical geometry.

Testing dependencies committed for the handoff:

- `bd815e71`: turn/render diagnostics, header/logger, installed/ABI validator.
- `0448f5a6`: isolated UI-configuration regressions and paired configurator/XML
  fixes. This is **offline EUI assembly coverage**, not native EUI certification.
- `74b9dc46`: separate local Steam socket-lookup/launch workaround source.
- `31d22c9f`: bounded runner, 18 Lua adapters, native helpers, classifier tests,
  CI test steps, and `TESTING.md`.

The handoff preparation ran the offline tests from a clean export of committed
files, not just the dirty tree: 5 UI-configuration tests, 14 runner/classifier
tests, 2 string-lifetime sanitizer tests, 1 allocator sanitizer test with 256
cases, and the million-transition RNG test passed. Native helper compilation
passed (including both background/foreground helpers and the universal Steam
socket helper). The RNG regression also passed separately on arm64 and x86-64.
The installed binary passed ABI/payload/signature validation. GitHub-hosted CI
and a full fresh GameCore rebuild were not run for this handoff; nothing was pushed.

## Evidence and reusable fixtures

All directories below are under
`/Users/duffy/Documents/GitHub/Lekmod/build/macos/playtests/`.
They are Git-ignored local artifacts, **not included by cloning the repository**.
Preserve them. On another machine, transfer the relevant permitted fixtures and
reports separately or create a new ordinary setup fixture; do not invent missing
evidence or represent a recreated fixture as the original.

| Run | What it establishes |
| --- | --- |
| `20260912T233131Z` | 72 consecutive human turns 41–112, 12 majors/40 city-states; then a test-driver policy loop, not a recorded native crash |
| `20260913T001716Z` | Reloaded turn 110, policy correction verified, progressed through 122; stopped when the user accepted turn testing |
| `20260913T012710Z` | Rendering-suppression cleanup: turns 111–113, no sync/Lua errors or new diagnostics; supervisor closed its game |
| `20260913T015307Z` | Early saved-fixture callback checks; wonder/process had no legal choices and were skipped |
| `20260913T020332Z` | Normal Modern-era setup, legal capital founding; all four production categories, native panel captures, local save, normal exit code 0 |
| `20260913T020622Z` | Reload of that manual save matched the recorded logical-state fingerprint; all four production callbacks; another normal save/exit |
| `20260913T020944Z` | All nine real CityView focus callbacks, including golden-age focus, and avoid-growth toggle/restore; captures, production checks, normal save/exit |
| `20260913T023845Z` | Enabled native-control service but failed attachment to the guarded background game; no physical input; supervisor interrupted/restored |
| `20260913T031707Z` | User-approved foreground attachment; real clicks Choose Research → Open Technology Tree → Close. The 180-second cap interrupted shutdown; **not** a normal-exit result |

Important fixture paths:

- Modern manual save:
  `build/macos/playtests/20260913T020332Z/Lekmod-Functional-20260913T020332Z.Civ5Save`
  SHA-256 `9c4760dda103a62025b5e859ab4dbe10db25537b5d8d7410cbf91eb3a31f1bc6`.
  Its sibling `report.json` contains `saved_state` for reload comparison.
- Huge-map turn-110 autosave:
  `build/macos/playtests/20260912T233131Z/autosaves-after/AutoSave_0110 AD-1000.Civ5Save`
  SHA-256 `50b61ec7b753b6bf3131f8f9be9b0d0c2806e88f918f57613f4174a1037b3c0c`.

Earlier failed test runs remain failed. In particular, an initialization check
ran before the human turn was active, and earlier exit adapters mistook a modal
context's hidden flag for its presentation state. `IsTopModal` fixed the latter.
Do not rewrite old reports as passes. Use accompanying notes/screenshots.

## Resume sequence

1. Read current user instructions and the three documents linked above. Check
   `git status`, process state, desktop lock state, and the installed binary hash.
   Do not assume saved PIDs or foreground approval remain valid.
2. Review the fourteen historical edits and later commits listed below before
   changing anything overlapping them. In particular, handle the older Lua exclusions
   separately from the already removed C++ rendering suppressions.
3. Continue remaining single-player coverage with an explicit fixture and
   assertions. Foreground work is authorized in the resumed conversation;
   preserve its 180-second cap and do not infer permission in an unrelated task.
4. Record exact game/UI configuration, observed input or callback path, expected
   result, actual result, artifacts, errors, and cleanup. Commit each verified
   defect correction and update the validation checklist.

Reference background callback command (only rerun when a focused change warrants
it; it is not the whole remaining test plan):

```sh
cd /Users/duffy/Documents/GitHub/Lekmod
python3 LEKMOD_DLL/macos/automated-playtest.py \
  --mode single-player-smoke --turns 3 --timeout 300 --stall-seconds 180 \
  --load-save '/Users/duffy/Documents/GitHub/Lekmod/build/macos/playtests/20260913T020332Z/Lekmod-Functional-20260913T020332Z.Civ5Save' \
  --expected-state build/macos/playtests/20260913T020332Z/report.json \
  --city-controls --capture-panels --save-and-exit
```

For genuine mouse input, use `ui-interaction`: it loads the fixture but only
observes state, without invoking gameplay callbacks. The existing foreground
exception is capped at 180 seconds; permission was renewed in the resumed task.
Do not lift the cap as an implied consequence of this handoff. About 50–80 seconds of prior
runs were spent starting/loading; leave shutdown time inside any approved window.

Use the native computer-use tool for UI actions. In the successful foreground
run the accessibility tree exposed only the window, so coordinates came from
fresh screenshots. The first Choose Research click had no visible effect; the
second opened it. Do not assume saved coordinates or an unexplained first click
are a game defect. Do not call `getApp` after quitting: it may start a launcher.

## Remaining single-player coverage

See [the resumed evidence](macos-single-player-20260913.md) and the current
validation table for the narrow gaps closed since the original handoff.

- Broader real mouse hitboxes and multiple resolutions; Worker/Water Mill
  selection, queue append/reorder, and Walls purchase have physical-input
  evidence. Queue removal, unit/faith purchase and other production categories'
  mouse paths remain open. Worker/Water Mill completion has a bounded scripted
  gameplay pass; wonder completion remains open.
- Broader specialist/tile assignments and yield accounting. One Workshop
  engineer add/remove has physical-input and matching yield evidence; focus
  enum changes alone do not prove correct yield effects in other cases.
- Supported EUI installation (up to v1.28 is the repository claim), isolated with
  backups. The callback adapters currently target standard UI. No EUI is installed
  locally and no native EUI pass exists.
- Extra Lekmod main-menu features. Aspyr-native MainMenu XML is intentionally
  retained after prior override crashes; the extra mod buttons are absent.
- Religion, espionage, trade routes, full diplomacy, World Congress, and richer
  late-game mechanics. Modern starting turn 214 is a setup value, not evidence of
  214 played turns. That fixture has religion disabled.
- Multiplayer remains outside the current assignment.

## Original uncommitted work (now preserved in `0952b9e5`)

At the original handoff there were 14 modified tracked files and no untracked
testing sources after the tool commits. Review this historical inventory and
the later shared-compatibility commits before changing overlapping code:

| Files | Remaining changes |
| --- | --- |
| `LEKMOD/Lua/Civilizations/Lekmod_newzealand.lua`, `LEKMOD/Lua/Lekmod_units.lua` | Earlier city-state/barbarian unit-handler exclusions; behavioral experiments not established as necessary |
| `CvDllPreGame.cpp`, `CvPreGame.cpp`, `CvPreGame.h` under `LEKMOD_DLL/CvGameCoreDLL_Expansion2/` | Configured SMTP-host getter instead of an empty value, plus header-text cleanup; PBEM untested/deferred |
| `LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvRandom.cpp` | Pointer formatting in logs and header-text cleanup; the RNG-width correction is already committed |
| `LEKMOD_DLL/CvGameCoreDLL_Expansion2/FirePlace/include/FireWorks/FBatchAllocate.h`, `LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaUnit.cpp` | Only final-newline/blank-line remnants; substantive fixes are committed |
| `LEKMOD_DLL/macos/build-macos.sh` | Incremental mode and compiler flags. Incremental checks only `.cpp` mtimes; it is unsafe after header/flag changes. Use a full build when rebuilding is actually required |
| `LEKMOD_DLL/macos/install-macos.sh`, `LEKMOD_DLL/macos/package-macos.sh` | Self-contained package installation/verification changes; do not deploy them casually while auditing |
| `LEKMOD_DLL/macos/README.md`, `docs/installation.md`, `readme.md` | Documentation backlog, including superseded historical test requirements |

## Failure diagnosis and cleanup reminders

The confirmed resync defect was LP64 RNG arithmetic: `unsigned long` grows to
64 bits on macOS, but Aspyr serializes/restores only 32 seed bits. The fixed
LCG normalizes reset/reseed/transitions. Earlier OpenGL-heavy samples did not
establish rendering as the root cause. Do not reintroduce suppressed hidden-AI
visualization/turn-status callbacks based only on GPU stacks.

Read `report.json` and the actual logs; `run-state.json` can lack final fields.
Required logs live under the data directory's `Logs/`: `Lua.log`,
`net_message_debug.log`, `LekmodRender.log`. Duplicate/backward turn ends,
RNG mismatch, `NetForceResync`, protocol errors, and new crash/hang reports are
real failure signals. An ordinary prompt, a driver bug, or a deliberately idle
UI-interaction fixture is not automatically a gameplay hang.

For a suspected sustained stall, preserve the render/Lua tails and take a short
sample of the verified game PID. Historical comparison samples may still exist
at `/tmp/civ5-city-state-turn.sample.txt`,
`/tmp/civ5-city-state-turn-postfix.sample.txt`, and
`/tmp/civ5-render-events-enabled-hang.sample.txt`; their rendering interpretation
was superseded by the RNG evidence. Never clear waits/checks to produce a pass.

Interrupt the verified **runner** with SIGINT for normal tool cleanup, not
SIGKILL. It may TERM/KILL its own game; that is reported explicitly and is not
a native crash or a successful user-initiated exit. See `TESTING.md` for recovery
from a supervisor that died before restoring its settings/UI backups. Preserve
Aspyr originals and user manual saves; test-generated saves have unique names.

Steam's workaround is separate: `LEKMOD_DLL/macos/steam-compat/README.md` explains
the real socket-metadata query replacing the problematic `lsof` command literal.
If Steam is already running, leave it alone. If startup is necessary, use the
existing `Launch-Steam.command` as previously authorized; it preserves backups,
does not change Docker, and refuses unfamiliar patch states. Do not apply a
different Steam update/channel or restore/modify its libraries as a routine game
test step. Original signed backups and the manifest are in
`/Users/duffy/.steam-socket-compat`; helper `/Users/duffy/.steam-ls`.
