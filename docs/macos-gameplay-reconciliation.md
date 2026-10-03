# Gameplay acceptance reconciliation (G0 in progress)

The [final acceptance plan](macos-final-acceptance-plan.md) is being executed.
The [case register](macos-gameplay-acceptance-cases.json) exists, but **G0 has not
passed** and the final gameplay case denominator is not frozen. No new native
gameplay or reliability pass is claimed from this inventory/preflight work.

## Verified discovery inputs

The starting Steam-enabled package remains
`build/macos/Lekmod-steam-startup-20260926.zip`, SHA-256
`edd00aa4d8eca910ee90777465e6db7eeae92b02aa2bff709f44fdb06b529002`.
Its signed GameCore and payload match the earlier comprehensive run's gameplay
components. That older run used process-only startup correction; it is not new
installer/Steam evidence.

The preserved native resolved database is
`build/macos/startup-stat-fix-20260926/installed-20260926T225114Z/cache-after/files/Civ5DebugDatabase.db`,
SHA-256 `8c0f687004e87d239e2bfae9c84c7cb485c48d892a97e66a983230927428427c`.
It was opened read-only/immutable, passed quick_check and retained its byte hash.
Archive members and the authoritative gameplay XML were checked against hashes.

Discovery found460 tables and114 playable civilizations. Conservative review
surfaces comprise938 non-default scalar fields,303 populated relation/system
tables, and97 Lua event-handler identities in the literal InGame context/include
closure. These **1,338 surfaces are not 1,338 required new tests or bugs**. Many
are parameters of shared mechanics, reference data, already-tested behavior or
presentation data. Every parameter row is retained for proper grouping rather
than assumed equivalent. Conditional Lua/native branches still need review.

Seventy-five empty tables,48 presentation/metadata tables and3 multiplayer tables
have explicit inventory dispositions. Thirteen additional scalar presentation
references have been separated while retaining their G7 UI obligations. The
static closure resolves37 packaged Lua files; it is not an exhaustive analysis
of dynamic UI add-ins. A conservative entity/reference index links all114
civilizations to their trait, replacement, improvement, promotion and handler
surfaces. It does not itself prove reachability or behavior.

Retained raw discovery and review outputs are under
`build/macos/acceptance-g0-20260926/`; their paths/hashes are in the case register.
Sources are in `LEKMOD_DLL/macos/gameplay_acceptance.py` and the gate checker
`check-gameplay-acceptance.py`. Seven discovery tests and13 register/evidence
checks pass. The gate checker verifies actual native assertion/replay/exit and
preservation records for retained batch evidence; filenames alone cannot pass.

## Case reconciliation so far

The16 comprehensive scenario/replay pairs from `20260926T222217Z` were reverified:
all81 declared assertions, exact snapshots, checkpoint hashes, native exit0,
no recorded Lua/synchronization/crash failures and successful restoration.
Their exact bounded scope is carried into16 register cases. This does not close
whole traits or every parameter in a shared table.

Ten new case designs are recorded. City of God, airlift, paradrop and exotic-goods
sales have source-derived oracles and pinned starting fixtures. Native action
sequencing still requires implementation/commissioning. The remaining six
ownership/healing/upkeep designs have
pinned starting fixtures but still need action-sequence/branch review. The124
initial pending document rows are indexed; the startup and final-artifact rows
are assigned to later F/R gates, leaving122 gameplay/document reviews unfinished.
One effect surface is mapped to the City of God design. Other surface mappings
remain explicitly untriaged, with no invented acceptance percentage.

## Unit-mission review

The native database contains59 mission definitions. A source-mention index is
retained in `mission-review.json`; absence from a test source is not automatically
a gap (some names are internal animation/queue events or aliases). Direct source
review produced three additional G3 designs:

- Airlift: all four configured airlift buildings, source/destination/team/domain
  gates, adjacent-enemy rejection, real relocation and movement exhaustion.
- Paradrop: the9- and40-tile promotion ranges, exact range/visibility/movement
  gates,30 native movement-point cost, attack-state and replay checks.
- Exotic goods: all three one-charge unit variants, peaceful foreign adjacency,
  independent distance-based gold/XP calculations, stock consumption and repeat
  rejection. The native action's boolean return alone is not an outcome oracle.

