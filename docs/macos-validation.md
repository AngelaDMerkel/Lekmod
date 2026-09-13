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
| Remove experimental AI rendering/turn-status suppression and smoke-test | Pending; changes must not be committed until verified |
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
