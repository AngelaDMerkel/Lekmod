# Polynesian ocean access after conversion and load

## Native paid-upgrade defect

The preserved fixture is a normal Medieval/Small/Archipelago single-player start
with human Polynesia 0, AI Polynesia 1 and Roman AI 2, with Always Peace and no
barbarians explicitly supplied as setup options. The human starting Settler uses
normal Found. Other coastal homes, Compass prerequisites, upgrade gold and Galleys
are labeled fixture inputs. No promotion or movement budget is assigned by the
test. Astronomy remains unknown to all three players.

Complete baseline `20260919T083635Z` verified that fresh human/AI Polynesian
Galleys lack Ocean Impassable while the Roman control retains it. Normal paid
Galley→Galleass upgrades succeeded: the human used the actual upgrade action and
paid 45 gold; each AI used its normal command on its real active owner turn and
paid 20. The native UnitConverted events and target types were checked.
Both Polynesian upgraded ships then carried the blocking promotion. A legally
staged ship could not enter the adjacent empty ocean tile. The Roman control
correctly remained restricted. The overall test recorded FAIL, saved its state
and exited 0; no synchronization or Lua error occurred. Failed save SHA-256:
`52e1b29e1524896365636acd61839a539d1894d1c5a85301cd16399ea8b14db3`.

The engine reapplies the new unit type's free promotions during conversion, after
UnitCreated. Polynesia's existing creation callback therefore ran too early.
The product now also listens to UnitConverted and refreshes the **new owner**
after the copy. Foreign recipients retain their normal restrictions. Six new
actual-handler cases failed before and pass after: human/AI upgrade copying,
incoming gifts, foreign outgoing gifts, dead recipients and unrelated owners.
The shared unit-owner suite then passed all 45 cases (including unchanged Swiss
and New Zealand cases); this was not 45 separate Polynesian gameplay tests.

Fixed same-input run `20260919T084518Z` passed all five native assertions.
Both Polynesian upgrades remained ocean-capable, and Rome retained the
restriction. The human Galleass moved through the normal synchronized mission
from coast (5,2) to ocean (6,2), spending movement 240→180 without Astronomy.
It exited normally (0), save SHA-256:
`f1513b42163cb82506c1310a4929a719a9fe8288f80336b935a0cb3c2f3d658a`.
Exact reload `20260919T084701Z` passed, save SHA-256:
`719f3fa8fccc2c1a50f32d398105f209f37e7242815d9cd8687cccafc76418b5`.
Both preserved settings/hooks/manual saves without Lua/protocol/synchronization
errors or new diagnostics. This is scripted action/outcome evidence, not mouse
interaction or earned unit/technology production.

## Gift owner boundaries

`20260919T084859Z` loaded the corrected upgrade save. The human's normal Gift
action transferred its Galleass to Rome, where the standard ocean restriction
returned. A fresh Roman gift ship was then supplied on Rome's real AI turn,
staged on an empty Polynesian coastal tile and gifted through the normal AI
command. The new Polynesian owner cleared the inherited restriction. A normal
synchronized move then entered ocean and spent movement, still without Astronomy.
Contact and staging positions were recorded as inputs; no ownership, promotion
or move outcome was assigned. This tests commanded gifts, not autonomous AI
negotiation or travel to the staging tiles.

All three checks passed with normal exit (0), save SHA-256:
`5d0fd574542efe74c2e2f8d38e5688c12c66e6c1dba98d536d5e0f8154cd21a7`.
Exact reload `20260919T085344Z` passed, save SHA-256:
`b028c2a0d52762a52995fd6e55fe5ad3b729b6ddacec626600abf82d8f49aaa9`.
Both verified cleanup, original-save preservation and no Lua/sync errors.

## Already-affected saves

The conversion-only fix did not repair flags already serialized into old ships.
Read-only baseline `20260919T085728Z` loaded the failed `083635Z` save without
creating units, setting promotions, positioning units or advancing turns.
Both Polynesian ships still had the restriction and ocean entry was rejected;
the Roman control stayed correct. It saved the failed result and exited 0;
save SHA-256:
`b3ceb89217688b3b8f2d6bde978b90bd09c12f08473b2014f305e55f0926901c`.

