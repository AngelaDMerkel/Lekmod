# Shelter damage, spaceship hurry and counterspy boundaries

The three specified cases now have20 passing native assertions and three exact
replays on the pinned current candidate. This is an aggregate of identified
stages/runs, not an uninterrupted all-stage pass. No product change was needed.

## Spaceship hurry and counterspy

In `20261002T221359Z`, the Engineer stage passed seven assertions and exact replay:
normal Apollo completion unlocked component production; missing Spaceflight
Pioneers rejected hurry; the supplied policy enabled it for all four component
types. Five actual hurry actions verified doubled independent production amounts,
unit consumption and the remaining-production cap. An ordinary military target
remained ineligible, and the next normal owner turn produced an unassembled
booster without creating a victory or assembly outcome.

The same process then passed the five counterspy assertions and exact replay.
Its real AI defensive assignment, human intrusion, travel/surveillance and mission
resolution killed the recruit, yielded no claimable science and promoted the
counterspy. It used16 ordinary turns; the Engineer stage used two. These remain
native outcomes with supplied prerequisites, not physical mouse tests.

The full607.6-second batch retains its failed-functional verdict because the
preceding shelter fixture exhausted legal space for a fourth isolated city.
The two passing stages are accepted only through the strict isolated-stage
contract: explicit reviewed fixture failure, matching report/stage assertions,
closed-writer checkpoints, exact replays, normal exit0 and complete preservation.
No Lua/synchronization errors or new crash diagnostics were recorded.

## Sheltered units

The completed retest `20261002T223137Z` passed eight assertions and exact replay
in185.8seconds, with zero ordinary turns. The actual resolved unit table contains
only the level2 nuclear missile; no synthetic level1 weapon was introduced.

| Supplied unit state | Native outcome |
| --- | --- |
| Healthy combat unit, shelter |25 damage; survives.|
| Healthy combat unit, no shelter |100 damage; dies.|
| Healthy sheltered unit, strike on adjacent plot |25 damage; survives.|
| Sheltered combat unit with74 prior damage |99 total damage; survives.|
| Sheltered combat unit with75 prior damage |100 total damage; dies.|
| Healthy Worker in each case |Dies: computed25/100 blast damage exceeds the configured civilian threshold6.|

Each real strike consumed its missile, incremented the explosion count and
returned the nuclear-unit count to its prior value. An ordinary Warrior had
nuclear level−1 and could not target a nuclear attack. War and nuclear diplomacy
were recorded. These unit outcomes complement the separately tested city
population/HP effects of the sole configured−75 Bomb Shelter modifier.

The fixture supplies cities, shelter, units, uranium, wounds and target visibility.
It resets the reused target city's population/HP between inputs and stages prior
surviving probes away without healing them. Missile missions alone create the
measured damage, deaths and consumption. No wait/synchronization flag is changed.

## Retained fixture failures

The first attempt ran out of space after three successful strike outcomes.
`20261002T222712Z` then reused one city but failed its unnecessarily land-only
adjacent-target search on a coastal site. Both failed reports remain unchanged.
The final fixture preflights an adjacent plot through the real `CanNukeAt` query
before any strike; native targeting has no land-only restriction. All original
health/damage assertions remain unchanged. The failed partial stages are not
claimed as complete shelter cases.

## Artifact and preservation

Archive `build/macos/Lekmod-config-edge-20260927.zip` retains SHA-256
`0726506aaaffde2f2ef9cc32b86f036a4bc6d611bf420910a946174e3c549339`;
actual GameCore SHA-256 is
`6c7aafb11d9e5aea80d1e7b95c6b8f3498820385f6e132abea81bad0b3b8cf6f`.
The actual compiler switches confirm spaceship hurry requires its policy;
`NQ_ALLOW_SS_PART_HURRY_BY_DEFAULT` is disabled.

Reproduce the combined plan with
`batch-playtest.py --plan LEKMOD_DLL/macos/batch-plans/acceptance-reward-boundaries.json`
or the focused corrected fixture with `batch-plans/nuclear-shelter-recovery.json`,
using the pinned package/hash. Raw reports/checkpoints retain all three run IDs.

All processes exited normally0 and restored temporary settings/UI. Final audit
`build/macos/nuclear-shelter-preservation-20261002.json` verifies904 original
baseline files, all866 non-autosave files captured before the last run,32 stock UI
originals, original host/core/backups and no remaining game/launcher or installed
payload. macOS remains26.5.2/25F84. Stock is active; nothing was pushed.
G0 and full final acceptance remain incomplete.
