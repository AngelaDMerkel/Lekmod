# New Zealand native contact rewards, 2026-09-19

## First contact through ordinary movement

Run `20260919T120139Z` used an Ancient/Standard/Pangaea single-player opening
with human New Zealand in slot 0, AI New Zealand in slot 1, ten Roman controls,
no city-states, Always Peace, no barbarians and no ruins. Its initial duplicate-
civilization crash and correction are documented separately in
[the player-color report](macos-player-color-validation.md).

A supplied human Scout and AI Warrior started at an isolated three-tile sight
boundary. Their creation did not cause contact. One normal synchronized human
movement reduced the separation to two, triggering the actual engine TeamMeet
event and mutual contact. Both New Zealand owners received exactly 12 science
in overflow, with no technology selected. All ten unrelated Romans' gold,
faith, culture and overflow stayed unchanged. No product Lua callback or
TeamMeet event was invoked manually for this movement check.

## Engine contacts and random reward branches

Twenty further first contacts were explicitly supplied through the native
`Teams:Meet` API, one per New Zealand/Roman pair. Each emitted exactly one
engine TeamMeet event, affected only the correct New Zealand owner, and drew
one of the four real rewards: 40 gold, 10 faith, 6 culture or 12 science.
No RNG function, seed, result, reward balance or synchronization flag was
changed by the scenario. The runner's ordinary fixed setup seeds were retained.
These are native contact/reward integration checks, not twenty naturally
explored encounters or mouse interactions.

The naturally drawn reward counts were:

| Owner | Gold awards | Faith awards | Culture awards | Science awards |
| --- | --- | --- | --- | --- |
| Human New Zealand | 3 | 3 | 2 | 3 |
| AI New Zealand | 1 | 2 | 3 | 5 |

Final human balances were 120 gold, 30 faith, 12 culture and 36 overflow science;
AI balances were 40 gold, 20 faith, 18 culture and 60 overflow. No current
research was selected, so this checks the overflow branch specifically.
The existing isolated handler tests cover the selected-research branch;
its live native completion/overflow boundary remains separate.

Calling the engine Meet API again on the known New Zealand pair emitted no
new event and changed no balance. A genuinely new Roman/Roman contact emitted
one native event, with no reward to either Roman or either unrelated New Zealand
owner. The complete twelve-player mutual-contact matrix was recorded.

## Persistence and evidence limits

All five reward checks and the twelve-color check passed on turn zero, with
normal save/exit (0), settings/hooks/manual-save preservation, no Lua/sync errors
and no new diagnostics. Save SHA-256:
`851b8c32390b2e93ecb0213c444fe2bb9e2d94590be7f84165fa57262c7dd69d`.
Exact zero-turn reload `20260919T120411Z` matched every recorded balance,
civilization, color and contact, then exited normally with the same cleanup.
Reload save SHA-256:
`83d6c91943ade95eaacd4c71d4a037884704f41f1e472714cc8020050ee2de9e`.

Reproduce with `--scenario newzealand-meeting --scenario-turns 1` and the normal
setup above, including explicit Roman `--slot-civilization` arguments for 2–11.
Use `--mode single-player-smoke --turns 3 --timeout 480 --stall-seconds 240
--save-and-exit`. The turn allowance supplies ordinary popup handlers; no turn
was requested. Exact reload uses the saved file/report with zero turns.

The tested package is `Lekmod-player-color-holes-20260919.zip`, SHA-256
`9d31987e6fc86240d7c113b3c76dfb2af788f36b72716a4cf6b0d6923c4ac91a`,
signed core `4e1a94b9ea8c61c16e18e2bc32a6f46a54941c056bb804b14cfd4c8066bc764b`.
No New Zealand gameplay change was needed. Battalion influence, Defender
radius/friendship behavior, selected-research rewards and city-state contacts
remain distinct native cases; this is not full civilization certification.

## Science with selected research

`20260919T121257Z` loaded the preserved initial twelve-player opening
(SHA-256 `65e0a54a66de72375d2ca0619ded784254e548868e189b850274ccf255adcaad`).
The human starting Settler used ordinary Found, then Astronomy prerequisites
were explicitly supplied and the normal research command selected Astronomy
(cost 603). No research progress, overflow or reward value was set. The first
movement contact and twenty supplied engine contacts then repeated the owner,
Roman, no-repeat and naturally drawn reward checks.

All seven checks passed: human science rewards added exactly 12 progress each,
ending at Astronomy 36 with overflow 0; the AI retained no selected research and
received overflow 60. Human/AI faith, culture and gold totals matched the earlier
reward draw counts. No ordinary turn advanced. Normal save/exit (0), cleanup
and no Lua/synchronization errors or new diagnostics were verified. Save SHA-256:
`c69c1447f0a67bbd5299cf8664db8167b1241e18938c419bdcad06a95a56f20e`.

