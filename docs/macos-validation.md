# macOS validation status

For another task resuming this work, start with
[the testing handoff](macos-testing-handoff.md) and
[the test-tool guide](../LEKMOD_DLL/macos/TESTING.md). The tooling and its required
diagnostic/configuration dependencies are committed. At this resumption the
previous fourteen product/documentation edits had already been committed in
`0952b9e5`, followed by the shared compatibility extraction. Those commits and
the installed handoff binary are preserved.

The [resumed single-player evidence](macos-single-player-20260913.md) separates
physical mouse actions, scripted commands, gameplay outcomes, and incomplete
sessions. The user renewed foreground-testing permission for this task.

## Scope and acceptance

The user accepted the accumulated turn-testing evidence as sufficient on
2026-09-12 (local time). The long turn campaign is closed. The previous target
of 100 uninterrupted additional turns was **not completed** and is not claimed
as passed. Remaining work is single-player functionality and focused regression
checks. Multiplayer, including hotseat and PBEM, is deferred and untested.

## Confirmed fixes

| Item | Evidence | Commit |
| --- | --- | --- |
| Preserve 32-bit LCG state on LP64 macOS | One million x86-64 regression transitions; native runs no longer showed the reproduced RNG mismatch/forced-resync loop | `1024d1e8` |
| Return the actual Lua movement-query result | Native scripted moves to legal adjacent plots succeeded after the binding stopped always returning false | `5deafa1d` |
| Keep unit script-data storage alive until Lua copies it | ASan reproduces the old heap-use-after-free; current binding passes, plus 400 native reads of empty/short/long/Unicode strings with original data restored | `e7cc7580` |
| Pointer-width batch allocator alignment | 256 mixed 1D/2D cases under ASan/UBSan, using the actual templates, including zero dimensions and 12-byte elements | `ded7a74d` |
| Standard tech-tree vertical geometry | Native screenshot shows the full Close button at the tested window size; normal close callback succeeds | `c05a602d` |

## Recorded runtime evidence

- Huge-map fixture: 12 major civilizations and 40 city-states, verified in game
  logs. All 40 city-states still processed the sampled completed round 68.
- `build/macos/playtests/20260912T233131Z`: 72 consecutive completed turns
  (41–112), then a test-driver policy-selection loop. No RNG sync failure,
  forced resync, or protocol error was recorded. The runner terminated its own
  process; this was not a recorded Civ V crash.
- `build/macos/playtests/20260913T001716Z`: loaded the preserved turn-110 save,
  verified the corrected policy choice, and progressed through turn 122. It
  was stopped at the user's acceptance of turn testing. Settings and temporary
  UI hooks were restored; no Lua runtime errors or new Civ V diagnostics were
  recorded.
- Other test-driver failures (dialogs, promotions, movement and policy choices)
  remain labeled as such in their original reports. They have not been relabeled
  as successful runs.

## Remaining checklist

| Area | Status |
| --- | --- |
| Remove experimental AI rendering/turn-status suppression and smoke-test | Passed focused native smoke: turns 111–113, 12 majors/40 city-states; no synchronization errors, Lua runtime errors, or new diagnostics |
| Actual mouse interaction, screen bounds and production UI | Actual clicks cover research/tech-tree open and close, Rome city entry, Worker selection, Workshop specialist assignment/removal, Walls purchase, queue append/reorder, and normal exit. Captures are at 2836×1898; other resolutions and background-only input remain untested |
| Standard UI and claimed EUI support | Standard callback/screenshot coverage below; no EUI installation found, so EUI runtime compatibility remains untested |
| Unit, building, wonder and process production | All four selection callbacks passed. Worker selection and Water Mill queue append/reorder also passed by mouse. Bounded scripted orders produced a Worker on turn 215 and Water Mill on 217, with engine production events and final-state checks. Wonder completion and sustained process-income outcomes remain pending |
| Purchasing and queue removal | Walls purchase by mouse reduced gold 134 → 14, added building 22 and increased displayed defense 56 → 61. Unit/faith purchases and queue removal remain unverified |
| Save, quit, reload | Passed callback-driven local save → normal exit → reload/logical-state comparison. Physical Escape → exit → Yes also exited with code 0 and no supervisor stop in two sessions. Physical save/load menu paths remain untested |
| Extra Lekmod main-menu features | Known parity gap; native Aspyr XML currently retained |
| City focus, specialists and yields | All nine focus callbacks and avoid-growth toggle/restore pass. A real Workshop-slot click added an engineer, removed worked plot 1 and changed production 9.9 → 11 and gross food 11 → 10; removal restored both. Broader specialist/tile controls, physical focus buttons and yield accounting remain pending |
| Religion, espionage and trade routes | Pending |
| Diplomacy and World Congress | Some normal callbacks exercised; full functional checks pending |
| Later-game mechanics | Required Freedom ideology selection through the normal network command was verified in the Modern fixture. This is not mouse/ideology-popup coverage or a naturally progressed late-game campaign. Broader mechanics remain pending |
| Multiplayer, cross-platform, hotseat, PBEM | Deferred by user; untested |

Native-control recheck (`build/macos/playtests/20260913T023845Z`): service
inventory requests now respond, but attachment to the running Civ V bundle ID
still times out. macOS independently reports the game registered and inactive;
the sampled frontmost application remained Codex. No physical input was sent.
The supervisor closed its fixture and restored settings/hooks. This narrows the
blocker to game attachment, rather than establishing that the service is disabled;
whether background-only operation contributes is not yet established.

