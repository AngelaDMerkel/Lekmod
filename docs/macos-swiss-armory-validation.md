# Swiss Armory: training-boundary fix and validation

**Resumed September 26 UTC. Fix `149e6328` passed the native reproducer and
exact reload.** Movement, conversion and further owner boundaries remain
separately scoped below.

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

## Preserved baseline evidence

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

The focused refresh and fixed-package retest are recorded below. The baseline
package and failed run remain unchanged. Conversion/load behavior requires its
own evidence; no wait flags or spent movement may be reset to obtain a pass.

Independent pause verification is
`build/macos/swiss-armory-pause-20260926.json`: stock active, Civ V closed,
all prior manual saves and the original quicksave unchanged, settings restored,
32 stock UI hashes and both canonical/Aspyr backups intact. No push was made.

## Focused fix and native retest

`149e632836936a42b2ad1ba913055613b06b298e` refreshes Mountaineer after
CityTrained and UnitConverted, with a one-time loaded-state reconciliation for
living civilization owners. Missing players/units/off-map plots are ignored.
A fresh creation or training event retains a full unused movement allowance when
the terrain promotion increases its maximum. Movement, conversion, loading,
partially spent allowances and zero-move purchases receive no refund. Event
wrappers keep coordinate arguments from being mistaken for a fresh-unit flag.

The Lua callback suite has 66 cases: eight failed before the change, all pass
afterward. These are scripted callbacks, not native gameplay evidence. Logs:
`build/macos/swiss-armory-offline-{red,green}-20260926.log`.

Clean source package: `build/macos/Lekmod-swiss-armory-20260926.zip`, archive
SHA-256 `6786af0ce4f8fac3aa01fbebcd547ef4b88d84792077549a55ecbf028c05dc5e`.
Core remains `2dcc90942588da45f5c8c04d38aec131a33e3a07333075fdb03df63054c8abc1`;
payload is `24df890045e8d393bfdd090e2edc2d949c739c9b6b281b93f00a9db601a2d564`.

`20260926T163747Z` failed before gameplay with startup255, 22.5 seconds. No Swiss
check ran. Its cache and metadata-call trace are preserved; stock/settings/UI
restoration passed. This remains a separate failed startup, not a gameplay pass.

Independent traced run **`20260926T163851Z` passed seven assertions and one exact
reload**, 134.5 seconds, four ordinary fixture turns, normal exit0. The native
free Reislaufer began at240/240 movement. The mountain-adjacent trained Swiss
Longswordsman had the active promotion and180/180 movement; the Spanish standard
Armory control stayed unpromoted at120/120. No Lua/synchronization errors or new
diagnostic appeared; settings/UI/manual saves were restored. No physical mouse
interaction is claimed. The same-process reload matched the full recorded state.

The run checkpoint is
`build/macos/playtests/20260926T163851Z/checkpoints/Lekmod-Batch-20260926T163851Z-swiss-armory-run.Civ5Save`,
SHA-256 `0c1b203169faea211a1b27534b73657d994a2a219e11e66a2977842d1d120dcd`.
Report SHA-256 `bf3a69511e3e41430db60d8168f9effaaefb2054530ed4de7dd0174460f8bb74`.
Both run/reload copies were independently compared to completed original saves.
Evidence: `build/macos/swiss-armory-fix-validation-20260926.json`.

This establishes stationary training and native birth movement on the fixed
payload. It does not by itself establish upgrade/gift movement restrictions,
repair of an affected old save, or every owner/terrain combination.

## Movement, upgrade and gifting boundaries

`20260926T164435Z` passed six assertions and exact reload in93.9 seconds,
normal exit0 with full runner restoration. The fixture supplies a Spanish-owned
Reislaufer, natural terrain boundary, research/gold and positions. It does not
assign promotions or movement. Normal synchronized movement left mountain range
(240→180 current movement, maximum180) and returned (180→120 current movement,
maximum240), demonstrating no movement refund. A normal305-gold Rifleman upgrade
retained Mountaineer, derived the correct out-of-range state and left zero moves.
A normal gift transferred that unit to owner9, preserving Mountaineer and zero
moves. The whole recorded state replayed exactly. A requested driver turn did
not advance the round; the run used zero ordinary turns. No physical clicks or
recipient-turn refresh are claimed.