The preceding `120929Z` attempt remained a driver failure: research requires a
founded city, and its fixture lacked one. The correction used the real Found
action; no city-founded/research eligibility flag was bypassed. No product
change was required. `newzealand-research` shares the meeting scenario through
a temporary helper that the runner restores/removes. The complete snapshot
includes selected technology, progress, overflow and all contact/reward balances.

Exact selected-research reload `20260919T121530Z` passed with normal exit (0),
restored settings/hooks/manual saves and no Lua/sync errors or new diagnostics.
Save SHA-256: `0f0798b2cee235b323163a519184aaf5d52fa69dedabfe29ba90f907b29bb1e4`.
All 32 runner regressions pass. Technology-completion overflow remains a
separate boundary from the non-completing progress test.

## Contact reward completes research

`20260919T121827Z` used the same preserved initial opening, normal capital
Found and research selection, supplied prerequisites and 597 of Astronomy's
603 required progress. A supplied native first contact with Roman player 2
naturally drew the 12-science reward. No random result or completion flag was
assigned. The engine emitted TeamTechResearched, marked Astronomy known,
cleared the completed selection and carried exactly six science into overflow.
Stored target progress was 609; unrelated AI New Zealand and the Roman recipient
received no reward, and human gold/faith/culture were unchanged. Repeating the
known contact changed nothing and emitted no additional completion.

All three checks passed on turn zero, followed by normal save/exit (0), settings/
hooks/manual-save preservation and no Lua/sync errors or new diagnostics.
Save SHA-256: `fa9957023abae74bd33518543d86cd5e59063e90f8e255f4b5847e6e6b959013`.
Exact reload `20260919T122051Z` preserved completed tech, raw progress, overflow
and contacts/balances, then exited normally with the same cleanup checks.
Reload SHA-256: `f3afde520a03fc36fd011b4df3cf3e13dbca86c513975d99b9e9dc9d332bb832`.

Use `--scenario newzealand-science-completion --scenario-turns 1` with the
`120139Z` initial save; no turn was requested. The script tries distinct unmet
Roman contacts until a real science reward is drawn, and fails if the fixture
exhausts them. It never changes RNG state to obtain a pass. This fixture drew
science on the first supplied contact; the previous 597 progress was an explicit
input, not an earned-research claim. No additional product fix was required.

## Battalion influence on actual owner turns

`20260919T122718Z` loaded the preserved two-Rome/two-city-state AI Zabonah
fixture; New Zealand was absent. Units, treasury and friendship values were
explicit inputs. Two human-owned Battalions occupied friendly city-state 22's
land, with an ordinary Warrior there, a Battalion in unfriendly city-state 23
and a Battalion on unowned land as negative controls. A fresh AI-owned Battalion
was supplied during the real AI owner turn. No promotion was assigned; the
native unit type supplied its own influence marker.

A read-only observer appended after the actual New Zealand Lua registrations
bracketed the automatically dispatched PlayerDoTurn handler, separating its
reward from ordinary city-state decay or other AI actions. The AI case changed
friendship 45→46 and left its neutral control at 0. At the next human owner turn,
the friendly standing changed 43→45 while the unfriendly value stayed -6.
The normal-unit and unowned-plot controls did not increase the expected two-unit
reward. Both Roman owners demonstrate the unit ability with its civilization
absent. This is native handler timing/outcomes with supplied units/standing,
not earned unit production or a naturally negotiated friendship.

The first attempt `122405Z` remained FAIL: its AI neutral precondition had changed
before measurement. In the corrected fixture, the logged AI value was 45 at
that point, so the intended neutral standing was supplied after preceding AI
processing/unit creation and before the measured handler. The input and before/
after observations are separate; no reward or synchronization flag was set.
The original failed report remains unchanged.

All four checks passed after one ordinary turn (2→3), with normal save/exit (0),
settings/hooks/manual-save preservation, no Lua/sync errors and no new diagnostics.
The appended observer and original product script were restored. Save SHA-256:
`277c1a6e82ddc05a3c57c8161ab0aaf58edb8df241a25ebdd1978234c58c0e96`.
Exact reload `20260919T122938Z` preserved influence and all recorded owner/unit
states, then exited normally with the same cleanup. Reload save SHA-256:
`ff995e4059ce804fdde51100cd3d0506856e6f84559de7066246384d6bd40104`.

Use `--scenario newzealand-battalion --scenario-turns 2` with the `114525Z` save,
then exact zero-turn reload. No product change was needed. Minor/barbarian-owned
Battalion exclusion remains isolated-handler coverage; further defender geometry
and real zone-of-control movement are separate native cases.

## Defender boundary defect: paused before native retest