Their fixture placement checks and scenarios are not yet implemented or executed.
The corresponding data surfaces are mapped to these cases; G0 is still open.

## Prepared first gameplay batch

`batch-plans/city-god-grant.json` has three independent reloads of the untouched
Spain/Tibet fixture: human/default Prophet, explicitly targeted Tibetan AI/Dalai
Lama, and a no-free-prophet reformation control. It declares21 assertions, three
exact checkpoint reload comparisons and a three-turn aggregate cap. The role
parameters are enumerated data, checked before installation and copied into each
stage's lexical environment; scenarios cannot rewrite the plan's parameters.

Expected results follow the enabled native paths:

- `ResponseFoundPantheon` routes reformation beliefs through eligibility checks.
- `DoReligionOneShots` grants one civilization-specific prophet, without charging
  faith or incrementing the paid-prophet counter.
- The active `addFreeUnit` path initializes the unit at its capital before legal
  relocation, so its religion and four/default or five/Tibetan spreads derive
  from that city and the unit definition.
- A repeated request is rejected; one genuinely advanced owner round must not
  produce another grant. No elapsed-turn or synchronization state is assigned.

Syntax/native-method/fixture preflight passes. The28 Python batch tests,19 actual
Lua dispatcher tests and34 runner tests pass. These are harness checks, not
native City of God coverage. The built-in exact replay is read-only; an additional
post-load repeat-request action still needs commissioning from generated saves.
Under the September27 scheduling refinement, the selected case can run after
its individual readiness/source/fixture checks, while global G0 remains open.
Global G0 still must close before candidate freeze and reliability qualification.

## Source-contract concern awaiting a gameplay reproducer

`BUILDING_MUGHALS_CARAVANSARY` configures `GarrisonMaintenceFree`, while enabled
native code reads `GarrisonMaintenanceFree`. The latter column is absent from
the preserved resolved schema. The correctly spelled loader string is present
in the actual pinned GameCore; the misspelled data string is not. A lexical
review of eight primary native loaders found this one close-name configured
mismatch; other missing legacy columns are not thereby classified as defects.

This is a source-contract mismatch, **not yet a demonstrated native upkeep
failure**. The planned reproducer uses registered `GetNumMaintenanceFreeUnits`
for an exact +1/-1 garrison check, `CalculateUnitCost`, ordinary treasury
settlement, move-out/removal controls and replay. It will distinguish this flag
from the separate500-hundredth city-strength bonus. No product fix has been made.

## Current installation discrepancy

At `2026-09-27T02:58:24Z`, the stock executable and core retained their known hashes,
and the Aspyr `.lekmod-original` backup retained the stock core hash. Civ V was
closed. However, WSDLC's canonical state/core/host backups and all672 previously
recorded non-autosave paths were absent from the recorded user-data directory.
The directory itself remains accessible. None of those files was deleted or
moved during this offline round; no native installation was performed.

Evidence: `build/macos/acceptance-g0-20260926/current-installation.json`.
Exact matching repository copies of all672 prior saves, including the original
quicksave, were located and hashed; `recoverable-saves.json` records each mapping.
No copy was restored to the live user-data folder.

The user has been asked whether the data was intentionally moved/reset. Read-only
checks of known neighboring Civ V/Aspyr locations found no matching relocated
folder; macOS denied filesystem access to Trash. Do not infer data loss or restore
old test files over a deliberate cleanup. Preserve the repository's verified
fixture/evidence copies and resolve the live-data baseline before another game
installation. Offline G0 work may continue independently.

## Next work

Continue mapping active effects to case families and source-derived outcomes,
reconcile the122 remaining document rows, and resolve the external/redundant Lua
include references. Complete the first ownership/upkeep designs. Keep G0 false
until the checker verifies all required mappings/designs. Then execute the
prepared City of God batch, close its post-load repeat case, and proceed to G2.
Reliability remains after gameplay closure and candidate freeze.

## September27 authorized data recovery and continuation

The user confirmed deletion of Application Support was unintended and authorized
necessary recovery to continue testing. All672 prior single-player saves were
restored byte for byte to their original paths, including the original quicksave.
Ninety-five newer saves and three current settings files were snapshotted and
preserved unchanged. The three verified pre-deletion settings files were retained
separately; surviving current preferences were kept active. No game was launched
for recovery. Evidence: `build/macos/data-recovery-20260927/report.json`.