Earlier `20260926T164218Z` passed the three movement observations, then failed
because the harness unnecessarily required flat/featureless owned land for
upgrade staging. The unchanged product passed after relaxing that staging
selector to eligible empty owned land. That earlier run remains failed. The
combined test is `playtest-scenario-swiss-boundaries.lua` and its matching plan.
Native purchase locking and affected-save repair remain separately scoped.

## Human purchase and old-save compatibility

`20260926T164936Z` passed nine assertions, two functional exact replays and the
Swiss fixture baseline replay in167.6 seconds (one ordinary turn), normal exit0.
The purchase and old-save scenarios run in one process.
The human Swiss fixture was normally initialized in `20260926T164719Z` (roster
Swiss/Spain; matrix `build/macos/civilization-matrices/20260926T164713Z`).
The purchase test supplies a legal mountain city, Barracks, Steel/iron, nearly
complete Armory hammers and gold. Ordinary Armory production generates its free
Reislaufer. The exact quoted Longswordsman budget is tested against cost-minus-one,
then the real ProductionPopup callback purchases it with the exact debit. Native
CityTrained grants active Mountaineer and maximum180 movement while preserving
zero current movement. No player event is called manually.

The preserved original failed Armory checkpoint is also loaded read-only.
The AI's old Longswordsman has moved outside mountain range by save time, so
**zero derived flags require correction** in this checkpoint. Current moves
remain120/240 for the trained/reward units, and the Spanish control stays
unpromoted. This establishes old-package save compatibility and no movement
refund, not repair of a stale promotion in an affected save. Native affected-save
repair was a separate gap at this point; the next section closes it. No Lua/synchronization errors or new diagnostic appeared. Source/copy save hashes
and each exact replay were independently checked after the process closed.
Report SHA-256 `cc623e507e4895db442d5b6df6c938422dde6ccd9b10cf4369b17d28e1439f58`.

Independent final preservation verifies stock/no running Civ V,603 prior manual
saves, original quicksave, settings,32 stock UI files and both original backups.
Evidence `build/macos/swiss-armory-fix-validation-20260926.json`, SHA-256
`dcadb453a38ac58fbfa597a17d3ee923f3ea1554ad7c41eb5eafd7380b94f204`.
The complete follow-up totals22 native assertions/four functional exact replays,
plus the new fixture baseline replay. The25-test batch dispatcher suite passes.
All interactions here are scripted callbacks/native commands, not physical mouse
coverage. No startup reliability fix or full single-player completion is claimed.

## Authentic affected-save repair and human training

The work continued on local `main` after the requested fast-forward through
`84010750`. On the unchanged old package, `20260926T165522Z` reproduced the same
training defect in a human Swiss city. Ordinary Armory/Longswordsman production
left unit40963 at(73,9) beside a mountain with base=true, active=false and120/120
movement. The failed run exited normally and preserved that stationary state:
`build/macos/playtests/20260926T165522Z/checkpoints/Lekmod-Batch-20260926T165522Z-swiss-human-training-run.Civ5Save`,
SHA-256 `a3d06b887e714071e1ce2e3b64890c56a7b16e76a37ced91b0d0ce04fefc404d`.
No stale promotion was manually supplied; it came from real production under the
old payload. The run remains failed, not a claimed success.

Fixed-package **`20260926T165800Z` passed eight checks and two exact replays**,
151.2 seconds, two ordinary fixture turns, normal exit0. Fresh human training
had active Mountaineer and180/180 moves. Loading the exact old failure save
repaired its missing active promotion and maximum180 while retaining120 current
moves. The off-mountain Reislaufer control retained180/180 and no active bonus.
A normal synchronized move spent the repaired unit's saved movement; its resulting
state replayed exactly. No turns/state/promotions were supplied by the migration
scenario. This closes the previously separate native affected-save repair gap.

Evidence: `build/macos/swiss-migration-validation-20260926.json`. Both original
and copied saves were independently compared. Runner restoration, original603
manual saves/quicksave/settings/backups,32 stock UI hashes and stock/no-live-game
were verified. The full Swiss follow-up now has30 native assertions and six
functional exact replays, plus one fixture baseline replay. It remains scoped to
these abilities and state boundaries, with no new physical-mouse claim.
