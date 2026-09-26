# macOS validation status

For another task resuming this work, start with
[the testing handoff](macos-testing-handoff.md) and
[the test-tool guide](../LEKMOD_DLL/macos/TESTING.md). The tooling and its required
diagnostic/configuration dependencies are committed. At this resumption the
previous fourteen product/documentation edits had already been committed in
`0952b9e5`, followed by the shared compatibility extraction. Those commits and
the installed handoff binary are preserved.

The [Swiss Armory fix](macos-swiss-armory-validation.md) now has seven native
assertions and exact reload on clean source `149e6328`, plus66 callback cases.
Stationary city-granted Mountaineer and full fresh birth/training movement are
verified; further conversion/owner boundaries remain separately scoped. Startup255
recurred before an earlier attempt; startup/shutdown reliability is still open.


The [system outcomes](macos-single-player-systems.md) and
[resumed single-player evidence](macos-single-player-20260913.md) separate
physical mouse actions, scripted commands, gameplay outcomes, and incomplete
sessions. The user renewed foreground-testing permission for this task.

## Current pause and confirmed open defect

Testing is paused at the user's request after `20260926T043437Z` confirmed that
Swiss Armory training grants Mountaineer without refreshing its active terrain
bonus. [The reproduction and preserved checkpoint](macos-swiss-armory-validation.md)
are ready; the fix and retest remain next. Stock is restored and Civ V is closed.
This building-granted unit is outside the 125 replacement-unit inventory.

## Special unique-unit acquisition (September 26 UTC)

[Special acquisition](macos-special-unit-acquisition.md) now closes the ten
non-production definitions alongside the earlier Swiss purchase. Nine new cases
passed 42 assertions/nine exact replays, plus two new human-fixture baseline
replays. Combined with ordinary production, all 125 enumerated replacement definitions have at
least one own-civilization acquisition/resulting-state replay path. This is not
full ability, mission, human-owner or every-state coverage.

The tests distinguish supplied GPP/XP/faith/religion inputs from ordinary births,
actual combat awards, purchase callbacks and immediate movement. Method-binding,
callback-order, pressure-unit and turn-observation mistakes are retained as
harness failures. No new product fix was established. The final prophet case
verifies a full low-faith round; a positive City of God free-prophet test is not
claimed from its earlier failed commissioning runs.

Latest independent stock checkpoint: 600 prior manual saves, original quicksave,
settings,32 stock UI files and both backups preserved; Civ V closed. Evidence:
`build/macos/special-acquisition-validation-20260926.json`. The later pause above supersedes the earlier continue instruction. After resumption: unresolved startup
reliability and the remaining concrete ability/state boundaries. Do not reopen
the accepted campaign or multiplayer.

## Unique-unit production continuation (September 26 UTC)

The [own-civilization production catalogue](macos-unit-production-validation.md)
now covers all **115 production-capable unique definitions**: 145 functional
assertions and ten exact replays across the saved civilization groups. The ten
special-acquisition definitions remain separately enumerated. This adds native
owner-production evidence (nine human / 106 AI acquisitions), not full unique-unit
ability coverage or new physical mouse coverage.

Three fixture issues were corrected: AI resource consumption before test setup,
Colorado's dynamic strength expectation, and Portugal's actual trade-route
prerequisites/three-round budget. The failed pilot and two mixed batches remain
failed; passing stage/reload pairs and focused recoveries are identified in the
report. No new gameplay defect or product fix was established. Startup255 recurred
before one attempt; its nonempty healthy cache was preserved and the cause remains
open. No healthy cache was manually deleted.

Latest independent evidence: `build/macos/unit-production-validation-20260926.json`.
Stock restored, Civ V closed, 569 prior manual saves, original quicksave, settings,
32 stock UI files and both backups verified. Continue broader ability/owner/state
and special-acquisition gaps; do not repeat the accepted campaign or claim full
single-player support from this catalogue.

## Latest clean-artifact qualification

Clean-source candidate `f33cfd33` fixes missing College great-person rewards
after city loss. The source loop skipped surviving cities beyond the current
city count; it now uses the engine's city iterator. The native failure granted
zero science/faith after a real capture; the same saved fixture now grants the
expected 50/50 on Quick. All 128 source-block sanitizer cases pass.

The clean archive `9005a104…09b01` passed 33 functional checks and seven exact
replays in one 264.1-second process, with normal exit and complete restoration.
[Special-building evidence](macos-special-building-validation.md) records both
purchase currencies, holy-city production/free rewards, real capture/annexation
and Outremer effects, normal and post-capture College rewards, and full hashes.
All 90 unique building definitions now have at least one acquisition/persistence
path covered across the regular and special catalogues; not every effect or
owner/state combination has been tested.