Current WSDLC is `950a329`/v1.0.10. Its168-test suite passes in the isolated
`build/macos/test-deps/wsdlc-runtime` environment with its committed hash-pinned
certifi2026.7.22 dependency. An earlier system-Python attempt had one dependency
version error (installed certifi2026.6.17); that result is retained separately.
No global Python package or WSDLC product source was changed.

The [plan](macos-final-acceptance-plan.md) now permits independently reviewed
cases to run while unrelated discovery mappings remain open. The global G0 gate
has not passed, no coverage requirement was waived, and reliability still follows
complete gameplay closure. `check-gameplay-acceptance.py --require-ready-case`
checks selected-case design and pinned implementation/plan identities in addition
to the whole register's evidence identities. Sixteen gate-checker tests pass.
The next managed City of God batch will recreate canonical backups before launch
and restore stock afterward through WSDLC; verify those actual results separately.

## September27 native evidence reconciliation

The current candidate passed the81-assertion/16-replay comprehensive batch
`20260927T223201Z`, with normal exit and independently verified preservation.
The28 currently specified cases pass; this does not close the discovery review.

Three building fields now have narrowly justified gameplay mappings. The sole
configured `GarrisonMaintenceFree` and `GarrisonStrengthBonus` values are covered
by the Mughal production, movement, treasury, removal and affected-save tests.
The six `BuildingProductionModifier` values share one additive native contribution
path, covered by the Moorish30/15/0 modifier, production and transfer checks plus
the compiled-cache audit of every10/15/25 parameter. Other effects and acquisition
conditions of these buildings remain separate review obligations. Source hashes
are pinned in each mapping and checked by the acceptance validator.

The ledger column header was excluded as a non-requirement. There remain1,318
untriaged review surfaces and121 document rows; G0 is still open. The retained
review record is `build/macos/acceptance-g0-20260926/building-scalar-review-20260927.json`.

## Historical process-pair evidence and handler review

The register now verifies historical separate-process runs with a distinct
`native-run-replay` contract. Both reports must be pinned, passed, complete and
free of recorded errors, with normal exit0 and full restoration. It verifies
all required assertions, the exact replay state, the original load identity,
and hashes of both retained and live source save files after the writer exited.
Missing/skipped assertions, failed sessions, mismatched states, corrupt saves
and missing restoration are rejected. All34 gate-checker tests pass.

Nine existing run/replay pairs account for26 native assertions in three added
cases: Moorish founding/era transitions, Cuban contact/source-culture changes,
and Māori opening/production/gifts/escort budgets. These remain historical passes
on their originally recorded binaries. Current Cuba and Māori Lua match the
reviewed later historical packages byte for byte. The Moorish era calculation
is unchanged; its newer acquisition/load hooks remain covered separately.
Earlier Māori stack/production cases predate later guards and keep that provenance;
final-candidate applicability/regression remains required at F. No new game was
launched or old failure reclassified for this reconciliation.

Seven specific event-handler surfaces are mapped to the combined native evidence,
including the ordinary Church-healing and Battalion influence cases. The review
record and archive/member comparisons are pinned in the register. Totals are
31 scoped cases (12passed,19covered by retained evidence),1,311 untriaged review
surfaces and121 pending document rows. G0 and final acceptance remain open.

## Independent merchant mission oracle prepared

`MISSION-MERCHANT-INDEPENDENT-REWARDS` closes a specific oracle gap: older utility
tests compared actual rewards against native quotes. The prepared case calculates
gold and friendship independently from the shipped values and native arithmetic,
then performs eight ordinary missions across both merchant types, Commerce
finisher off/on and two eras. It verifies additive modifiers, exact settlement,
consumption, location eligibility and one resulting-state replay without advancing
a turn. Supplied units/policy/research are separate from observed rewards.

Six assertions and one replay preflight successfully;29 batch tests pass. The
first launch attempt was refused by the locked-desktop guard before installation
or settings changes. The case stays ready, with no native pass claimed. Evidence:
`build/macos/merchant-rewards-native-20260927.log`. Gameplay-source/data mappings
cover five scalar fields; other speed/AI/purchase branches remain independent.

## Further source and historical evidence review

