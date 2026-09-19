# Māori movement expiry

Current Mac, standard UI, normal Ancient/Tiny Pangaea with human/AI Māori and
Roman AI control, no minors, and normal no-barbarians/no-ruins options. Supplied
Warriors, Workers, Scouts, one human Triplane and 1,000 upkeep gold per owner
are labeled inputs. The scenario never assigns promotions, movement, turns or
synchronization flags. Probes observe native movement/sight state; this is not
a mouse-driven travel-distance test.

## Native defect

`20260918T235446Z` passed initial human/AI +2 movement/+1 sight checks, recon/air/
Roman exclusions, and promotion/limit expiry at turn five. Newly supplied
Warrior/Worker units on turn five received the bonus normally. On turn six
their promotions disappeared and their limits fell to two moves, but their
remaining movement did not match. The assertion failed and the supervisor
stopped the process (−9); this remains a failed run. Its original settings,
hooks and manual saves were restored.

`20260918T235949Z` replayed the preserved post-turn-five autosave and sampled
two distinct updates at turn six. Both units had `moves=240`, `maximum=120`,
`sight=2` and neither Māori promotion. The mismatch persisted without any
scenario-side movement setter. It saved and exited 0 while retaining FAIL.
Save SHA-256: `eb8ca5a63ff91cbfd9d02741dcc4182d42dfdc80fe04560c9bee08c879116c07`.

Reusable initial autosave SHA-256:
`747c1c6197ec5e7661a0912634f9bb98acc459d91806f31231051dabbbd7ea3b`.
Post-turn-five autosave SHA-256:
`4a397e3374bf8378689d266e525f14599bc6955fcc8b1addd9ba301df1d03eb8`.
Both are under `build/macos/playtests/20260918T235446Z/autosaves-after/`.

## Correction

The engine resets movement when the previous owner turn ends. The next
PlayerDoTurn callback then removed Māori promotions without reducing the
already refreshed budget. The product handler now first removes every expired
promotion, then reduces excess movement to the current allowance. Two passes
ensure an escort processed later cannot supply its own expired bonus. Spent
movement is never increased and units without the expired promotion are untouched.

A new read-only `Unit:MaxMovesWithStack()` binding returns the maximum of native
movement and applicable Great General, embarked or land-civilian stack allowances,
matching the ordinary reset's movement calculations. It does not reset movement
or change activity, missions, synchronization or waiting state. Twenty-four actual
Lua-handler cases pass (including birth-turn, later-era and owner cases); 22 real-Lua sanitizer
binding cases pass across enabled/disabled land-stack configurations.

The optional-method guard keeps older DLLs from raising a missing-method Lua
error. The movement correction requires the updated core; an older DLL retains
its old budget behavior. No object layout or save field changed. The changed
Lua binding header was followed by a full rebuild and successful ABI validation.

## Fixed native diagnostic

`20260919T001109Z` replayed the exact post-turn-five fixture on the correction.
Both independent observations now show `moves=120`, `maximum=120`, `sight=2`
and no Māori promotion. It saved and exited normally (0), with cleanup, manual
save preservation and no Lua/synchronization errors verified. Save SHA-256:
`053bdce2917d664961cc7bb72a693d5d28d1ea6825ac478e1eb183e13d91d9a2`.

The first full retest, `20260919T001246Z`, confirmed correct turn-five movement
for the Warrior and Worker, then failed an overbroad new assertion on a Scout
that had spent its moves exploring. That report remains failed. The test now
asserts remaining movement only for eligible expiring-bonus units; recon/air
controls continue to check their unchanged limits, sight and promotions.

The supplied-unit replay `20260919T001506Z` passed all six checks through turn
six and exited 0 (save `c20663993e68ec98d3757853c594b9f94ac913544ba06b02e5abe074556736c3`).
Native escort run `002229Z` retained Worker movement 180 with raw limit 120 and
General movement 300 with its escort-inclusive limit 300. `002505Z` reloaded
that state exactly; both exited 0. Escort save/reload hashes:
`152425a6cab6816810a9ed96e08d4a32705f2c643c2881c6afd2da6ff5aea197`,
`177549533c56940830372c303b25a08de5b5233e6c033abc94b2cea3e79d74dc`.
Earlier escort fixtures failed because owned tiles were occupied (`001734Z`)
and because the test assumed General maxMoves excluded its escort (`001933Z`).
Those reports remain failed; product code was unchanged for these corrections.

