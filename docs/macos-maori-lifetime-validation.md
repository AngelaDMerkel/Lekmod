# Maori unit lifetime continuation

The specified upgrade, civilian capture, naval and embarkation branches now have
**25 passing native assertions and five exact resulting-state replays** on the
Mughal-fixed candidate (archive `79239c0e…e53ec`, core `4756df05…d8659`).
The case register contains full hashes. No Maori product change was needed.
An intact all-stage pass is not claimed: the successful stages are identified
separately from the retained failed commissioning runs.

## Inputs and native outcomes

All stages start independently from the preserved turn-six human-Maori / AI-Maori
/ AI-Rome save `20260919T024720Z`, SHA-256
`f5a0999b7528ceb9a5c1ea49d539153d4e699771d4f45ce58e11af9afefbb444`.
Its baseline state replay also passed. Supplied inputs include units, legal
positions, prerequisites, exact upgrade budgets/upkeep, and war/contact. No
promotion, movement, birth timestamp or captured-unit outcome is assigned.

| Passing stage | Evidence | Result |
| --- | --- | --- |
| Two paid upgrades | `20260927T193159Z`, `maori-upgrade` | Cost-minus-one rejection and exact payment; fresh upgrade preserves birth turn/bonus but has zero moves. Next owner turn expires the bonus. A later upgrade preserves the older birth and does not renew bonus or moves. |
| Naval movement | same run, `maori-naval` | Trireme birth has six moves/sight3; a normal clear-coast step costs60 points. Next owner turn restores ordinary four moves/sight2; Roman naval control and further turn remain ordinary. |
| Capture into Maori | same run, `maori-capture-in` | Actual human capture removes the older Roman worker and creates a Maori worker at the capture turn with its recipient bonus and zero moves. Both subsequent owner turns have ordinary allowance. |
| Capture out of Maori | same run, `maori-capture-out` | Actual Roman AI-turn capture removes the fresh Maori worker and creates a Roman worker at the capture turn, without inheriting Maori bonuses, at zero moves. Later recipient turns remain ordinary. |
| Embark/disembark | `20260927T195115Z`, `maori-embark` | Normal embark, domain accounting and owner-turn expiry, followed by normal disembark and another ordinary turn. Exact resulting-state replay passes. |

These are scripted commands, callbacks and native outcomes, not physical mouse
coverage or autonomous AI strategic choices. Older gift and escort/donor tests
remain separate evidence in [the earlier Maori report](macos-maori-validation.md).

## Oracle and binding corrections

- `20260927T191558Z`: upgrade/naval stage pairs and baseline passed. The embark
  precondition used the wrong general movement predicate. The capture observer
  also mistook UnitCreated's coordinates for a type. An unsupported first operator
  exit request caused an additional harness setup failure; the corrected failed
  finish used the original exit callback. This run remains failed-early-exit, with
  process0 and restoration but no normal-exit verification; it is not reused to
  close the case.
- `20260927T193159Z`: four stage pairs/baseline passed, but the embark oracle omitted
  Optics' extra movement point. The run remains failed-functional-checks, with
  verified normal exit0, no Lua/sync/crash errors and full restoration.
- `20260927T194438Z`: embark and actual owner expiry passed; the disembark predicate
  used the wrong Lua signature. CanEmbarkOnto takes two plots; CanDisembarkOnto takes
  a target plot and optional destination boolean. The failed verdict remains.
- `20260927T195115Z`: all five embark-stage assertions and exact replay pass after
  using the actual binding and shipped data. Normal exit0/restoration pass.

The oracle now includes known technology and active promotion contributions.
Base embarked movement1 plus Optics1 gives2; minimum embarked sight1 plus the
Maori promotion1 gives2, falling to1 when that promotion expires. Land sight is
separate. `build/macos/maori-lifetime-20260927/oracle-review.json` pins the source,
resolved values and enabled preprocessor branch.

The native-method preflight also checks the fixed UnitCreated callback arity
against its current C++ source (owner,id,x,y). Four regression checks pass. This
still does not claim general receiver, signature or argument-type verification.

## Isolated evidence and dependency proof

A `native-isolated-stage` contract may retain a completed stage from a fully
resolved batch whose only failures are explicitly reviewed unrelated harness
oracle errors. It still requires verified normal exit0, settings/UI/manual-save
preservation, no Lua/synchronization/crash diagnostics, matching assertions in
both raw reports, exact run/reload fingerprints, closed-writer/source-copy checks
and unchanged checkpoint hashes. Selected, unreviewed, global and incomplete
failures are rejected. The overall batch verdict remains failed. The acceptance
checker has27 passing tests, including these refusal cases and dependency proof.
This does not relax the final requirement that every required case must close.

The read-only observer in the actual prophetreplace context verifies that the
first PlotIterators include supplies PlotAreaSweepIterator, later context code
still exists, and a six-neighbor iteration matches direct native neighbors.
This resolves the redundant missing standalone include reference. It does not
execute the dormant resource-placement function or claim its gameplay coverage.

`build/macos/maori-lifetime-preservation-20260927.json` independently verifies all
672 recovered saves,95 newer saves/current three settings, all736 single-player
files present before the final run,32 stock UI files and original host/core/backups.
Counts overlap. Stock is active, Civ V closed, nothing pushed. Full acceptance and
G0 mapping remain open; the next native group is Moorish acquisition/production.
