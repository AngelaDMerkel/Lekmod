# Nuclear mission validation

Current Mac, standard UI, isolated game-combat fixture loaded from the recorded
Industrial Archipelago save. A Nuclear Missile, full-health barbarian targets,
uranium, target visibility and one compatible target Farm were supplied inputs.
The blast area was unowned and had no preexisting units or cities. No damage,
death, fallout, pillage or turn value was assigned as an outcome.

The native unit reports nuclear damage level two and range twelve. Queries
reject the launch tile itself, an out-of-range tile and a non-nuclear unit. A
nearby target overlapping the attacker's own city is allowed by this engine's
victim-team rule; that target was queried but never attacked. Initial attempt
`20260919T040100Z` wrongly expected rejection and remains a failed test, not a
product defect.

The actual MISSION_NUKE command killed full-health Warriors at the target and
at radius two. A supplied Giant Death Robot's shipped nuclear immunity kept it
unharmed inside the blast, while a Warrior at radius three remained unharmed.
The direct target acquired fallout and its provided Farm became pillaged. The
missile was consumed. No city, population or diplomatic-consequence outcome is
claimed by this isolated barbarian-unit test.

`20260919T040248Z` passed those five gameplay checks and exited 0, but no manual
save was written after the callback. It remains `failed-save-or-normal-exit`.
The driver had requested saving as soon as unit/terrain changes were visible.

Read-only settling control `040702Z` observed resolved damage with no combat-end
event initially; by the thirtieth update EndCombatSim had arrived. A subsequent
normal save/exit succeeded. Save SHA-256:
`b96175f670eb409245b83c638d067bbe06ddeb760e38010766e71524ae5b46e8`.
No synchronization or wait state was cleared.

`20260919T041001Z` replaced the diagnostic fixed delay with a wait for the
matching EndCombatSim attacker owner/unit. Resolved damage was observed near
50 seconds; the real event for owner 0/missile 98314 arrived at 67.166 seconds.
All five gameplay checks then passed, the save was written, and exit was normal
(0). Save SHA-256:
`56d1809c8a412ce157fb2b5ad419995efa6fdf5af16904c2ca3c852f80d4a3d7`.

`20260919T041156Z` exactly reloaded the surviving human/barbarian units' types,
positions, health, movement and immunity, the absent missile/victims, fallout
and pillaged-improvement state, and turn. Reload-save SHA-256:
`eacb9f05c21d6b501ad0ddeec322ba43adeb5a5d35e208d5ca4b4bb2f34a5a20`.
Both final runs exited 0, restored settings/hooks and preserved manual saves,
with no Lua errors, synchronization failures or new diagnostics. No product
correction was made: the test driver now waits for the genuine combat-end event
before requesting a save. The earlier premature-save report remains failed.

The test package is `Lekmod-moors-founding-20260919.zip`, archive SHA-256
`13304c6e11215040b644e05ebbdb6347e294afe2bd782a0fa2088d8ac2e0493d`,
signed core `80a9ec3f54b96485606228c067f3656e727c2bf6b16c2c977cbf6c19bb85b8c1`.
These are scripted commands and native outcomes; no mouse interaction, weapon
production, city effects, fallout cleanup or complete nuclear-system coverage
is established by these checks.


## Production, cleanup and city effects (2026-09-21/22 UTC)

All runs below use the clean `f40fd2b2` release artifact, archive SHA-256
`e6904b434b3a3a7bebea4c2a83d1709c3aaf73d55a096237b6ed87f07fefcffc`.
No nuclear product change was necessary.

The `nuclear-production` stage in `20260921T011611Z` supplied prerequisite
technologies, uranium and production one hammer below completion. Missile
production was rejected before the player's Manhattan Project. Normal project
production completed Manhattan, rejected a duplicate project and unlocked the
missile. Normal unit production emitted CityTrained without gold/faith purchase
and created a range-12, level-two missile. Two ordinary turns were used. All three
checks and exact reload passed; the overall batch remains FAIL because its later
independent cleanup fixture failed. Checkpoint hashes are in that batch report.

The first cleanup stage removed real blast-generated fallout but its supplied
worker disappeared on an ordinary AI turn near the surviving immune GDR and
outside-radius barbarian. It failed before repair; this is retained as a fixture
failure, not a repair defect. The corrected fixture explicitly stages those two
enemies at distant land sites before supplying its worker. It does not change
AI turns or the real fallout/pillage outcomes being tested.

`20260922T203810Z` passed cleanup eligibility (actual fallout versus clean city),
normal scrub completion and repeat rejection, preservation of the pillaged Farm,
normal Farm repair and exact reload. One ordinary turn, 97.5 seconds, normal exit
0, full restoration/preservation, no Lua/synchronization errors or diagnostics.
The repaired Farm's food yield is 3. Checkpoint:
`0ac20155da0cc0243b23d6f8d858083eb71ff5a25ac3c31d9fe193dc502ab697`;
reload: `bf80421e736577b0e06e68e7dc97084d5a775ee89d3392b1e4dbc13b366be45b`.

`20260922T204010Z` supplied target cities/populations, launch sites, missiles,
uranium and a Bomb Shelter. Four ordinary MISSION_NUKE commands each reached their
actual EndCombatSim event before proceeding. Outcomes passed:

- A population-four original capital survived, with configured HP and population
  damage; the original-capital protection was observed.
- A population-four noncapital was destroyed by the level-two strike.
- A population-twelve city survived with configured HP loss and population loss
  inside the native random bounds.
- A population-twelve city with the -75% shelter modifier lost population inside
  the reduced bounds; HP damage followed the separate native rule.
- War and IsNukedBy diplomatic state were recorded, four explosion-count increments
  occurred, and the four missiles were consumed.

All five checks and exact city and nuclear-state reload passed in
150.4 seconds, with zero ordinary turns. Normal exit, restoration/preservation,
no Lua/synchronization errors or new diagnostics were verified. Checkpoint:
`37f5add9746b16c72741c8cf5b48e336bc1ea4843c65ac153bb0a0e28bc70f39`;
reload: `90468a9dd9197d3de7644a2966602ab167747115ad33eb1911ed1bee7ddb63bd`.
All listed checkpoint hashes were independently reverified. No outcomes, RNG,
wait flags or elapsed turns were assigned. These are scripted commands/native
outcomes, not mouse input or earned research/production prerequisites.

Reproduction plans are `batch-plans/critical-gaps.json` (use
`--from-stage nuclear-cleanup` for the corrected cleanup case) and
`batch-plans/nuclear-cities.json`, under `LEKMOD_DLL/macos`. Complete population,
HP and fixture-input observations are in each run's `batch-lua.log`.
The shipped Units table has no Atomic Bomb definition; residual art/localization
references do not make level-one atomic weapon production a supported feature.
