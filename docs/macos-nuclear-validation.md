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
