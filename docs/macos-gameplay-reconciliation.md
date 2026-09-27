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