The earlier Tunisian flag fix, 125 unique-unit creation/disband cases, 114 normal
civilization starts/replays, 81-check comprehensive batch, five lifecycle cycles
and physical UI acceptance remain scoped historical evidence.
[Release qualification](macos-release-qualification.md) distinguishes artifacts.
Historical startup/shutdown failures and broader ability/effect coverage remain
open. Scripted callbacks, native outcomes and physical input remain distinct;
full single-player certification is not claimed.

## Latest civilization ability continuation

The unchanged clean `f33cfd33` package now has [additional Vatican, Israel and
Jerusalem evidence](macos-vatican-validation.md): 45 passing functional assertions
across seven stage/reload pairs and a new Vatican-human baseline replay. This
covers St Peter's pressure/delegates and actual settlement, both Courthouse event
paths, all seven Great Person improvement bonus comparisons, capped kill faith,
worked terrain yields, unique-unit acquisition and unit/trait reward stacking.
The latest three-stage batch passed intact; earlier failed commissioning batches
are retained with their specific fixture corrections. No new product fix was
required. Remaining unit utilities and owner/state boundaries remain open.

After explicit resumption, the [Swiss utility continuation](macos-swiss-crusader-validation.md)
closed both earlier fixtures and added city-plunder and hostile-healing boundaries:
17 checks/six exact reloads passed across three runs. A real test-harness defect
that copied an asynchronous save too early was fixed in `d7dd1237`; original saves
and failed evidence were preserved. Startup-255 recurred and remains unresolved;
failure-cache preservation is now in place. No product code was changed for these
Swiss tests. Stock, backups, 541 prior manual saves, quicksave, settings and 32
stock UI files were verified at the resulting checkpoint.

The upgrade/faith follow-up adds twelve passing functional assertions and two
exact reloads on the same product: actual upgrades preserve/drop the specified
promotions, remove intrinsic old-unit rewards and retain Vatican trait faith;
Maccabee faith purchase respects religion, belief, owner replacement and exact
80-faith gates. Native commands/callbacks are distinguished from supplied input
state in [the report](macos-vatican-validation.md). The latest stock/preservation
checkpoint covers546 prior manual saves, quicksave,32 UI files and both backups.

## Scope and acceptance

The user accepted the accumulated turn-testing evidence as sufficient on
2026-09-12 (local time). The long turn campaign is closed. The previous target
of 100 uninterrupted additional turns was **not completed** and is not claimed
as passed. Remaining work is single-player functionality and focused regression
checks. Multiplayer, including hotseat and PBEM, is deferred and untested.

## Confirmed fixes

| Item | Evidence | Commit |
| --- | --- | --- |
| Visit surviving cities after capture/raze when awarding great-person building yields | Native ordinary College reward 50/50; post-capture 0/0 before fix and 50/50 after; exact reload plus 128 source-block sanitizer cases | `f33cfd33` |
| Preserve 32-bit LCG state on LP64 macOS | One million x86-64 regression transitions; native runs no longer showed the reproduced RNG mismatch/forced-resync loop | `1024d1e8` |
| Return the actual Lua movement-query result | Native scripted moves to legal adjacent plots succeeded after the binding stopped always returning false | `5deafa1d` |
| Keep unit script-data storage alive until Lua copies it | ASan reproduces the old heap-use-after-free; current binding passes, plus 400 native reads of empty/short/long/Unicode strings with original data restored | `e7cc7580` |
| Pointer-width batch allocator alignment | 256 mixed 1D/2D cases under ASan/UBSan, using the actual templates, including zero dimensions and 12-byte elements | `ded7a74d` |
| Standard tech-tree vertical geometry | Native screenshot shows the full Close button at the tested window size; normal close callback succeeds | `c05a602d` |
| Preserve unit-owner abilities and Defender player IDs | 17 actual-Lua regression cases; native minor Defender and minor/barbarian Helicopter Gunship states verified | `3d97c2a3` |
| New Zealand science without selected research | Actual-Lua reward test and native +12 overflow/progress-preservation check | `5ca189f2` |
| Accept boolean SetXY flags and route SetHasTech flags correctly | Actual Lua binding harnesses: 34 position cases plus invalid type, 16 technology combinations; native boolean call and scenario technology setup | `8f902063`, `7188275c` |
| Restore building-derived trade bonuses after loading | Before: route 8.10 → 5.60 gold. After: exact old-save snapshot remains 8.10; 128 six-array sanitizer cases | `a8bc7d38` |

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

