# Mexico opening discovery validation

Scope: current Mac, standard UI, single-player human Mexico and AI Mexico on
separate teams; Tiny Pangaea, eight city-states, Ancient start, no barbarians.
No visibility, city ownership or elapsed turn was assigned by the test. Normal
setup, founding and PlayerDoTurn events supplied the gameplay.

## Native failure

`20260918T070031Z` began with no city-state cities. The first observed AI Mexico
PlayerDoTurn callback at turn 0 still had no minor cities. The old handler scanned
only existing cities and then removed its shared listener after that first
Mexico player. By the next human turn, all eight minor cities existed, but all
three nearby human targets (distances 8, 9 and 10) and the AI's target (distance
10) remained undiscovered. Eight distant controls remained hidden.

The run kept both functional failures even though diagnostic save/Exit callbacks
returned process 0. Its failed-state save SHA-256 is
`f1c8c9028e237c6ef92e267aeace14d027681eba9e4326d1ceb3c632c14bec7d`.
Settings/hooks/manual saves were preserved. The exact original product handler
is retained as `build/macos/Lekmod_mexico-before-discovery.lua`.

## Correction and native replay

The product now reveals nearby living minors' starting locations for every
living Mexico player during game initialization. When those actual minor cities
are founded during the opening turn, it refreshes their city visibility. Both
paths require elapsed turn 0, so later foundations or loads do not reveal more
cities. Distance remains greater than zero and at most ten; major players and
dead players are excluded. Reapplying the normal true reveal value refreshes a
new city's visibility without first resetting its plot. No persistent script-data
field, synchronization check or wait flag is changed.

Twelve isolated product-handler cases pass, including both Mexico owners, exact
distance 10/11, major/dead exclusions, missing starting plot/player guards and
later-foundation/load exclusion. The original handler fails five cases.

`20260918T070657Z` replayed the exact preserved initial save from the failing
world. Before any minor city existed, all three human-nearby starting locations
and the AI-nearby location were revealed. Their actual founding events then made
all four corresponding city views visible. All eight distant controls remained
hidden. One ordinary turn reached turn 1; no fixture mutation supplied visibility
or city creation. Save SHA-256:
`1066f56dcb2685a1921c0e2f807c402b10581a37358ef36182e2b0af1dc0117a`.
Normal save/exit returned 0 with settings/hooks/manual saves preserved and no
Lua or synchronization errors.

The source initial save is
`070031Z/autosaves-after/AutoSave_Initial_0000 BC-4000.Civ5Save`, SHA-256
`038fa2ab5118ea9b14474bec404d811ad4853f91ef6c63387e4ea965ecd47a3b`.

Exact reload `070926Z` matched the saved visibility but stalled after its Exit
confirmation. The supervisor sampled the process and terminated it with SIGTERM;
this remains a failed-shutdown run. It restored settings/hooks and preserved
manual saves. `071357Z` is a separate exact reload that passed and exited normally
(0), with the same preservation/error checks. Its reload-save SHA-256 is
`2e12b6199ee89086f587ca1be3f0bb79d85c470df571d30465aac93b8a0bb685`.
The shutdown issue is tracked separately in `macos-startup-cache.md`.

The managed intermediate standard archive is
`build/macos/Lekmod-mexico-discovery-20260918.zip`, SHA-256
`0daa7848a00162c6bb2cfdf176c322dcaa7260ef4d7e1346262014fe41022bd0`.
Signed GameCore remains
`cf5273574eb622c53b700d6a0dbfa1e2ff882f5475d4c9a486aa4cdac740e798`.
This includes the committed EUI science formatter and the then-uncommitted Mexico
correction. It is an intermediate test artifact; final clean release checks remain.

These are normal initialization/event outcomes and scripted observation, not
mouse input, multiplayer, the free Worker/tribute-influence abilities or the
Ranchero/Hacienda mechanics. Late saves with discoveries already missed by the
old handler are not retroactively awarded new visibility by this first-turn fix.

## Pottery Worker award

`20260918T072049Z` loaded the discovery save at turn 1, with both capitals and
Pottery unknown to both Mexico players. Pottery was supplied separately to each
team through the native technology API. The human's grant created exactly one
Worker while AI count stayed zero; the AI's grant then created exactly one Worker
while the human count stayed one. Re-sending already-known Pottery created no
additional unit for either owner. No Worker was supplied with InitUnit. Both
Workers had owner-local ID24576, so the recorded identity includes owner as well
as unit ID. Technology input is explicit, not earned research or mouse input.

The save SHA-256 is `783b89cd014b8ee3315f90ab52784402221aadc1d7a64e89872611344b7c2514`.
`072226Z` matched each owner's technology, Worker identity, position and movement
exactly on reload. Its save SHA-256 is
`3613e6ec8f678e11ae8ceec834d72324673b12e9bcd35d4ed19c1293a8c838e5`.
Both runs saved/exited normally (0), restored hooks/settings and preserved manual
saves, with no Lua/sync errors. The new initial-hook evidence feature retained
and hash-verified all 43 injected files in the action run. No product change was
needed for this award. Tribute-related influence and Ranchero/Hacienda remain open.