Three retained New Zealand process pairs pass the strict checker:16 declared
assertions (including two player-color checks) and three exact replays. They
cover native movement first contact, explicitly supplied subsequent engine
contacts, both owners, all four unforced reward draws, repeat/foreign controls,
selected research and technology-completion overflow. The TeamMeet dispatcher
and leader lookup are pinned with the Lua source; no new minor-contact settlement
or multi-member-team gameplay claim is made. The complete civilization remains
open in the wider inventory.

Six additional string/asset fields were classified as presentation metadata
after reviewing their loaders and consumers: era art prefix, victory/defeat
audio, bombard visual tag, abbreviation and the specialist great-person icon.
Their G7 presentation and final asset-integrity obligations remain open. This
classification does not establish that every asset rendered successfully.

The register contains33 specified cases:32 retained/passed and one ready merchant
case awaiting an unlocked desktop. There remain1,299 untriaged review surfaces
and121 document rows; the final case count is still not frozen.

## Batched Engineer arithmetic and receiver-aware preflight

The pending `great-person-rewards.json` plan combines the merchant checks with
an independent Engineer case:12 declared assertions and two exact replays in one
process, with zero ordinary turns. Four real hurry actions will cover supplied
populations1/5/12 and a production cap; no-city and one-turn targets are rejection
controls. The oracle follows the native truncation order for75+36×population
and the current speed percentage. Spaceship-part doubling/completion and other
speeds remain separate branches. This plan is prepared, not natively passed.

Direct binding review caught an Engineer harness error offline: `CanHurry` is
registered on City, not Unit. The corrected scenario uses Unit `CanStartMission`
with the native Hurry mission and integer visibility argument. Optional explicit
receiver annotations now check method registration on the actual declared class,
preventing the global-name union from accepting that mismatch. Both new scenarios
also enable the existing native-name/callback checks. Six receiver tests, four
callback-arity tests and29 batch tests pass. These checks are not general Lua
type inference or complete argument-signature validation.

The Mac remains locked for the requested native round. An independent audit at
23:17UTC confirms stock, original host/core/backups,35 original UI files,792 prior
single-player saves,672 recovered originals and98 newer save/settings files
unchanged; no game/launcher process. Evidence is in
`build/macos/locked-merchant-preservation-20260927.json`. The register now has34
specified cases (32passed/retained, two ready),1,297 untriaged review surfaces
and121 pending document rows. Final acceptance is still open.

## October2 resumption and longer-session workflow

The [independent Merchant/Engineer batch](macos-great-person-rewards-validation.md)
passed12 assertions/two exact replays. Its two speed-scaling fields are mapped
through the sole shared native consumer of each getter, with all five configured
percentages verified by the earlier native cache audit. Only Quick-speed mission
outcomes are newly claimed; no five-speed gameplay run is implied.

The user requested longer useful sessions. The prepared
`acceptance-lifetime-long.json` combines52 assertions/15replays under one process
and one install/restoration, retaining the existing26-total-turn and45-minute
limits. Eight new current-candidate cases are ready; the long run must complete
and preserve state before they are marked passed. Historical evidence remains
separately valid at its original scope.

A strict retrieval index verified117 historical standalone run/reload pairs and
119 stages from completed passing batches across649 inspected reports. It is
an aid to reconciliation, not an automatic coverage or candidate-applicability
claim. The reusable `index-native-evidence.py` now builds this index. Current-source
Tonga13, unit-owner66 and Venice8 isolated checks pass. An initial unit-owner
invocation used the wrong source directory and is retained separately.

`GameOptions.SupportsMultiplayer` is excluded solely as an explicitly deferred
network-multiplayer display filter. Standard single-player display filters and
the individual game-option effects remain open. Direct source review also found
a real coverage gap: Bomb Shelter modifies stationed-unit damage as well as city
population loss. Existing city assertions do not establish those unit outcomes;
the surface remains untriaged with a concrete next-batch design action.

There are42 specified cases and1,288 untriaged review surfaces;121 document rows
remain. This is still a review inventory, not a frozen test denominator.

The October2 [longer run](macos-long-session-validation.md) has now completed:
all52 checks and15 exact replays passed in788.3seconds, with one install/restore
and no inter-stage restart. It closes the eight ready cases and adds current-core
Moorish/Mughal old-save regressions. All42 currently specified cases have scoped
passes/retained evidence; G0 remains open at1,288 surfaces/121 document rows.

