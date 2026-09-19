# Duplicate-civilization player colors, 2026-09-19

## Native crash and source cause

The New Zealand first-contact fixture used normal single-player setup with two
New Zealand majors and ten Roman AI controls on Standard Ancient Pangaea,
Always Peace, no barbarians and no huts. No long turn campaign was requested.

Run `20260919T115124Z` crashed with SIGSEGV (-11) before any scenario callback
check ran. The crash report (PID 16714) was preserved in that run directory as
`Civilization V-2026-09-19-075216.ips`, SHA-256
`837d25b37e863f81115610a3cbbf53913d1bea26969e76905280bd78b50e4eb0`.
An identical setup against the previous Zabonah package/core also crashed:
`20260919T115518Z`, PID 17250, native -11; preserved report
`Civilization V-2026-09-19-075613.ips`, SHA-256
`251cfc1289f405cd7ee3f0ee65faa5e224c71aeed57ada69dfdbe275b3ba72ab`.
The two packages had identical payload/compat manifests. The first included the
farm-cache fix, the second did not; the color crash therefore predates that fix.
Both failed attempts preserved saves and restored temporary settings/hooks.
Neither is a pass or a normal exit. The healthy localization database was not
removed, and this is separate from the intermittent startup exit-255 issue.

The shipped PlayerColors table has 182 records spanning IDs 0–183, with holes
at 92 and 174; read-only native database inspection confirmed those same holes.
`CvGame::InitPlayers` resolved duplicate colors by iterating the numeric range
and picking an unused ID, without checking whether the row existed. The twelve
player setup selected missing color 174 for player 11. The engine stack shows
its player-color lookup followed by a null-result dereference at executable
address `0x1007f5adf` (base `0x100000000`), consistent with that invalid assignment.

## Correction and offline regression

The allocator now requires an existing `GC.GetPlayerColorInfo` entry before
assigning an alternate color. Its ordering, valid selected/default colors,
barbarian reservation, database IDs and save format are unchanged. Missing rows
remain missing; the engine is never handed one as an alternate player color.

`test-player-color-holes.py` extracts and executes the actual initial allocation
block under ASan/UBSan. It reads the shipped XML for color availability and
civilization defaults, and uses explicit setup/team/lookup stand-ins. Thirty-seven
cases cover one through 22 duplicate Roman players, the exact two-New-Zealand /
ten-Rome setup, distinct selected colors, sparse interior/trailing holes, dense
compatibility, observer color assignment and closed-slot exclusion. Twenty-four
fail on the original source; all 37 pass after the guard. This is allocator
regression evidence, not a substitute for native rendering/new-game/reload tests.

Intermediate archive: `build/macos/Lekmod-player-color-holes-20260919.zip`,
SHA-256 `9d31987e6fc86240d7c113b3c76dfb2af788f36b72716a4cf6b0d6923c4ac91a`.
Installed signed GameCore:
`4e1a94b9ea8c61c16e18e2bc32a6f46a54941c056bb804b14cfd4c8066bc764b`.
This includes the verified farm fix and was built before the color-fix commit;
it is not the final clean release.

## Native correction and persistence

`20260919T120139Z` repeated the same twelve-player setup with the guarded
allocator. The game reached native gameplay; all player color rows and their
primary/secondary/text components existed, and all twelve colors were distinct.
Resolved colors were `[160,183,77,182,181,180,179,178,177,176,175,173]`: player 11
now received valid 173 rather than missing 174. The New Zealand contact checks
also completed, with no ordinary turn requested. This is not multiplayer or
visual contrast/accessibility certification.

The run saved and exited normally (0), preserving settings/hooks/manual saves
and recording no Lua/synchronization errors or new diagnostics. Save SHA-256:
`851b8c32390b2e93ecb0213c444fe2bb9e2d94590be7f84165fa57262c7dd69d`.
Exact reload `20260919T120411Z` preserved all twelve colors, civilizations, contact
matrix and reward balances, then exited normally with the same cleanup checks.
Reload save SHA-256:
`83d6c91943ade95eaacd4c71d4a037884704f41f1e472714cc8020050ee2de9e`.
All 32 test-runner regressions pass.

The `newzealand-meeting` scenario reproduces the setup with twelve majors and
zero minors, human/AI New Zealand in slots 0/1 and explicit Roman slots 2–11.
Use Standard Ancient Pangaea, Always Peace/no barbarians/no huts, explicit
`single-player-smoke`, `--turns 3 --scenario-turns 1 --timeout 480`. The one-turn
allowance enables informational-popup handling; the successful run used none.
Previously saved invalid-color states were not available from either crash and
are not claimed repaired. The fix governs new-game alternate-color selection.
