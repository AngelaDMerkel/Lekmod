# Philippines founding-quota validation

Current Mac, standard UI, single-player human Philippines and AI Rome. The normal
Ancient/Tiny Pangaea setup had no city-states or barbarians. Extra Settlers and
ruin-free legal staging locations were supplied; city founding used real actions.

## Baseline and native defect

`20260918T084918Z` verified capital exclusion, one population/marker for each of
the first two expansions, and no bonus on the third expansion or Roman capital.
The awarded population was checked immediately after founding; later ordinary
city growth/starvation is separate. Save SHA-256:
`7c91faa6dde6728bb888cdd046fbe39d673b0f154a318436e8f09c86b238814c`.

`085401Z` loaded that four-city save and declared war through the normal command.
On Rome's actual active turn, a supplied Giant Death Robot, uranium and upkeep
budget enabled one legal adjacent move/attack. The real CityCaptureComplete
changed ownership of a noncapital awarded city. No city damage or ownership
was assigned. The Philippines retained three cities and one marker.

A supplied Settler then used normal Found at another ruin-free legal site.
This fourth expansion wrongly received a marker and population 2. The handler
counted currently owned markers, so losing an awarded city reopened the quota.
The failed verdict was retained alongside a diagnostic save and normal exit 0.
Failed-save SHA-256:
`52cdbac76304e5d13d011de3061f11dccc707cbf927d5fe199513b10d29f31b6`.

## Correction

Lua now queries the engine's existing lifetime founded-city counter. The capital
counts as the first founded city, so only the next two qualify. Capturing cities
does not increase that count and losing cities does not decrease it. The new
read-only `Player:GetNumCitiesFounded()` binding exposes a counter already
serialized since v30; no object-layout or save-format field was added.

For older DLLs lacking the getter, the Lua keeps the prior marker-count fallback
instead of failing at runtime. The corrected lifetime behavior requires the
matched updated DLL. No Windows runtime fix is claimed from these Mac tests.
Existing excess awards in older saves are not retroactively removed.

Twelve isolated product-handler cases pass after reproducing the lost-one and
lost-both failures on the original source. Cases cover the first two, later
foundings, acquisitions not spending the founding quota, separate AI ownership,
capital/dead/other-civilization exclusions and old-DLL fallback compatibility.

A full rebuild was performed because the Lua binding header changed. ABI
validation retained the sole GameContext export, 474 imports and 359 dynamic
lookups. The managed intermediate archive is
`build/macos/Lekmod-philippines-quota-20260918.zip`, SHA-256
`52c8b6d826f05fdcff968e871206eb85b5b1406387531539fad5a5c4de1e5a70`.
Its signed GameCore is
`e5804484ab9743361d5819058c29606d1463bbbaf973c6f5b1adbf3f2dd08b22`.
It was built from `747548fc` plus the then-uncommitted fix/tests. Final clean
release validation remains separate.

## Native retest and persistence

`20260918T090306Z` repeated the actual capture and later founding from the same
baseline save. After capture, the Philippines had founded four cities but owned
three; Rome had founded one but owned two. The later founding raised the human
history to five and gave no marker or extra population. Save SHA-256:
`328a3aa5d9cd959a2de7ac67d17a3af0467531c6b605424c4b7e538620277f3b`.

`090501Z` matched the exact saved ownership, population, marker, capital,
original-owner and war state. Its read-only history records remained human 5 /
AI 1 despite owned counts 4 / 2. Reload-save SHA-256:
`6ef643edba2481a7b7561443180facedc3dea6a4933f6cda6abfa8a164dcd7cd`.
Both saved/exited normally (0), restored hooks/settings and preserved manual saves,
with no Lua or synchronization errors.

These are scripted setup/commands and native founding/combat/ownership outcomes,
not mouse input or earned Settlers/late-game armies. The civilian movement bonus,
Marine and National Church remain separate coverage.

`20260918T090810Z` replayed the original initial save on the rebuilt DLL. Capital
and other-owner exclusions, the first two population awards and the third-city
rejection all passed, with lifetime history equal to the observed founding
sequence. It saved/exited normally (0) with restoration/preservation and Lua/sync
checks passing. Save SHA-256:
`5205f0d4534750fed456e61dc36b50b2d21b4e6568bb89500768dba3c81fe98f`.
Thirty-one runner regressions also pass.

## Civilian movement and normal refresh

`20260918T091920Z` supplied Workers, Settlers and Scientists on distinct owned
and neutral land plots, an owned Philippine Warrior and a Roman Worker control.
No movement counter was assigned. Workers/Settlers had native maximums of 240
on owned land and 120 on neutral land; Scientists, whose base is four moves, had
360 and 240 respectively. The own combat unit and other-owner Worker stayed at
their base 120. One ordinary turn retained the six human probe positions/owners
and refreshed each budget exactly to its quoted maximum.