The subsequent user-approved foreground attachment test
(`build/macos/playtests/20260913T031707Z`) attached successfully and verified the
real mouse paths Choose Research → Open Technology Tree → Close. The first
Choose Research click had no visible effect; the second opened the panel. No
scripted action handlers drove those interactions. The run's 180-second cap
expired during shutdown and the supervisor terminated its own process, so this
is not another normal-exit result. Settings/hooks were restored, no new Civ V
diagnostics or Lua/sync errors appeared, and the game is closed. This comparison
does not yet isolate foregrounding from removal of the background guard.

Keep confirmed fixes in focused commits. Preserve unrelated worktree changes,
keep experiments separate, and do not push without authorization.

Resumed test-tool fixes (`82a57031`) allow engine-legal civilian/military
stacking moves and resolve/verify the required ideology choice. The new bounded
completion harness and CityView observer are in `13f9c622`. These are driver
fixes, not new GameCore fixes. The no-intervention replay is
`build/macos/playtests/20260913T210313Z/report.json`; the preceding run retains
its driver failure and live-refresh history. The generic improvement-adjacency
table warning remains an open issue described in the resumed evidence.

## Focused native functionality evidence

`build/macos/playtests/20260913T015307Z/report.json` records the standard-UI
callback/API checks above. No extra resources or technologies were granted, no
end-turn command was issued, and manual saves were unchanged. Normal load
processing completed the stored turn into active turn 111. No synchronization
failures, Lua runtime errors, or new Civ V diagnostic reports were recorded.
Settings and temporary hooks were restored. The supervisor closed its test
instance; this run is not a normal-exit test.

An earlier fixture driver (`20260913T015126Z`) asserted too soon, before the
loaded game's human turn became active. It remains recorded as a failed test;
the driver now waits for the normal turn handoff. This is not a game defect.

### Modern-era production and normal save/exit/reload

- `build/macos/playtests/20260913T020332Z`: new Huge/Modern fixture with 12
  majors and 40 city-states, using normal setup and a legal settler founding
  action. No end turns, extra resources, or extra technologies were injected.
  Unit, building, wonder and process selection all passed; their queue IDs
  were checked after dispatch through the real ProductionPopup callback.
- The same run captured the tech tree and each production popup without
  foregrounding the game. The Close/Back controls are fully visible at the
  captured 2836×1898 window size. This is not a multi-resolution or mouse test.
- A uniquely named local save was created through SaveMenu's ordinary handler.
  The normal exit confirmation completed and the process exited with code 0;
  the supervisor did not send termination signals.
- `build/macos/playtests/20260913T020622Z` loaded that save and matched the turn,
  capital population, gold/culture/faith, research, focus/growth, production
  queue, and unit IDs/types/positions/moves/script data. All four production
  categories passed again, followed by another local save and normal exit.
- Both runs had no Lua runtime errors, synchronization failures, or new Civ V
  diagnostics. Settings and temporary hooks were restored.
- Earlier exit-adapter attempts (`20260913T015811Z`, `20260913T020034Z`) used
  the ordinary context hidden flag to check a modal dialog. The screenshot
  showed the dialog despite that flag. The test now uses Aspyr's `IsTopModal`
  check; those earlier runs remain failed/interrupted, not retroactively passed.
- Religion is disabled in the Modern-era setup shown by the game. That fixture
  cannot validate religion, and neither its starting turn 214 nor advanced
  starting technologies prove general late-game correctness.

### CityView callback matrix

`build/macos/playtests/20260913T020944Z` reloaded the Modern-era fixture and
entered the normal CityView. It invoked the existing `FocusChanged` handler for
balanced, food, production, gold, science, culture, great-person, faith and
golden-age focus, checking `GetFocusType` after each synchronized change. It
then restored the original focus, invoked `OnAvoidGrowth` twice, and verified
the original growth setting was restored. The city-screen screenshot shows
the nine focus controls and Return to Map fully within the window. Faith focus
selection is tested, but religion itself remains disabled in this fixture.
The run also passed the four production categories and saved/exited normally
(code 0), with no Lua errors, synchronization failures, or new Civ V reports.
Temporary settings and hooks were restored. The offline checks now comprise
five UI-config tests, thirteen evidence-classifier tests, two script-data ASan
tests, and one batch-allocation ASan/UBSan test (256 allocation cases).

## Verified rendering cleanup

The source now calls the original unit visualization and player turn-status
callbacks without the experimental hidden-AI suppression. Only diagnostic
logging remains in the `CvUnit.cpp` and `CvPlayer.cpp` diffs. The RNG and Lua
movement-query fixes are retained.

- Candidate (unsigned) SHA-256: `bb31cfa89c413b1188ea9a4a91fc5c5bfa4bc4fbc0cd8cc2dbaf40bc28b646d2`.
- Installed signed cleanup SHA-256: `ada65581fbe74cce79801c92690923d0a35fd50d1fcbf093cfcabcfc923fa40a`.
- The pre-cleanup binary remains preserved at `build/macos/pre-render-cleanup.dylib`
  (`ccc945046a9fab534029c6f5ffa0d016c5fbe11a07fd2d5aca37bd927ce1c97e`).
- Build, ABI validation, five UI-tool tests, ten runner tests, and the
  one-million-transition RNG regression pass.
- Native evidence: `build/macos/playtests/20260913T012710Z/report.json`.
  Three consecutive turns (111–113) returned to the human player. Settings and
  temporary UI hooks were restored. The runner terminated its own test instance
  after completing the check; this does not verify normal user-initiated quit.
- The UI-control service timed out during the follow-up. No physical mouse
  interaction is claimed from this scripted run.