## Single-player coverage matrix

The user restored foreground permission on 2026-09-15 and removed the old
three-minute limit. [Current physical evidence](macos-physical-validation-20260915.md)
closes standard queue removal, tile assignment/reset and the smaller-window
tech-tree Close path. EUI city/focus/specialist/tile controls, purchase, queue
selection/reorder, tech-tree Close and physical save/load/normal exit also passed.
The planned mouse continuation is complete; the system report still records
startup-only code 255 exits whose cause has not been isolated.

| Area | Status |
| --- | --- |
| Clean-source package, stock restoration and reinstall | Passed: clean commit `293e2235`, archive `2a9b3ce9…ca84f`, 4,086 payload files matched, stock/Aspyr backups and all prior manual saves preserved. Final native smoke `20260914T051747Z` passed all ten checks and normal save/exit |
| Remove experimental AI rendering/turn-status suppression and smoke-test | Passed focused native smoke: turns 111–113, 12 majors/40 city-states; no synchronization errors, Lua runtime errors, or new diagnostics |
| Actual mouse interaction, screen bounds and production UI | Actual clicks cover research/tech-tree open and close, Rome city entry, Worker selection, Workshop specialist assignment/removal, Walls purchase, queue append/reorder, and normal exit. Physical focus/save/load also passed at requested 1280×800 (2560×1656 captured backing buffer); background-only mouse input remains untested |
| Standard UI and claimed EUI support | EUI 1.28g passed three scripted turns, shared normal save/exit and exact inventory reload, with complete standard-payload/text/options restoration. Its HUD is captured at 1280×800. Selected EUI mouse controls and a physical save/load/normal-exit workflow passed in `20260915T222014Z`; broader popup coverage is not claimed |
| Unit, building, wonder and process production | All four selection callbacks passed. Worker selection and Water Mill queue append/reorder also passed by mouse. Bounded scripted orders produced a Worker on turn 215 and Water Mill on 217, with engine production events and final-state checks. Globe Theatre completed through normal production; Wealth settlement matched actual treasury history in the small Congress fixture |
| Purchasing and queue removal | Walls purchase by mouse reduced gold 134 → 14, added building 22 and increased displayed defense 56 → 61. Gold caravan and faith missionary purchases passed through real popup callbacks; Water Mill queue removal passed in both UIs. EUI Aqueduct purchase spent 120 gold and added building 67; Caravansary selection and drag-reorder passed |
| Save, quit, reload | Passed callback-driven local save → normal exit → reload/logical-state comparison. Physical Escape → exit → Yes also exited with code 0 and no supervisor stop in two sessions. Physical Save and Load Game selections passed at the smaller window size, with the loading adapter dismissing the loading screen; the earlier sessions reached their cap before normal exit. EUI physical save/load plus normal exit completed in the later `20260915T222014Z` session |
| Extra Lekmod main-menu features | Optional version/download and Discord/GitHub shortcuts omitted; native Aspyr XML retained. These are not gameplay systems |
| City focus, specialists and yields | All nine focus callbacks and avoid-growth toggle/restore pass. A real Workshop-slot click added an engineer, removed worked plot 1 and changed production 9.9 → 11 and gross food 11 → 10; removal restored both. Physical Food Focus selection passed; physical tile assignment/reset passed with matching worked flags and food/production changes. Trade income and Wealth use actual gameplay settlement checks |
| Religion, espionage and trade routes | Pantheon/founding/enhancement, missionary purchase/spread and reload passed with labeled resource/unit setup. Trade route, income and corrected reload passed. Spy assignment/recall/diplomat and persistence passed; diplomat reached schmoozing through four ordinary turns. An earned 230-science popup award and recall passed after eight ordinary turns with labeled research-city setup; exact research/spy-state reload passed |
| Diplomacy and World Congress | Congress formed, proposal and three yes votes resolved into engine-confirmed enactment; exact saved-state reload passed. A legal embassy offer passed through Trade, Propose, acceptance, Back and Goodbye; exact embassy/deal-state reload passed |
| Later-game mechanics | Required Freedom ideology selection through the normal network command was verified in the Modern fixture. This is not mouse/ideology-popup coverage or a naturally progressed late-game campaign. Ordinary two-turn score resolution, the human defeat screen and normal exit also passed. Other victory routes are not covered |
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