`20260919T123456Z` loaded the retained actual Rome/Argentina friendship save
`20260916T105738Z` (SHA-256
`4257141f236b0c8e43c1216b0f2b5a5b492a8bbb5e9d5f43606fef07177901a0`).
Coastal cities, five Defender probes, one ordinary Ironclad and upkeep were
explicit inputs. After one ordinary turn (20→21), the actual owner-turn handler
activated the ignore-ZOC promotion at distance three from both owned and
Declaration-of-Friendship cities. The documented Help, Strategy and promotion
text all specify two tiles. Distance-two positives, the far-away Defender and
ordinary Ironclad controls behaved correctly. No promotion outcome was assigned.

The baseline remains FAIL. Its saved state is
`91586434b2476e3cd1e981c26c2c2a5cb2e462d714bdc76b29855fbc68667db6`.
The runner terminated the process (-9), so this is not normal-exit evidence.
Temporary hooks/settings were restored and manual saves preserved; no Lua/sync
errors or new diagnostics were recorded.

The uncommitted correction replaces IsPlayerCityRadius, which describes the
wider workable radius, with Map.PlotDistance against each qualifying owner's
cities and an explicit two-tile limit. The existing start-of-turn timing stays
unchanged. The expanded 57-case actual-handler suite has four distance-three/
stale-state failures before the fix and zero afterward; all 32 runner regressions
pass. Geometry/engine objects in those isolated tests are stand-ins.

Candidate archive `Lekmod-defender-radius-20260919.zip` was built successfully
with SHA-256 `c12bf01668c657ddea481c4f265b0ce12bc98490ca9bf92fad32c2c1c966db94`.
The user stopped testing before installation/native retest. Stock is restored.
Preserve the four uncommitted files and finish the same-fixture native retest,
exact reload and affected-save recovery on the next ordinary owner turn when
authorized to resume. Do not clear an earned start-of-turn effect merely because
a ship moved farther away before saving/loading. Real zone-of-control movement
and further owner boundaries remain separate checks.

## Defender correction: native batch retest and reload

The resumed single-process pilot `20260920T224820Z` (PID 45746) passed all five
Defender assertions on the preserved Rome/Argentina friendship fixture. Owned
and DoF-city distance two activated the promotion; both distance-three probes
correctly remained inactive; far Defender/ordinary Ironclad controls remained
unchanged. It used one ordinary turn. The run checkpoint SHA-256 is
`be3fd61fe85c7af2d3cce873b61dce6095fb279bbdaf204be9eb13d21f665045`.

An exact checkpoint reload in the same native process preserved all city,
friendship, unit-position/movement and promotion fields. Reload checkpoint:
`d431b6ad9ac3a26a28a5f2e478a678051a25dec7031eff57d24200edee843b98`.
The process then passed Great Admiral repair and its reload before normal exit
(0). All temporary hooks/settings and manual saves were preserved, with no
Lua/synchronization errors or new diagnostics. The managed wrapper restored stock.

The candidate Defender correction is now supported by the 57-case actual-handler
suite (four pre-fix distance/stale-state failures), the native boundary retest
and exact reload. It retains start-of-turn timing; real enemy-zone movement and
recovery of an old affected save on its next owner turn remain additional cases.
This evidence verifies the promotion boundary, not every Defender combat path.

The dynamic batch's Battalion ordering assumption was corrected separately from
gameplay: test-only signals now bracket the real product registrations, so a
late stage can observe the actual before/after states. Targeted batch
`20260920T233452Z` passed all four Battalion checks and exact reload, with normal
exit (0), complete cleanup and no Lua/sync errors or diagnostics. The failed
Battalion verdict in full batch `231930Z` remains unchanged; see the batch guide.


## Defender old-save recovery and actual zone-of-control movement

Stage `defender-zoc` in `20260921T011611Z` loaded the preserved pre-fix save
`91586434…7db6`. Both incorrect distance-three bonuses were still present on
load. One ordinary owner turn removed the owned/friend distance-three bonuses
and retained the distance-two bonus, without assigning any promotion state.

Three separate water triangles and hostile Triremes were explicit staging inputs.
The normal human MOVE_TO command moved each ship between two tiles adjacent to
its enemy. The active Defender spent 60 of its 180 movement points and retained
120; the inactive Defender and ordinary Ironclad both spent all 180. Moving the
active ship outside the city radius in the same turn preserved its earned
start-of-turn effect. No movement, wait or promotion flag was set to obtain the
result. Exact in-process reload preserved ships, enemy positions, movement and
promotions. These four checks passed within an overall batch that later failed
an independent cleanup fixture; that overall FAIL verdict remains unchanged.

Checkpoint SHA-256:
`24c129933896f911a1721a41e8554d33621f9fc6414fa0cf3c6b77fb32179e13`.
Reload checkpoint:
`c08b7d0ec360d389b56bee68be36ffce5c64a81e06521c72243f164247ef23ab`.
Reproduction: `batch-playtest.py --plan LEKMOD_DLL/macos/batch-plans/defender-zoc.json`
with the verified clean release package. This is native movement/outcome evidence,
not mouse input. No additional Defender product change was needed.
