# Longer single-player batch tests

The batch runner keeps one Civ V process open for a sequence of independent
functional scenarios. It saves each result, verifies the save file on disk,
loads that checkpoint through the normal engine load event, compares the exact
scenario snapshot, then loads the next known fixture. Each stage keeps its own
assertions, input labels, observations, callback subscriptions and turn limit.

The comprehensive plan contains **16 scenarios, 81 functional assertions and
16 checkpoint reload comparisons**, with a **60-minute default wall-clock limit**
and **28 total permitted functional turns** across independent saved fixtures.
It finishes early when the work is complete; no idle time or repeated long
campaign is added to consume the budget. These are intended checks, not a claim
that the entire new batch has already passed.

## Run it on this Mac

Preflight requires no game launch or installation changes:

```sh
cd /Users/duffy/Documents/GitHub/Lekmod
python3 LEKMOD_DLL/macos/batch-playtest.py --preflight-only
```

With a tested Lekmod package already installed:

```sh
python3 LEKMOD_DLL/macos/batch-playtest.py --plan comprehensive --minutes 60
```

From stock, the optional managed-package mode installs this preserved candidate
and restores stock in its cleanup. The identified intermediate package contains the verified Defender correction
and optional-control reload guard:

```sh
python3 LEKMOD_DLL/macos/batch-playtest.py \
  --plan comprehensive --minutes 60 \
  --package build/macos/Lekmod-optional-control-20260920.zip \
  --sha256 f054823b392cd282e7635a475e65b91fe3240b35f29cdfa8e0d3adfe224bd21e
```

Steam must already be signed in, Civ V must be closed and the local desktop must
be unlocked at launch. Standard UI is required. The runner does not start Steam,
alter its channel, enable schedules, unlock the desktop or restart Docker.
All multiplayer modes remain excluded. Foreground input is not used by this suite.

For a shorter commissioning run, use `--plan pilot --minutes 15`. To resume an
independent portion after fixing a defect, use e.g. `--from-stage internal-trade`.
A custom reviewed plan JSON can be passed instead of a profile name. Every input
save is checked against its recorded SHA-256 before launch and again before a
transition. The saves and candidate package are local ignored artifacts from the
handoff; a clone alone does not contain them. Missing or altered fixtures fail
preflight before touching the game.

## Coverage in the comprehensive plan

| Stage | Assertions / outcome scope | Maximum ordinary turns |
| --- | --- | ---: |
| Defender | Owned/friendship city distances 2 and 3, far/ordinary ship controls | 2 |
| Great Admiral | Fleet/embarked healing, owner/domain/radius exclusions, consumption | 0 |
| Worker | Farm and road construction, pillaged-farm repair, build restrictions | 9 |
| Unit actions | Promotion, paid upgrade, retained XP, healing, embark/disembark, restrictions | 7 |
| Great-person builds | Academy, Manufactory, Customs House, Holy Site and Citadel | 0 |
| Unit utility | Disband/cancel, gift, merchant/scientist/engineer actions and restrictions | 0 |
| City lifecycle | Founding, purchase/sale/cancel, growth and starvation | 4 |
| Budget | Treasury/science floors and ordinary recovery settlement | 3 |
| Internal trade | Rebase/cancel, land food, sea production and route restrictions | 1 |
| Great Works | Creation, movement, cross-city swaps and theming | 0 |
| Air | Interception, sweep, carrier rebasing/capacity/movement | 0 |
| Nuclear | Range, blast radius, immunity, fallout/pillage and missile consumption | 0 |
| Religion | Selected belief yields, purchases and owner/resource boundaries | 0 |
| Nabataean farms | Mathematics/Civil Service cache transitions and Roman/dry controls | 0 |
| Rock-Cut Tomb | Construction, yields/resources, contribution queries and actual land route | 1 |
| Battalion | Human/AI turn influence, negative controls and foreign owners | 1 |

Setup mutations remain explicit inputs. Scripted normal commands, native outcomes,
and read-only native queries retain their existing evidence distinctions. This
suite does not establish physical mouse interaction, all civilizations, all
victory branches, multiplayer, other Macs or complete startup/shutdown reliability.

## Failure handling and evidence

A scenario failure remains failed even if later assertions pass. The runner
preserves its checkpoint and proceeds only to the next independent, hash-verified
fixture; it does not continue a dependent operation in a partially modified world.
Failed scenarios do not receive a successful reload verdict. Missing required
assertions and skipped assertions cannot produce a stage pass.