A normal SequenceGameInitComplete listener now reconciles this derived trait
state for living Polynesian major players after the saved units are available.
The pattern follows existing initialization repair in the mod. Two additional
isolated cases verify human/AI saved ships, idempotence, unrelated promotion
preservation and foreign/dead exclusions. The full owner suite now passes 47
cases; the Polynesian subset is 13. The earlier creation and conversion listeners
remain, so new units, conversions and existing saves use the same ability rule.

Fixed old-save test `20260919T090227Z` passed all three assertions. Both saved
Polynesian ships loaded without the restriction, Rome stayed restricted, and
the saved human ship legally moved into ocean using the normal network command.
No units, promotions, technologies, coordinates or move budgets were supplied,
and no ordinary turn advanced. Normal save/exit returned 0 with preservation
checks and no Lua/sync errors; save SHA-256:
`b7c5585ed96a18d8c57ee516846d314bb50fcc7e252a42ccb9d8398b04fe62dd`.

## Retained setup failures and reproducible input

The original initial save is
`080442Z/autosaves-after/AutoSave_Initial_0082 AD-0260.Civ5Save`, SHA-256
`967891ad71dbb518bcb0939996654850f3e3b0ea6269e61903bb75f756caea9d`.

- `080442Z`, `082057Z` and `082839Z` stopped at the AI upgrade gate. Diagnostics
  showed the original AI probe ships were pending deletion, despite valid moves,
  technology, gold, ownership and stack count. The engine correctly rejected
  their upgrades. The driver now supplies fresh AI probes on empty owned coastal
  tiles during their real owner turn, leaving original deletion flags untouched.
  This does not validate autonomous AI upgrade choices or diagnose why it chose
  to remove the earlier probes.
- `083228Z` completed all three paid upgrades but hit a test API naming error.
  The driver now uses the actual CanMoveOrAttackInto binding. On the empty
  neutral ocean tile, this is a movement eligibility check.
- `080901Z` failed during startup before the diagnostic. Its healthy cache,
  subsequent approved stock-menu comparison and exact reinstall are separately
  recorded in [startup evidence](macos-startup-cache.md). It is not a gameplay
  result or a root-cause fix.

These failures remain in their reports. The completed `083635Z` baseline and
`084518Z` retest retain the per-command promotion observations, so a later unit
creation cannot mask the conversion defect. The test's AI commands always require
nonhuman ownership and an active owner turn. Human actions use normal action or
network-message paths, with unchanged synchronization checks.

Run `--scenario polynesia-upgrade --scenario-turns 3` on the preserved initial
save, with `--mode single-player-smoke --turns 3 --timeout 600 --stall-seconds 240
--save-and-exit`. `polynesia-gifts` uses the corrected upgrade save and a two-turn
bound. `polynesia-load` uses the failed upgrade save and zero turns. Each supports
`--expected-state` on its recorded result for exact reload. The runner guard suite
passes all 32 cases.

## Artifacts and limits

Conversion-only archive `Lekmod-polynesia-conversion-20260919.zip` SHA-256:
`6d4d7fa6fac2fff38737b504c385bf82a86781c3e6eab26cd1070a87fb90da71`.
Current conversion-plus-load archive `Lekmod-polynesia-load-20260919.zip`:
`b3e0b9ade0db1542d8385a06d0a644fd9643ff7c5f23a8304950f757cce96999`.
Both use signed core
`7a4a5abb38928278e940bdd83ee05d234972d1ffceef4125d46b637e8c8fdca9`.
These are intermediate packages built with the Polynesia changes uncommitted,
not the final clean release artifact.

Koa/Moai mechanics, land-unit early embarkation, capture variants and other
boundaries remain separate. Current-Mac single-player evidence does not establish
multiplayer or other-platform support.


Exact repaired-save reload `20260919T090450Z` passed on the final package,
with normal exit and preservation checks; save SHA-256:
`68d6dfdd938b0954cda6f2ec50a84e088ba27a69b8fa3a345cb641761096dc8d`.
The already-correct gift save also matched its complete `084859Z` snapshot
under the final package in `20260919T090803Z`, confirming initialization did not
change those correct ownership/restriction/position/movement states. It exited
normally with cleanup verified; save SHA-256:
`87e9a2c855b26f3083aef29f28fc3af35d9735ab4884aebbd812d44a76092603`.
Neither run recorded Lua, protocol or synchronization errors or new diagnostics.
