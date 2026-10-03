# Policy promotion and founding effects

The current native policy batch uses clean Consulates package
`build/macos/Lekmod-consulates-fixed-20261003.zip`, archive SHA-256
`52778f2971c77ac4bc2fdfc2f6ce6e2b753cf24d438b5821bf86dace6935130c`,
GameCore `c8f1723c7588fdf54465781ebbca9d8de009e3e11c76ba6375b5200fd9687aa2`.
No product change was needed for the three passing stages below.

## Native promotion grants

`20261003T011152Z` passed eight promotion assertions and exact replay. Human
commands and actual AI owner-turn adoptions each granted Morale to existing
Warriors, Riflemen and Paratroopers, and Dogfighting I to Fighters. Newly created
units received the same configured flags. The native modifiers were15combat
percentage points and33air-sweep percentage points. Archers/Workers remained
unpromoted; the foreign owner's probes remained unchanged before its adoption.
Further creation/adoption refreshes did not stack bonuses, each target adoption
emitted the native event and consumed one supplied choice, and already owned
policies were ineligible. These are native modifier queries, not combat-damage
comparisons. Volunteer Army free units/upkeep and Arsenal production are separate.

## Native Resettlement founding

The same process passed eight assertions and exact replay for each of Rome and
Akkad. A normal pre-policy founding had1population,7claimed plots and no free
selected buildings. After legal policy adoption, two distinct normal Found
actions each produced5population,13plots and exactly one Workshop, Granary,
Aqueduct, Monument and owner-specific Library. Akkad received its Akkadian
Library through the native building-class resolver. Prior cities and the foreign
owner were unchanged; neither city received an unconfigured Worker. The chosen
clear radius-two sites deliberately provided room for all six extra claims.
Crowded/unavailable territory and other replacement parameters remain separate
boundary/applicability reviews.

## Retained commissioning failure

That four-stage process remains `failed-functional-checks`: Colonialism created
the Governor mansion, Worker, population and territory, then failed the test's
happiness assertion. The test called `GetHappinessFromBuildings`, which
`CvCity.cpp:11824` explicitly returns from the **unmodded** building counter.
Configured `Happiness=2` instead enters the base local counter and
`GetLocalHappiness`. Its observed unmodded0 did not establish a product defect.
The corrected test requires local2/unmodded0 and records both in the replay
snapshot; the Resettlement snapshot remains unchanged. The failed save is
retained with SHA-256
`5c94653ed7cc157c4a39bba11ee9bc5bc7ae229f48d1b89057603c670c70a967`.

The original run lasted223.5seconds, one aggregate ordinary turn, with normal
exit0, no Lua/synchronization/new crash diagnostics and full restoration.
`build/macos/policy-effects-preservation-20261003.json` verifies947baseline files.
The strict isolated-stage contracts preserve the batch failure and admit only
the three independently completed run/replay pairs, whose closed original/copy
checkpoint identities match. No incomplete Colonialism result is marked passed.

The binding preflight also caught an unavailable C++ getter name before launch;
Lua exposes it as `AirSweepCombatMod`. Neither test correction changes gameplay.
All research, prerequisite policy/branch flags, free choices, units/Settlers,
upkeep and staging are explicit inputs. The actions and rewards are native;
there is no physical mouse or naturally earned-prerequisite claim.

## Focused recovery

The corrected Colonialism stage passed all eight assertions and exact replay
in `20261003T011819Z`, 75.8seconds, zero ordinary turns and normal exit0.
Both post-policy foundings granted one Worker, one mansion,2local happiness,
0unmodded building happiness,3population and13plots. The pre-policy1population/
7plots/no-mansion/no-Worker and unaffected prior/foreign-city controls passed.
Independent preservation verified954baseline files, stock and no game process;
no Lua/synchronization/new crash diagnostics occurred.

Across the mixed batch and focused recovery, all32declared policy assertions
and four exact stage replays now have passing evidence. There is no claim that
the original full batch passed intact. G0 and final F/R acceptance remain open.
