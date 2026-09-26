# Swiss Armory: confirmed training-boundary defect

**Paused at the user's request on September 26 UTC. The product fix has not
been made.** The reproducing test has finished and stock is restored.

The 125-unit catalogue covers non-default civilization unit-class replacements.
`UNIT_SWISS_REISLAUFER` has its own default class, so it is a separate acquisition
path: the Swiss Armory (`BUILDING_SWISS_REISLAUFER`) grants one through
`Building_FreeUnits`. The building also grants Mountaineer to trained land units.
This additional path is not included in the 125 replacement-type count.

## Native reproduction

`20260926T043437Z` used the unchanged clean `f33cfd33` package (archive SHA-256
`9005a104f665ea4c5336c9ed8a85f31abdad782e33b277864a923ece3de09b01`).
The test supplied research, two legal cities beside natural mountains,
prerequisite Barracks, iron and near-complete hammers. Spain was the human
standard-Armory control; Switzerland was AI owner3. Actual unforced owner queues
produced both buildings, then Longswordsmen. AI observations were taken at the
ordinary owner-turn callback after city production bookkeeping.

Four checks passed before the confirmed failure:

- The unique Armory was eligible for Switzerland and rejected for Spain.
- Both buildings completed ordinary production.
- The Swiss building generated exactly one Reislaufer through native UnitCreated;
  the standard Armory generated none. No target unit was supplied.
- The trained Swiss Longswordsman received Mountaineer; the Spanish control did not.

The Swiss trained unit was still beside a mountain at observation but lacked the
active promotion: `base=true`, `near=true`, `active=false`, current/max moves
`120/120`, owner3/unit32770 at (76,11). The Spanish control had no Mountaineer or
active bonus at its mountain city, as expected. The final terrain-at-training
assertion failed; this is not a passed scenario or replay.

Source order explains the failure. `CvCity::CreateUnit` calls `initUnit`, which
emits UnitCreated, then calls `addProductionExperience`, which grants the city's
promotion. `Lekmod_switzerland.lua` only refreshes terrain state on UnitCreated
and UnitSetXY, so the newly granted promotion is not refreshed while stationary.
The intended active promotion adds one movement and 15% combat.

The free Reislaufer also showed a birth-time movement discrepancy: active bonus
true and maximum240, but current180. Check that boundary when designing the fix;
do not grant movement indiscriminately on movement, conversion or loading.
The reward was subsequently staged remotely as an explicit input to keep the
controlled training city clear. That staging is not travel coverage.

## Preserved evidence and next step

The run remains `failed-functional-checks`, 114.1 seconds, normal exit0, no Lua
runtime/synchronization errors or new crash diagnostic. Settings/UI/manual-save
restoration passed. Reproducer plan:
`LEKMOD_DLL/macos/batch-plans/swiss-armory.json` (six-turn cap).

Report: `build/macos/playtests/20260926T043437Z/report.json`, SHA-256
`f12bd720be26b985ba125ac7f5f39dac2a6577489aa046b194c388aa3a25a257`.
Saved checkpoint:
`build/macos/playtests/20260926T043437Z/checkpoints/Lekmod-Batch-20260926T043437Z-swiss-armory-run.Civ5Save`,
SHA-256 `1cc54bc04a358eb18bf4512a54ca0f514da24dde65ef17482d5ac4d6e6cfcfc2`.
Its bytes match the completed original save. The AI had moved the trained unit
by checkpoint time, so verify its saved terrain before treating that checkpoint
as an affected-save migration case. The native observation above is the direct
stationary training reproduction.

Resume with a focused refresh after CityTrained and tests for existing behavior.
Review conversion/load refresh and birth-time movement carefully, using the
established ownership/event signatures. Do not change wait flags or refund spent
movement to satisfy an assertion. A new Lua payload must be packaged and tested
through the central installer; the current package is the failing baseline.

Independent pause verification is
`build/macos/swiss-armory-pause-20260926.json`: stock active, Civ V closed,
all prior manual saves and the original quicksave unchanged, settings restored,
32 stock UI hashes and both canonical/Aspyr backups intact. No push was made.