## Ranchero growth during production

`20260918T072920Z` supplied capital population 4, a Granary and stored food one
short of growth, then selected Food Focus and disabled Avoid Growth through
normal commands. The legal Ranchero production order was accepted; Mexico's
replaced base Settler was ineligible. Native `IsFoodProduction` stayed false.

One ordinary turn (1 to 2) grew the city from 4 to 5 while Ranchero production
advanced from 0 to 600 hundredths toward its 71-hammer cost. The unit remained
under construction; no completed Ranchero appeared. Food went from 28 to 4
after paying the growth threshold. These are scripted orders and native turn
outcomes with supplied growth prerequisites, not earned food or mouse input.
Save SHA-256: `35856d6864b2b58c3595c028a0cf85c583089fb364bb033fc369de80940eda42`.

`073243Z` matched the exact population, food, focus, production, Granary and
Ranchero-count state on reload. Reload-save SHA-256:
`75e5b8b2150a1c5abbc0c703e482210b856377422a5f7ac370538e6a0f7d791b`.
Both saved/exited normally (0), restored settings/hooks and preserved manual
saves, with no Lua/sync errors. No product correction was required. This checks
the Ranchero's distinct growth rule, not a completed training/founding sequence.

## Hacienda construction and resource classes

`20260918T075444Z` loaded the Ranchero fixture. Economics and the resource-reveal
technologies, two cleared forest/jungle plots, compatible wheat/cotton/iron/coal
resources, and production one hammer below completion were explicit inputs.
Resource placement used native compatibility checks and distinct owned plots;
no plot-yield value or completed building was assigned.

A normal Hacienda production order was legal; the replaced Windmill was rejected.
One ordinary turn (2 to 3) completed the Hacienda and emitted CityConstructed.
Wheat gained exactly one gold, cotton one production, and both iron and coal one
food. Every other measured plot yield remained unchanged. City base building
maintenance stayed unchanged, matching Hacienda's zero maintenance.
Save SHA-256: `d4e3aa8e7a2633f032ab4a2bcbd16a8ab236f15201203af838d554c79fd97d1d`.
`075847Z` matched the saved building, maintenance, all owned resource quantities
and plot yields exactly. Reload-save SHA-256:
`8dfd6dd069e7d8136745689ec0639eab878eec52164670a44c2c7e3c20972c7e`.
Both saved/exited normally (0), restored settings/hooks and preserved manual
saves, with no Lua/sync errors. No product change was required.

The earlier `073937Z`, `074200Z`, `074503Z` and activation-only `074705Z` attempts
failed during localization startup, before gameplay. Original-settings native
control `074840Z` reached the menu and exited normally; it is documented in the
startup investigation. `075215Z` then reached gameplay but had no eligible early
strategic-resource plot. The final fixture explicitly cleared two plots before
finding a valid assignment; this is supplied terrain, not worker-chopping coverage.

This establishes the four resource-class bonuses, normal construction and zero
maintenance. Capture/removal behavior and the remaining influence mechanic are
separate coverage; no broad Mexico-complete claim follows from these cases.

## Tribute eligibility and influence

`20260918T080340Z` supplied contact with minor 22, one Giant Death Robot on an
empty neutral staging plot, one uranium and an upkeep budget of 1,000 gold.
Friendship, tribute eligibility and influence rates were not assigned. Before
the military input, influence/rate were zero and tribute was unavailable. The
native military calculation then allowed tribute (score +90); Mexico's rate rose
to 750 hundredths under the shipped Quick speed's 125% GoldGiftMod.

One ordinary turn (1 to 2), with no tribute taken, produced the whole-point
friendship reading 7 expected from that quoted rate. The exposed friendship
getter truncates hundredths; no direct exact-fraction outcome is claimed. The
next rate was 625 hundredths after ordinary positive-influence decay.

The normal `Game.DoMinorBullyGold` command then paid its quoted 65 gold
(1020 to 1085), changed the whole-point influence reading to -7, removed current
tribute eligibility and left only the 125-hundredths recovery rate. The final
native snapshot also contains an unmet, tribute-eligible minor 26 whose influence
and rate remained 0; `unmet-influence-control.json` verifies that negative case.
Save SHA-256: `8e02d230673099c2d5e0c3ccb58ed6e4d20267e3b784f8a976276d644ab45f21`.

`080646Z` matched the exact saved treasury, every living minor's contact,
friendship/rate/eligibility/personality fields and human unit positions/movement.
Reload-save SHA-256:
`ca5b1a787c6d9182e274b99a135bdaa6b2db221d2162ba24e29f42246afeb7aa`.
Both saved/exited normally (0), restored hooks/settings and preserved manual
saves, with no Lua/sync errors. These are scripted setup/commands and native
turn outcomes; no mouse or earned military buildup is claimed. No product fix
was needed for these influence/tribute cases.