Protocol errors, RNG synchronization failures, native crashes, unhandled runtime
errors, save/protocol failures and time limits abort the batch. No synchronization
or GameCore wait flag is changed. Turn-discontinuity checks apply within each
explicit load interval; an authorized fixture reload starts a new interval and
is recorded, rather than being mistaken for rollback during gameplay.

Each evidence directory contains `batch-plan.json`, `batch-report.json`, the
normal `report.json`, `batch-lua.log`, retained injected scripts, and uniquely named
saves under `checkpoints/`. The batch report includes each stage's verdict,
assertions, elapsed time/turns, snapshot and save hash; supplied-state observations
are retained in `batch-lua.log`. Check the final `report.json` for process exit,
synchronization and cleanup results before treating a completed batch as passed.
The source hashes and plan identify exactly which adapters ran. Temporary UI and
civilization observers, settings and original manual saves remain covered by the
existing runner's restoration checks.

## Commissioning evidence

Offline tests currently cover 15 supervisor/plan cases, 18 actual Lua dispatcher
cases and 33 existing/extended runner cases. The suite tests immutable fixture
hashes, required save acknowledgements, sticky failures, callback cleanup,
independent continuation, exact snapshot mismatches, turn limits, load-interval
bookkeeping, unsupported multiplayer and UTF-8/escape preservation.

Native pilot `20260920T192821Z` demonstrated two fixture stages and normal shutdown
in one process, but both scenario setups failed because Civ V omits `setfenv`.
The dispatcher was changed to lexical function scopes. This run remains FAIL.
Pilot `20260920T193122Z` then passed all five native Defender assertions and saved
its checkpoint (SHA-256
`32af318b02eb672a23999df8c69eecd7e2996c228b194cbd81a5fa79b73dd0ea`), but the Python
supervisor failed while reporting zero completed turns at a load boundary.
That bookkeeping defect has a dedicated regression and is corrected. This second
pilot is also incomplete/failed, not a full batch pass. Its native process was
terminated by cleanup; no normal exit is claimed.

The next pilot launch was blocked before launch because the desktop was locked.
Final pilot and full comprehensive execution must still be recorded. No new
scheduled task was created.

## Completed resumed pilot

`20260920T224820Z` completed both scenarios and their exact checkpoint reloads
in one native process (PID 45746), in 107.5 seconds. Nine functional assertions
and two reload comparisons passed. The Defender stage used one ordinary turn;
the Admiral stage used none. Normal exit (0), original settings/UI-hook/manual-save
preservation, and no Lua/synchronization errors or new diagnostics were verified.
The managed launcher restored stock successfully. Checkpoints and their hashes
are recorded in that run's `batch-report.json`. This commissions the two-stage
pilot; the full comprehensive run is being recorded separately.

## Full-plan commissioning corrections

The first comprehensive attempt, `20260920T225052Z` (PID 45975), preserved seven
passing scenario/reload pairs before encountering batch-specific adapter gaps.
City lifecycle and internal trade executed their cancellation checks, but those
UI contexts printed verdicts directly rather than adding them to the stage ledger;
the required stage assertions correctly remained failed. Great Works then stalled
because its popup-closing adapter was missing from the batch map. The stall guard
terminated the owned game; overall status remains `failed-stall`, native -9.
Settings/hooks/manual saves were preserved, with no synchronization errors,
Lua runtime errors or new diagnostics. The wrapper restored stock.

Batch-specific UI adapters now forward their existing assertion prints through a
scoped Lua event, retaining the original print and standalone behavior. Inactive
completed stages ignore late reports; failures remain sticky. Great Works now
includes its required popup adapter. Preflight checks that each test-only Lua
response event subscribed to by a stage has a producer in its supplied adapters
or source, catching this missing dependency before launch.

New regressions cover external-UI assertion routing, failure retention, stale-run
filtering and missing response adapters. The follow-up plan contains only the
two failed and seven unfinished stages, using the original hashed fixtures;
completed independent cases are not silently rerun or relabeled. Its results
are recorded separately from the failed comprehensive attempt.

## Latest full-plan and targeted results

