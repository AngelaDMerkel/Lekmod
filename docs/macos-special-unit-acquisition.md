# Special unique-unit acquisition

All ten unique definitions excluded from ordinary production now have at least
one native acquisition path under their own civilization. Together with the
[115 production definitions](macos-unit-production-validation.md), this establishes
one acquisition/resulting-state replay path for **all 125 unique unit types**.
It does not establish every ability, owner role, mission, belief interaction or
possible game state. These tests add scripted callbacks and native outcomes,
not physical mouse coverage. Multiplayer and the accepted long campaign remain
outside this work.

The product is unchanged: clean `f33cfd33`, archive
`build/macos/Lekmod-college-city-iteration-20260924.zip`, SHA-256
`9005a104f665ea4c5336c9ed8a85f31abdad782e33b277864a923ece3de09b01`.
No new gameplay defect or product-code correction was established in this phase.

## Passing paths

| Unique definition | Native acquisition | Passing run |
| --- | --- | --- |
| Bolivia Comparsa | Ordinary specialist progress, musician threshold | `20260926T022950Z` |
| Italy artist | Ordinary specialist progress, artist threshold | `20260926T022950Z` |
| Venice merchant | Ordinary specialist progress, merchant threshold | `20260926T022950Z` |
| Macedonian Hetairoi | Actual combat crosses the general threshold | `20260926T024649Z`, group 5 |
| Mongol Khan | Actual combat crosses the general threshold | `20260926T024649Z`, group 6 |
| Czech Foreign Legion | Normal gold purchase, exact 460-gold debit | `20260926T030004Z` |
| Madagascar Mpiambina | Normal faith purchase, exact 100-faith debit | `20260926T030004Z` |
| Maurya missionary | Normal faith purchase, exact 130-faith debit | `20260926T030656Z` |
| Tibetan Dalai Lama | Ordinary faith processing, 200-faith cost | `20260926T031507Z` |
| Vatican Swiss Guard | Normal gold purchase, exact 210-gold debit | Earlier `20260924T230221Z`; [religious-unit evidence](macos-vatican-validation.md) |

The nine new definition cases passed **42 functional assertions and nine exact
replays**, plus exact baseline replays for the new Czech and Maurya human starts.
The six great-person cases include separate default-unit owner controls. The
new unique acquisitions use four human and five AI paths. AI use of a generated
person before the checkpoint is distinct from its recorded native birth;
resulting cities/units/counters and the explicitly snapshotted state are replayed.

The three specialist stages each used one ordinary turn. Their buildings and
progress at threshold-minus-0.01 points were supplied. The native city update
created the right replacement/control, reset progress and raised the next class
threshold. No target `InitUnit` or `DoSpawnGreatPerson` call was made.

Each general stage used one ordinary turn. War, full-health combatants, upkeep,
uranium and global XP one below the threshold were supplied. Actual attacks
awarded XP, created the right general, spent one previous threshold, preserved
overflow and raised the next threshold. Attacker XP is checked after combat
settles: native global general points are processed before the attacker's own
XP assignment. The general promotion is checked through the exported
`IsHasPromotion` API; `IsGreatGeneral` is not exposed to Lua.

Purchase cases use the actual ProductionPopup callback and native UnitCreated /
CityTrained events. They check rejected production, missing research/religion,
Mpiambina's enhancement gate, a foreign-owner rejection, cost-minus-one/exact
budgets, exact debit, unchanged other currency/control state, free promotions,
and relevant religion/charges. Religion and empty legal cities are supplied
inputs. Czech and Maurya units actually move immediately after purchase without
advancing a turn; Mpiambina has zero movement as its data specifies. Maurya's
raw strength 1000 resolves to 10000 pressure units through the native ×10
multiplier, with no strength-modifying belief in this fixture.

The final prophet case used two ordinary turns. With open religion slots and
zero supplied faith, a **completed** turn-two-to-turn-three round produced no
paid prophet. Religions and faith of quoted cost +100 were then supplied; the
normal spawn-chance calculation is guaranteed by that excess, without changing
its RNG roll. Native processing created the unique/default units, removed the
quoted costs and increased their next prices. Both observed debits were 200;
the next price was 260. Religion, spreads, faith and resulting state reloaded.

## Retained commissioning failures

- `20260926T023515Z`, 102.0s: both general stages called the C++-only
  `IsGreatGeneral` method from Lua. The callback and snapshot failures remain.
- `20260926T024135Z`, 128.6s: general callbacks demanded attacker XP before its
  later assignment; the prophet callback also rejected an additional birth.
- `20260926T024649Z`, 173.6s: both general stage/reload pairs passed; the prophet
  stage still rejected the additional unit. The containing report remains failed.
- `20260926T030004Z`, 223.3s: Czech/Madagascar purchase stage/reload pairs and both
  new baseline replays passed. Maurya incorrectly compared raw religious strength
  with resolved pressure. The prophet observer tracked enhancement but missed the
  separate City of God reformation grant. The containing report remains failed.
- `20260926T030656Z`, 116.4s: Maurya's six checks/reload passed. The prophet observer
  required later accounting to have happened before a free-grant callback. The
  containing report remains failed.

The source confirms City of God uses the legacy `NumFreeSettlers` field to grant
a free civilization-specific prophet through `DoReligionOneShots`. The observers
now distinguish the reformation/enhancement event from a paid faith spawn. The
**passing** prophet run selected a different reformation belief with no free
unit reward. A completed positive City of God grant test is not claimed here.

Earlier prophet variants also requested an end turn without waiting for the
observable turn to advance before their low-faith assertion. That earlier check
is not accepted as an ordinary-round negative test. The final case explicitly
requires one complete round, recorded as `prophet-below-cost-round` (2→3).
No synchronization check or GameCore wait flag was changed.

All listed runs exited normally with settings/UI restoration and prior manual
saves preserved; there were no new crash diagnostics or synchronization errors.
Their harness assertion failures remain separate from product behavior.

## Reproduction and preservation

Plans under `LEKMOD_DLL/macos/batch-plans/` are:

- `unique-specialist-birth.json`: three cases, 12-turn aggregate cap.
- `unique-general-birth.json`: two cases, eight-turn aggregate cap.
- `unique-generals-and-prophet.json`: three cases, 12-turn aggregate cap.
- `unique-special-acquisition.json`: two baseline replays, three purchases and
  the prophet case, four-turn aggregate cap.
- `unique-special-acquisition-recovery.json`: Maurya and prophet only.
- `unique-prophet-recovery.json`: the final isolated prophet case.

The two additional normal human starts were created through the guarded fixture
builder, with Rome as the AI: Czech `20260926T025552Z` (73.1s) and Maurya
`20260926T025706Z` (71.1s). Both passed five initialization/founding checks.
Their pinned save and source-report hashes are in the acquisition plan. The
builder's custom-roster and refusal checks pass (six tests).

`aa436dde` adds opt-in batch preflight for native colon-call names and a regression
for the unavailable getter. The dispatcher tests pass (25). This checks method
registration, not signatures, receiver types, units of measurement or callback
timing; those still require source review and native evidence.

Independent evidence: `build/macos/special-acquisition-validation-20260926.json`,
SHA-256 `54ec4ac6e21ab5658f6005152377abc121f962ed2761a93e8a596484d3f0fedd`.
It records accepted stages, all resulting checkpoint hashes, births, controls,
additional observations and the two baseline replays. All accepted copies match
the completed original saves. Stock is active, no Civ V process remains, 600
prior manual saves and the original quicksave are unchanged, settings are
restored, and all 32 stock UI hashes and canonical/Aspyr backups are intact.