## Normal production and pause point

`20260919T002712Z` used a legal production order and supplied production one
hammer short of completion. CityTrained created the Māori Warrior on turn
seven with its bonus, but the same turn's expiry callback removed it before
its first playable state. The failed state saved/exited 0, SHA-256:
`a20d7fb11569e6b92e335e5ca291719247c94a94e9c36acf4750fadc9d6644a9`.
The handler now excludes units whose creation turn is the current owner turn.
Two birth-turn regression cases fail before this guard and pass after it.

`20260919T003228Z` passed normal production: turn seven retained four moves and
sight three; turn eight expired to two moves and sight two. Save SHA-256:
`e9af97be2ca7447333dbfe05060852ebd8d58bf17ea334447779840dd0d5d2d3`.
It exited 0 with settings/hooks/manual saves preserved and no Lua or sync errors.
This used `build/macos/Lekmod-maori-birth-expiry-20260919.zip`, SHA-256
`f262c143b3c0519f07c01620d8fdc622b4ed5880ec2e187bb0e8c8bf6f20bcd4`,
with the same signed core below.

The user paused testing and requested stock restoration, which was verified.
Testing resumed on 2026-09-19 at 02:37 UTC with the same identified package.
`20260919T023734Z` exactly reloaded the normal-production snapshot and exited 0,
with hooks/settings/manual saves preserved and no Lua/synchronization errors.
Reload-save SHA-256:
`abd9c74c90c74c0741a1125c848326c8f13a6bd9e2019ecd0932a92f634fdd61`.

## Later-era opening window

Normal Classical setup `20260919T023914Z` began at calendar turn 33 and elapsed
turn zero. Two supplied land probes had the bonus initially, then lost it at
calendar turn 34 after just one elapsed turn. The script incorrectly compared
the opening window against the calendar counter. This run saved/exited 0 but
keeps its failed verdict. Save SHA-256:
`c3d826ec6d167de4efd461dab70bc476c94f237a20488f872da9b626545dce53`.
Its normal initial save has SHA-256
`520457368476e22601ee137927a1ea55dfcaf9d79f597d1790eeac367d99b48f`.

The opening window now uses `Game.GetElapsedGameTurns()`. Individual unit age
continues to compare `GetGameTurnCreated()` with the calendar turn, keeping
normal-production first-turn protection independent of starting era. Two new
isolated opening-window assertions fail before this correction; all 21 expiry
cases pass afterward, including elapsed-five expiry and a newborn at that boundary.

`20260919T024338Z` replayed the same initial Classical map. The probes retained
+2 movement/+1 sight throughout elapsed turns 0–4 and expired normally at
elapsed turn 5 (calendar turn 38). No counter, promotion or movement value was
assigned by the scenario. It saved/exited 0 with restoration and no Lua/sync
errors. Save SHA-256:
`2912f7118f5a62e6bfc18dabfba1b02f2c3f71957bd50d7f38ec883a8c123da0`.
`20260919T024539Z` reloaded that exact Classical state, including elapsed/calendar
turns, all observed unit types, creation times, movement, sight, promotions and
positions. Reload-save SHA-256:
`83fb19178af2557df61bd298d7411a677a9c284b6a8bf2231dc961a41673d479`.

Final Ancient replay `20260919T024720Z` used the preserved initial map with all
three corrections installed. All six checks passed: human/AI opening limits,
recon/air/Roman controls, ordinary human turn-five budget expiry, late unit
creation, next-turn budget expiry and AI expiry. Save SHA-256:
`f5a0999b7528ceb9a5c1ea49d539153d4e699771d4f45ce58e11af9afefbb444`.
`20260919T025044Z` exactly reloaded all three owners' observed unit states.
Reload-save SHA-256:
`1a875dfaefcc7d37a1af88a4e2b8ffab5a55879895599354e0a43b93a8da2cf0`.
All three runs exited normally (0), restored settings/hooks and preserved manual
saves, with no Lua/synchronization errors or new diagnostics. The accepted long
campaign remains closed; these are bounded functional regressions.