`20260920T231930Z` ran all 16 stages in one process (PID 47872) in 783.8 seconds
with package `f054823b…bd21e`. Fifteen stages, containing 77 planned functional
checks, and all fifteen corresponding exact reloads passed. The process exited
normally (0), and settings, temporary hooks and manual saves were preserved.
There were no Lua runtime errors, synchronization failures or new diagnostics.
The optional shared-options UI guard is documented in
[its validation report](macos-optional-options-control.md).

The overall full-run verdict remains FAIL because Battalion's test-only before
observer was registered after the gameplay handler when loaded dynamically.
Its one-turn limit correctly prevented extending the test to hide that ordering
problem. The harness now prepends a before signal ahead of the actual product
registrations and appends the existing after signal. Stage observers subscribe
to those signals; they never call the product handler themselves. A regression
executes the real prefix/suffix observers with late stage registration and checks
both their order and removal of stage listeners.

Targeted batch `20260920T233452Z` (PID 49644) passed Battalion's four functional
checks and exact reload in 83.2 seconds, with one ordinary turn. Normal exit (0),
settings/hooks/manual-save preservation and no Lua/sync errors or diagnostics
were verified. The managed wrapper restored stock after both attempts.

All **81 planned functional checks and 16 reload comparisons now have passing
evidence** on the same product package, using the full run plus this targeted
harness retest. This is not described as one untouched all-green 16-stage run:
the full report retains its failed Battalion verdict, and the targeted result is
separate. No passed reports or snapshots were rewritten.

Current offline batch coverage is 15 supervisor cases, 18 dispatcher cases and
33 runner cases. The separate optional-control product regression has 64 cases,
and all nine UI assembly checks pass. The original single-player completion
ledger still has broader civilization and system gaps.


## Clean-source full-plan pass (2026-09-21 UTC)

`20260921T002839Z` passed all **16 stages / 81 functional checks / 16 exact
reload comparisons** in one process, in 813.7 seconds with 23 ordinary functional
turns. All 32 checkpoint files match their recorded hashes. Normal exit (0),
settings/hooks/manual-save preservation, and no Lua/synchronization errors or
new diagnostics were verified. The managed wrapper restored stock.

The package was built from clean commit `f40fd2b2`; its archive SHA-256 is
`e6904b434b3a3a7bebea4c2a83d1709c3aaf73d55a096237b6ed87f07fefcffc`.
See [release qualification](macos-release-qualification.md) for full provenance,
commands and preservation checks. Earlier failed runs retain their verdicts.
The supervisor now has 17 offline cases, including direct and terminal-group
interrupt cleanup. This run adds scripted/native coverage, not physical input.
Startup/shutdown reliability and the broader single-player ledger remain open.


## Progress inside long zero-turn stages

The first long unit-catalogue run (`20260922T211144Z`) reached the 115th of 125
units before the 240-second stage guard expired. The supervisor recognized only
turns and stage/checkpoint transitions as progress. A later screenshot/sample in
`20260922T212042Z` also identified a real blocking texture-load dialog at the same
Tunisian Privateer: `tunis_xebec_flag_32.dds` is absent. The earlier failure must
not be attributed solely to the timer. Both failed/interrupted reports are
retained, with settings/hooks/manual-save restoration verified. The progress
correction remains necessary for a valid 125-unit stage lasting over 240 seconds;
it does not dismiss the native dialog or manufacture completion.

The supervisor now counts each newly passed assertion for the active run/stage
once. Long catalogue stages emit a per-unit PASS only after the real native
creation or removal event and the asserted state/treasury result. Repeated
assertions, other runs/stages, FAIL messages and ordinary observation messages
do not reset the stall timer. Two regressions verify these boundaries and that
partial progress cannot complete a stage or supply a checkpoint. All 19 supervisor
and 33 runner tests pass. Existing synchronization, wall-clock, turn and final
checkpoint rules are unchanged. Native retest results are recorded separately.


The fixed-asset unit catalogue `20260922T213414Z` then completed all125 per-unit
checks, aggregate checks and exact reload in335.8seconds; normal disband of the
saved125-unit catalogue and exact reload completed in530.1seconds
(`20260922T214053Z`). Both exited normally with full restoration/preservation and
no Lua/synchronization errors or new diagnostics. This commissions the
completed-check progress path beyond the240-second stall interval. See
[the catalogue report](macos-unit-catalogue.md) for the actual missing-texture
fix, retained failures, exact hashes and limits.