Save SHA-256: `1121b5710d53d9f2dd9b2b1b5f52b8ca464a30db6f894eaf659dd14524e8c225`.
The original PASS detail mentioned the Worker/Settler budgets only; its actual
assertions and structured records used each unit's correct base value. A retained
clarification and corrected future message explicitly distinguish Scientists.

`094245Z` reloaded the complete recorded unit identities, owners, types, positions,
territory, movement, maximum, combat and embarked fields exactly. Reload-save
SHA-256: `4ce35aaaff4d2808261cb2c32f7ee333baf942e4562b18097a59c5f7a6570dcc`.
Both successful runs saved/exited normally (0), restored settings/hooks and
preserved manual saves, with no Lua/sync errors. The intervening `092553Z` and
`092829Z` attempts failed during localization startup before reading the save;
the separate logging-only control and cache evidence are in the startup report.

This is native movement-budget and turn-refresh coverage for three civilian
classes, plus combat/owner controls. It does not claim a physical movement path,
foreign open-border territory, embarked-unit or every civilian-class behavior.

## National Church prerequisites, yields and training XP

The active building Help/Strategy points to `TXT_KEY_BUILDING_NATIONALCHURCH_HELP`:
Compass, no prerequisite building, cheaper than Zoo, +1 culture/+2 faith and
+15 training XP. The separate older `_STRATEGY` text describes a superseded
Temple/four-faith rule and is not the building's active reference.

`20260918T094631Z` verified the Church unavailable before Compass, then available
at Compass while Printing Press, Temple and Colosseum were all absent. The base
Zoo was rejected and its quoted cost exceeded the Church's. Technologies and
production one hammer below completion were labeled inputs. One ordinary turn
completed the Church through CityConstructed: base culture 1→2, faith 0→2 and
quoted Scout production XP 0→15. A second normal production order and similarly
provided near-complete progress produced a real Scout with exactly 15 XP through
CityTrained. No completed building, unit or XP value was assigned.

Save SHA-256: `c4e730a13f5729f3b24a8beb72d930305ce74dcaa257bf7b6d096f05fe5b618a`.
Exact reload `094859Z` matched the Church count, absent prerequisite buildings,
base yields and all human unit identities/types/XP/positions. Reload-save SHA-256:
`4741528adc996d1d5e400c7dc373fa677e4933b1cbe41e804989b6d2c9c14cb5`.
Both saved/exited normally (0), restored hooks/settings and preserved manual saves,
with no Lua/sync errors. This is scripted production/native outcome coverage,
not mouse input or earned research/production. No product correction was needed.

## Gerilya strength, embarkation and land boundary

`20260918T095334Z` supplied a Gerilya and same-owner Expeditionary Force control
on distinct neutral coastal staging plots, plus an upkeep budget. Their native
land strengths were 55 and 40, matching the current data, with equal 180-point
(three-move) land limits. Only the Gerilya had its unique Marine promotion.

Both used normal land-to-coast moves; no embark flag was assigned. While embarked,
their limits were 360 and 180. One ordinary turn refreshed actual movement to those
exact values: the Gerilya received three extra moves. Their embarked combat
query was 12 for both; the 55/40 strength comparison is a land-state result.
Save SHA-256: `386a010376dc308725f3a432213f595eb4390256eeee191e56b32e1b1776e8fc`.
`095548Z` matched the complete embarked comparison state on reload; reload-save
SHA-256: `663c35b5349ec40cf1245a0fb12c83c3466bdacb94c69a300cfd88d23dbdeff0`.

`095814Z` resumed that actual save and issued two normal coast-to-land moves.
Both land limits returned to 180; the Gerilya retained its promotion and 55 strength
versus the control's 40. Both movement budgets were 0 after disembarking, without
a turn advance. Save SHA-256:
`7a755682d077f07e2b290efd9a12f1e34175dff8ea85dbb894db1c20158be3ba`.
Reload `100336Z` matched state but stalled after Exit confirmation and required
SIGTERM; it remains a failed shutdown run. Separate retry `100854Z` matched state
and exited normally. Its reload-save SHA-256 is
`3b26b0c5a6d3ecf2b19a82cbe4d8a914d47ca897c1351b020b6a40396b0711b2`.

All four successful action/reload runs exited 0, restored settings/hooks and
preserved manual saves, with no Lua/sync errors. These are scripted moves and
native outcomes with supplied units, not mouse input, normal Gerilya production
or combat-damage testing. The failed shutdown has the same main-thread join /
SDLTimer future-wait pattern as the earlier failures and remains unresolved.