Current intermediate package:
`build/macos/Lekmod-maori-opening-window-20260919.zip`, SHA-256
`f750e49ec4f4de98e9fe5f28396983aae2d8db43d42338ffea85fbcc187583ac`.
Only Lua changed after the full build; the signed core remains the hash below.

Intermediate package: `build/macos/Lekmod-maori-expiry-20260919.zip`.
Archive SHA-256: `acff3463ddfa4c248a32fe373db7ed12664f550f70c5c33e27ab4202ad5c34ae`.
Signed installed core: `80a9ec3f54b96485606228c067f3656e727c2bf6b16c2c977cbf6c19bb85b8c1`.
The central installer preserved the stock backup. This dirty-manifest test
package includes prior religion/Tonga fixes and is not the final clean release.
Upgrade/capture ownership, other Māori uniques, sea-unit creation and actual
movement-path outcomes remain separate coverage.


## Gifted-unit expiry

`20260919T030214Z` used three actual gift actions after supplying units, peaceful
contact and staging positions: a Warrior to the Māori AI, then a Warrior and
Worker to Rome. Native UnitConverted events and source removal verified the
transfers. After both recipients' real turns six and seven, the Māori unit had
expired, but both Roman units retained their temporary promotions, four-move
limits and sight three. Their inherited creation turn remained six. The owner
civilization filter prevented the temporary state from ever expiring in Rome.
The failed state saved/exited 0, SHA-256:
`0a24143b5068993fd0c2127204c9f8f09597edc4d439e4609fc5fdfe196a6f79`.
The earlier `025740Z` attempt failed during startup; no gift action ran there.
See the [startup report](macos-startup-cache.md) for the preserved cache and
intro-setting comparison.

Expiry now follows the inherited promotion for each living owner, preserving
the same opening window and first creation turn. Units without the temporary
promotion remain untouched. The isolated suite now has 24 cases; foreign and
non-major expiry cases fail against the former owner filter. Non-major handling
is isolated evidence, not a native city-state/barbarian gift test.

`20260919T031132Z` replayed the three gifts on the correction. Both recipients'
units expired after the observed ordinary owner turns, and all three checks
passed. Save SHA-256:
`2a1fc3f7fa67b6ff69681ddc7767fddc60f7ec541aa69d925d21b60344d56226`.
Exact three-owner reload `031848Z` produced save SHA-256
`15ac61c5767577f4cd69f536b61de10a54d216665d96f3435e68cd3499617a63`.
The native replay retained the baseline's intro-enabled setting; reload used
the usual intro-skip setting and also started successfully. This does not
resolve the intermittent startup issue.

`20260919T032022Z` loaded the retained affected save. One ordinary Roman turn
cleared both stale bonuses; their limits/remaining movement became 120 and
sight two. No test-side movement/promotion or turn assignment was used.
Save SHA-256: `d9c024e0b7ad9d696cd20f1326edbc6f693f864e22b3ada70f03c6fc876eb7b8`.
Exact repaired-state reload `032226Z` produced
`593009b6bf975eaea1ac2956fce70d05915ad1f4923a7f358475f0676b58f14f`.
All four successful runs exited 0, restored settings/hooks and preserved manual
saves, with no Lua errors, synchronization failures or new diagnostics. These
are scripted gift commands and native outcomes; no mouse input was used.

Latest intermediate package: `build/macos/Lekmod-maori-owner-expiry-20260919.zip`,
SHA-256 `9d089034c691def6596acf7ef8af02eee9cfd7b641e92e022c8278197d7aa46e`.
The signed GameCore remains
`80a9ec3f54b96485606228c067f3656e727c2bf6b16c2c977cbf6c19bb85b8c1`;
this follow-up changed Lua only. This is not the final clean release package.