## Shelter consumer and spaceship-hurry closure

The [reward-boundary report](macos-reward-boundaries-validation.md) verifies20
native assertions/three exact replays across explicit successful stages/runs.
The original combined batch remains failed for a fixture-space error; the two
independent passing stages use strict isolated-stage contracts. Shelter combat
and civilian damage, nuclear-unit accounting, health99/lethal100 boundaries,
spaceship policy/doubling/cap/completion and current-candidate counterspy outcomes
are now covered. No product code changed. The current register has45 scoped
passes/retained cases,1,285 untriaged surfaces and121 pending document rows.

A compiled-AST retrieval study found143 generic one-dimensional cache loads,
139 with candidate indexed getters, including SetYields/SetFlavors wrappers.
This is not runtime parity or gameplay coverage. The next broader diagnostic
requires careful distinction between boolean membership, integer compact-ID
lists and indexed values, plus default/count/duplicate/nullable-getter review.
The existing utility's integer existence overload produces a compact ID list
with−1 padding; treating it as a boolean or ID-indexed mask would be wrong.
Candidate data is retained under `build/macos/config-array-audit-20261002/`.

## Broader cache preparation while the desktop is locked

The [132-array diagnostic](macos-array-cache-audit.md) is compiled, ABI-validated
and packaged from clean source, with tested bounds/type/default contracts and an
independent verifier. It plans1,075,256 comparisons across16 tables. Native launch
was refused before changing settings because the desktop is locked; the case
remains ready. Five conflicting AI-flavor arrays and orphan input rows remain
explicit review findings. No surface is closed merely from this preparation.
The register now contains46 cases:45 scoped passes/retained evidence and one ready
configuration case. G0 still has1,285 untriaged surfaces/121 document rows.

## Further offline handler reconciliation

Five retained process pairs verify17 native assertions and five exact replays
for Georgian promotion/lifetime behavior, Mughal conversion markers, Italian
human/AI branch rewards and Qasimi sea-route plunder. Seven event surfaces are
now mapped to those bounded cases. Georgia's incoming-gift/AI/dead-owner controls
remain isolated-handler evidence; Mughal capture/founding/aggregation and UAE
improvement-pillage/other abilities remain open. No new game was launched.

The current Georgia, Italy, UAE and shared civilization callback suites pass
13/10/4/16 isolated checks respectively. Italy/UAE Lua match their retained
packages byte for byte. The preserved Georgian creation package predates the
conversion hook; its handler body matches, while the later upgrade/gift native
contract remains separately pinned. No whole-file identity is inferred there.
Final-candidate applicability remains required at F.

The duplicate-flavor review now has a reproducible read-only tool. Exactly five
conflicting cells are present verbatim in the shipped XML. The source loader
uses the last returned row without ordering its query; reversing unordered
selection on the immutable snapshot changes all five winners. This confirms
source/data ambiguity, not author intent or the native host's selected values.
Original weights are unchanged and these arrays remain excluded pending native
query/cache evidence and explicit review. Source-concern evidence hashes are now
checked by the acceptance validator.

The register contains50 cases (49scoped passes/retained, one ready cache case),
1,278 untriaged surfaces and121 pending document rows. The Mac is still locked;
the ready68-check cache/reward batch remains unexecuted and stock is unchanged.

## Reward, route-lifetime and religion evidence reconciliation

Eight more historical cases have been incorporated with97 declared native
assertions and19 exact replay contracts. They cover Swiss birth/training/terrain
movement/upgrade/gift/purchase locking, Romanian conquest/gift/liberation roles,
Yugoslav adoption and all revolution destinations, Kilwan route creation/food
settlement/expiry/war/naval plunder, Palmyran founding/capture, Ottoman promotion
faith and minority-religion happiness refresh, and Phoenician Optics founding.
These are reverified retained results, not new native runs.

Sixteen event-handler surfaces are now tied to those cases and the already
verified Defender/Palmyra saved-state regressions. The sole configured Ottoman
`HappinessPerReligion=1` and Phoenician building `Gold=50` fields also have
source-consumer mappings with exact native amounts and parameter-cache support.
`LocalPopulationChange` is deliberately still open: its−1/+6 cases and associated
boundaries cannot be inferred from the two+1 founding rewards.

