# Vatican ability validation

Five independent Vatican ability cases now have passing native outcomes and
exact reloads: 30 assertions and 14 ordinary turns across three runs. Their
containing commissioning batches retain overall failed verdicts where another
stage failed. This is aggregated passing evidence, not one uninterrupted green
full-plan run. All use clean package `9005a104…09b01` / core `2dcc9094…8abc1` from
`f33cfd33`, on the current Mac. There is no physical mouse coverage here.

| Case | Passing run | Assertions | Ordinary turns |
| --- | --- | ---: | ---: |
| vatican-pressure-votes | `20260924T223011Z` | 5 | 4 |
| vatican-conversion | `20260924T222330Z` | 5 | 3 |
| vatican-capture | `20260924T222330Z` | 5 | 2 |
| vatican-great-sites | `20260924T224553Z` | 10 | 1 |
| vatican-kill-faith | `20260924T224553Z` | 5 | 4 |

## St Peter's pressure and delegates

After explicitly supplied research, contacts, religion, a Temple and a legal
nearby target city, Congress formed through its ordinary eligibility path.
St Peter's completed through an eligible, unforced AI owner-turn queue, with
near-complete production supplied. Its real CityConstructed event changed
nontrade outgoing pressure from **90 to 180** and calculated starting delegates
from **1 to 3**. The host/human's two delegates were unchanged, and the distant
human capital remained at zero pressure. Over one later ordinary turn the
nearby target's stored religious pressure increased by exactly 180. Exact
pressure, cities, religion and delegate state reloaded successfully. This
checks the delegate calculation, not a separate newly allocated voting session.

The first attempt `20260924T222330Z` had passed the instantaneous effects but
incorrectly assumed that returning the driver's `turn` request meant the next
callback was already in a later turn. The native state was still on turn 5.
The test now waits for ordinary turn advancement; it does not change turn,
synchronization or wait flags. `20260924T223011Z` passed settlement/reload.

## Courthouse on capture and conversion

Both paths use a real AI move/attack to capture the human original capital;
a supplied legal second human city keeps the human alive. One independent
fixture supplies Vatican-religion conversion before capture. It grants exactly
one Courthouse through the real capture event. Another starts the captured city
without that religion and correctly grants none, then a supplied Prophet uses
a legal owner-turn spread mission. Actual majority conversion grants one
Courthouse. In both cases a normal annex task preserves the building and native
occupation-unhappiness exemption. The nonoccupied Vatican holy city and the
human-owned target before capture receive no Courthouse. Ownership, disposition,
religion, building counts and relief state reload exactly.

Religion founding, pre-capture conversion in that branch, cities, attackers,
Prophet placement, upkeep and uranium are explicit inputs. Capture, post-capture
Prophet conversion, Courthouse award and annexation effects are outcomes.
Foreign-religion conversion away, recapture/gifting and every owner permutation
remain outside these cases.

## Great-person improvement bonuses

Fourteen actual Great Person build missions produced paired Vatican/Roman
Academies, Manufactories, Customs Houses, Holy Sites, Concert sites, Docks and
Citadels. Each observed BuildFinished and unit consumption. Each Vatican
improvement's before/after tile-yield delta exceeded its Roman counterpart by
exactly **2 food, 1 gold and 1 culture**, without changing underlying terrain,
resources or roads. All seven comparisons and exact reload passed in
`20260924T224553Z`. These are tile yields, not proof that every tile was worked
or that every city-income combination was exercised.

Inputs are research, legal extra coastal cities and the corresponding Great
People on naturally eligible owned plots. The first site selector counted water
toward land capacity, leaving too few Roman land plots (`20260924T223011Z`). A
land-only correction could select coast with no eligible clear Dock tile
(`20260924T223706Z`). The final selector requires usable land and water and
checks both inventories before any build. These fixture failures are retained;
no product rule was changed.

## Faith from military kills

