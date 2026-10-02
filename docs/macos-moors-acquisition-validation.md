# Moorish acquisition and saved-city repair

`20260927T201419Z` passed30 native assertions and six exact replays in one424-second
process, across16 ordinary turns. It verifies the acquisition/load repair
`e8a3fabd` for Medieval capture, Renaissance gift, both foreign-owner controls,
actual Market production, and two authentic affected saves. No mouse or autonomous
AI-choice evidence is claimed from these scripted actions.

## Defect and correction

`20260927T195635Z` reproduced zero markers/0% production immediately after a real
Medieval conquest (expected2/30%) and a real Renaissance gift (expected1/15%).
The shipped trait text promises the bonus in all cities. The handler previously
updated founding, era changes and owner turns, but missed acquisition. Both
foreign-recipient paths correctly removed the benefit and completed ordinary
production; the overall run remains failed.

The repair calls the existing era update for the current owner at
CityCaptureComplete. A load callback rebuilds the derived era marker for living
Moorish majors, covering old saves with a stale zero. It assigns the count rather
than adding it, and never grants production or replays capture rewards. Native
NeverCapture behavior removes the old marker on transfer to a foreign owner.
All22 actual-Lua handler checks pass; eight new cases failed before the repair.

## Candidate and native regression

Clean source `ae85ca7e654369d8e569c703641ee94077ad90cc` produced
`build/macos/Lekmod-moors-acquisition-20260927.zip`, SHA-256
`62d71ca82c8cb21d96198a23df3e3e1e931d2f09976675d3d64117f37421d53e`.
The signed/ABI-validated core remains
`c8afcadc49da838b3243edd401b6f37ada3bf63b600df6af2e666788c6bf7452`.
A byte comparison with the Mughal package finds exactly one changed payload member:
`Lua/Civilizations/Lekmod_moors.lua`. WSDLC remains `950a329`/v1.0.10.

`batch-plans/moors-acquisition-regression.json` pins all inputs. Secondary cities,
Renaissance prerequisites, war/contact, GDR/uranium/upkeep and near-complete Market
hammers are supplied. Gift/propose/AI-reply callbacks, active-AI-turn combat,
normal resistance expiry/annex tasks, production completion and subsequent owner
turns are actual native outcomes. The tests quantify30/15/0 production modifiers
and wonder exclusion; they do not claim earned city-development pacing.

The two original failed checkpoints reload with only the declared era marker and
production-modifier corrections. Recorded city identities, disposition,
resistance, other-owner state and production progress match exactly before any
scenario action. Subsequent owner turns and exact replays remain idempotent.
The snapshot does not include every other field in the save, so no broader
byte-identical in-memory migration claim is made.

The successful run exited normally0, restored hooks/settings and preserved manual
saves, with no reported Lua/synchronization error or new crash diagnostic.
`build/macos/moors-preservation-20260927.json` independently verifies all recovered
and newer saves/settings,744 pre-existing single-player files,32 stock UI files
and original host/core/canonical/Aspyr backups. Stock is active; Civ V is closed.
Nothing was pushed. G0 and final F/R acceptance remain open.
