# macOS validation status

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
| Actual mouse interaction, screen bounds and production UI | Pending; scripted command/queue checks alone are insufficient |
| Standard UI and claimed EUI support | Broader runtime validation pending |
| Unit, building, wonder and process production | Partial scripted evidence; full UI matrix pending |
| Save, quit, reload | Loads and resumed turns observed; focused user-workflow check pending |
| Extra Lekmod main-menu features | Known parity gap; native Aspyr XML currently retained |
| City/yield controls, religion, espionage and trade routes | Pending |
| Diplomacy and World Congress | Some normal callbacks exercised; full functional checks pending |
| Later-game mechanics | Pending; turn number alone is not proof of feature coverage |
| Multiplayer, cross-platform, hotseat, PBEM | Deferred by user; untested |

Keep confirmed fixes in focused commits. Preserve unrelated worktree changes,
keep experiments separate, and do not push without authorization.

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
