# Nabataean Zabonah discovery and lifecycle, 2026-09-19

## Off-map removal defect

Native baseline `20260919T092209Z` started an ordinary Ancient/Duel/Pangaea
single-player game with two Roman majors, no barbarians and no ruins. Nabatea
was absent. The human starting Settler used normal Found, then one Zabonah was
supplied as a labeled unit input. Its normal Delete action and actual Yes
confirmation removed it and paid the quoted four-gold refund.

The engine also emits UnitSetXY during removal with invalid map coordinates.
The discovery handler passed the resulting nil plot to PlotAreaSweepIterator,
causing a runtime error at PlotIterators.lua:151. The runner correctly classified
this as `failed-lua-runtime-error` even though the disposal assertion and normal
save/exit (0) completed. This is a Lua callback failure, not a recorded native
crash. Failed-run save SHA-256:
`f4e671ec5e0f08f44e7a9a20e8484d15a4d170dc1e286b5ff7d1cf4e603cc961`.

The handler now verifies an existing living owner, an existing unit not pending
deletion, the Zabonah type and a valid map plot before scanning. It leaves the
reward logic unchanged. Thirteen actual-Lua handler cases cover capital rewards,
repeat/already-revealed/noncapital boundaries, multiple capitals, human/AI owner
routing, unrelated units, civilization absence and missing/dead/off-map inputs.
Five failed before the guards; all 13 pass afterward. Their plot iterator is a
stand-in, so they do not establish native radius/visibility behavior.

Same-initial-save retest `20260919T093015Z` completed the same normal disband and
four-gold refund without a Lua error. It saved/exited normally (0), preserving
settings/hooks/manual saves with no protocol/synchronization failure or new
diagnostics. Save SHA-256:
`1f41bb8e42fd9e6aeaa775c704ef74284ed5c9eb6ff93154c72abdb96e3dd62e`.
Initial fixture SHA-256: `037233f07af22d8d5b1f7204eff79a308805f69421d0c5a0e31b40766ad24c32`.

## Native discovery and repeat boundary

`20260919T093455Z` used an Ancient/Small/Pangaea single-player fixture with two
Roman owners, Always Peace, no barbarians and no ruins. Supplied inputs were a
legal unrevealed foreign capital, a Zabonah, a normal Scout and clearly recorded
staging positions. Neither gold nor discovery outcomes were assigned. The
corridor excluded nearby natural wonders to isolate discovery rewards.

The normal Scout first moved through a synchronized mission to the extended
radius: the capital stayed unrevealed and gold did not change. After clearing
that control from the corridor, the Zabonah's normal synchronized movement
reached distance five while its ordinary sight was two. The real UnitSetXY
handler revealed the capital and increased treasury exactly 0→10. A second
normal move within the discovery area kept gold at 10. No ordinary turn advanced.
This establishes the extended capital reward and non-repeat path for a foreign
unit owner with Nabatea absent. It is not a mouse test or earned unit/city
production, and it does not establish every terrain/visibility geometry.

All three assertions passed, followed by normal save/exit (0), preservation checks
and no Lua/protocol/synchronization errors or new diagnostics. Save SHA-256:
`116e81c34067d5bd49de3a65df72d7887623c34d1acfef94a5cbac7300327752`.
Exact reload `20260919T093713Z` matched the capital's revealed state, gold, unit
positions/movement and turn, then exited normally; save SHA-256:
`20a2f5a53b48fa962e3166a649f23cc7903c389a56e780a6de4164a1b5846663`.

## Current mechanics versus dormant legacy source

`MC_NabateaAddin.lua/xml` remains in the repository, but its LoadNewContext call
is explicitly commented out in the shipped InGame template, which is shared by
the configured standard/EUI builds. Its old food-purchase controls are not a
current feature to enable or certify. The inventory contains 26 civilization Lua
source files but 25 explicit active civilization contexts, plus that dormant
legacy add-in. This source audit is not evidence for arbitrary third-party mods.

The current Nabataean trait is the freshwater-farm bonus at Mathematics until
Civil Service. That trait, Rock-Cut Tomb yields/resources/trade effects, AI
Zabonah movement and city-state-capital discovery remain separate native gaps.
The present native discovery case uses a major capital; AI reward logic and
noncapital/missing-owner boundaries are isolated Lua evidence.

## Reproduction and artifact

`nabatea-disband` uses the retained initial save under
`092209Z/autosaves-after/AutoSave_Initial_0000 BC-4000.Civ5Save`, with explicit
`--mode single-player-smoke --turns 3 --timeout 300 --stall-seconds 180
--scenario nabatea-disband --scenario-turns 1 --save-and-exit`. The one-turn
allowance enables normal popup helpers; no turn was requested by this scenario.
`nabatea-discovery` can start the controlled two-Rome Small/Pangaea fixture with
a two-turn maximum, though the accepted run used zero. Both support exact reload
using their saved files and reports. All 32 runner tests pass.

Intermediate standard archive `Lekmod-zabonah-removal-20260919.zip` SHA-256:
`9d10cd396769a678ebd23da76a017fd171bd3050976195caf34c14c6f63fbbfb`;
signed core remains
`7a4a5abb38928278e940bdd83ee05d234972d1ffceef4125d46b637e8c8fdca9`.
The product correction is Lua-only. This package was built before its commit
and is not the final clean release. Full current-Mac coverage remains open;
multiplayer and other platforms remain deferred.

Exact disband-state reload `20260919T093907Z` passed with normal exit (0),
settings/hooks/manual preservation and no Lua/protocol/synchronization errors.
Save SHA-256:
`9e913405f8ad907ce731e45ea39674c22400a6f0448a4d6c061a3815775d49d7`.