Vatican and Roman AI owners used normal attacks with supplied full-health
attackers and defenders on natural flat staging plots. Native deaths/capture
and attacker XP were verified. Vatican gained **8 faith** for a Warrior,
**7 faith** for an Archer (its larger ranged strength), and **30 faith** for a
34-strength Rifleman, exercising the cap. Capturing a civilian Worker gave
zero faith. Matching Roman military/civilian cases all gave zero. The final
state reloaded exactly in `20260924T224553Z`.

A noncombat religion, uranium and upkeep are supplied inputs; no damage, death,
faith reward, combat strength or wait flag was assigned. City attacks,
no-religion-option behavior and unique-unit/trait stacking are separate cases.

## Evidence and pending terrain test

Every listed source/reload snapshot pair and checkpoint hash was independently
verified. All containing runs exited normally (0), restored settings/hooks and
preserved prior manual saves, with no Lua/synchronization errors or new
diagnostics. Managed wrappers restored stock after each run. The complete
source/reload paths and hashes are in the ignored local artifact
`build/macos/vatican-ability-validation-20260924.json`.

## Israeli/Jerusalem terrain and the three unique units

Run `20260924T230221Z` passed the complete new three-stage plan: **15 functional
checks and three exact replays** (including the new Vatican-human baseline),
197.1 seconds and eight ordinary turns, normal exit 0. The terrain stage uses
the older Israel-human fixture; the unit stage uses the normally generated
Vatican-human fixture `20260924T230005Z` (five startup/founding assertions,
two ordinary turns, 69.1 seconds, normal exit 0).

The terrain case supplies Cow/Gems resources before legal founding and uses
normal citizen tasks. Actual Worker builds produce both Pastures without supplied
work progress. Israel gains one tile culture and one worked-city terrain culture;
the Roman control gains neither. The completed Cow Pastures become locally
connected resources. Jerusalem's raw Gems give one faith, while its Cow control
and Rome's Gems give none. The worked Gems contribute one city terrain faith;
actual empire faith increases by the quoted two over a later ordinary turn.
All resource, improvement, worked/forced plot and city-yield state reloads exactly.

The new fixture has human Vatican, AI Israel/Jerusalem/Rome. The Swiss Guard
correctly rejects production and is bought through the real ProductionPopup
callback for exactly 210 gold. The Maccabee and Crusader complete through eligible
unforced AI queues on their actual owner turns, with near-complete hammers
supplied. Correct owner, type and base combat strength are checked. Each acquired
unit then legally attacks a supplied full-health Roman-owned Barbarian Archer
(melee strength 4, ranged strength 7) on a natural flat staging plot. Actual
combat death/XP occurs. The Swiss Guard earns 7 gold and 14 faith (unit plus
Vatican trait); Maccabee earns 7 faith; Crusader earns 14. Exact state reload passes.
These are acquisition and kill-yield paths, not every unit promotion/utility path.

The terrain commissioning failures are retained: raw Cow connection was checked
before improvement (`20260924T223706Z`), then the first normal click deselected
an automatically worked tile (`20260924T224553Z`). The corrected test checks
connection after Pasture completion and uses the ordinary deselect/select task
sequence before asserting forced work. No product behavior was changed.

The initial new-roster launch was blocked by the locked desktop before settings
changed. The user unlocked; the guarded launch then passed. Reproduction plan:
`LEKMOD_DLL/macos/batch-plans/religious-terrain-and-units.json`.
Aggregate evidence now contains **45 passing functional assertions across seven
stage/reload pairs**, plus the new baseline exact replay, with 22 ordinary turns
across independent fixtures. This is not one uninterrupted all-green aggregate
run. All selected checkpoint hashes and snapshots were verified. Latest independent
stock verification preserved 518 prior manual saves, original quicksave,
32 stock UI files, settings and both canonical/Aspyr backups. Evidence:
`build/macos/religious-civilization-validation-20260924.json`.

No product change was needed for these Vatican cases. Full single-player
certification and all civilization/owner/state combinations are not claimed.