The evidence retains distinctions that affect acceptance: Swiss legacy-load
compatibility corrected zero stale flags; the separate authentic failure save
proved actual repair. Kilwan stale saves repair on an ordinary owner turn, not
immediately at load. The naval plunder failure was fixed and retested before
its successful contract is used. Supplied religion/XP/research/production inputs
are not relabeled as naturally earned gameplay. No additional long campaign
was run, and no new mouse interaction is claimed.

There are58 specified cases (57scoped passes/retained, one ready array audit),
1,260 untriaged surfaces and121 document rows. The ready native batch remains
blocked by the locked-desktop guard; no game or settings change was started.
The acceptance goal remains active because meaningful offline reconciliation
work remains. Full G0, final-candidate applicability and F/R gates are unfinished.

## Opening, exploration and quota reconciliation

Eight retained cases add28 declared native assertions and10 exact replay
contracts: Mexican initial minor discovery, Pottery Worker grants, Ranchero
growth during production, Hacienda resource-class yields, tribute influence;
foreign-owned Zabonah discovery/removal; Minaa damage; and Philippine city-loss
quota persistence. Five corresponding Lua surfaces have cases assigned, with
Philippine positive founding explicitly still ready. The sole Mexican600
afraid-minor coefficient maps to met/eligible750-hundredth native rate, removal
after tribute and the unmet-eligible zero control. Whole-point friendship views
are not relabeled as exact fractional balances.

Review identified a specific missing replay: `20260918T090810Z` passed the
Philippine capital/first-two/third/foreign founding assertions, but no matching
standalone exact replay was found. Loading that save for a different scenario
is insufficient. `LIFE-PHILIPPINES-POSITIVE-QUOTA` is therefore ready, not passed,
and joins the cache/reward plan using the original initial fixture and unchanged
assertions. The planned session now has72 assertions/seven replays and a six-turn
aggregate cap. The separate real city-loss/reload case remains accepted at its
recorded scope.

Nabatea's handler mapping includes real human/AI foreign owners, major/minor
capital discovery, repeat rejection and normal disband without the prior off-map
Lua error. No autonomous exploration claim follows. Minaa's supplied embarked
Worker is a damage target, not evidence of an embark transition. All preserved
failures and later source applicability obligations remain separate.

The register now has67 cases:65 scoped passes/retained and two ready cases.
There remain1,254 untriaged surfaces and121 document rows; G0 is still open.
No live installation or native run occurred during this locked-desktop review.

## Consulates ownership reproducer

Source review found two concerns in the unchanged Consulates policy Lua: the
first adoption removes the shared adoption listener, and the era callback treats
a team ID as a player ID. The native `CvTeam::setCurrentEra` hook supplies a team
ID. Executing the actual unchanged Lua with that contract produces five failures
in ten isolated cases, including reversed adoption order and unrelated/shared
teams. These are source-level reproductions, not native gameplay confirmation.
The raw output is retained in
`build/macos/consulates-source-reproducer-20261002.log`.

`POL-CONSULATES-OWNER-ADOPTION` adds two native single-player orderings to the
combined cache/reward plan. Each supplies research, prerequisites and one free
policy choice, then uses the normal human command or actual AI owner turn to
adopt Consulates. Each Industrial adoption should grant two policy delegates
(native base one plus era one); subsequent Modern research should add one.
Failed counters are recorded without assigning a replacement result, allowing
authentic affected saves to be retained. Team-ID mismatch currently has only
isolated coverage. Product code remains unchanged pending native confirmation.

The combined plan now declares82 assertions/nine exact replays, a12-turn
aggregate cap and40-minute ceiling. The register contains68 cases:25 passed,
40 covered by retained evidence and three ready. There remain1,252 untriaged
surfaces and121 pending document rows. These are review counts, not an overall
completion percentage; G0 and final F/R acceptance remain open.

## Inactive adjacency scaffold review

The two listeners in `Lekmod_improvements.lua` are excluded only as inactive
scaffolding: the exact `Improvement_Adjacency_Yields` table has no shipped schema
or native database entry, and its guard returns before applying effects. The
differently named, populated native adjacency tables remain in scope. Existing
warning logs are preserved. This source/database review leaves1,250 untriaged
surfaces; it does not establish any new native gameplay pass.
