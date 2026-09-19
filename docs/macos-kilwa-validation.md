# Kilwa route food bonus, 2026-09-19

## Native creation, accounting and food settlement

Scenario `kilwa-routes`, accepted run `20260919T062930Z`, loaded a preserved
Industrial/Duel/Continents opening with human Kilwa and Roman AI slot 1, no
city-states. The starting Settler used the normal Found action. Supplied inputs
were one legal secondary Kilwa city, two legal Roman cities, an origin
Caravansary where absent, contact/range reveal and three caravans. City production
used normal Wealth orders. No marker, food, yield or trade outcome was assigned.

Each route used `UI.SelectUnit` and the exact synchronized
`Game.SelectionListGameNetMessage` mission used by the trade popup's Confirm
handler, with normal active-turn/readiness and eligibility checks. This is
scripted network-command and native-outcome evidence, not physical popup input.

| Capital state | Marker count | Food modifier | Gross food | Food difference |
| --- | --- | --- | --- | --- |
| No routes | 0 | 100% | 10 | 4 |
| One outgoing international route | 1 | 105% | 10.5 | 4.5 |
| Two outgoing international routes | 2 | 110% | 11 | 5 |
| Plus one outgoing internal food route | 2 | 110% | 11 | 5 |

The internal route's native origin gold was 400 hundredths, matching Kilwa's
four-gold ability, while its destination food was 175 hundredths. It did not
increase the international-route marker. The secondary Kilwa city and all Roman
cities kept zero markers. Base food stayed 10 throughout the capital checks.
No product handler was called directly; normal route/unit events updated it.

One ordinary turn (165→166) stored exactly 500 food hundredths, matching the
pre-turn native FoodDifferenceTimes100. Population remained 3, below the 1,600
hundredths growth threshold. The repeated owner-turn callback retained marker 2
without stacking. All six checks passed, followed by normal save/exit (0) after
79.2 seconds. Settings/hooks/manual saves were preserved, with no Lua errors,
protocol errors, synchronization failures or new diagnostics. Save SHA-256:
`4e6cb4ab905dda16f6a98bf86aba58f1a38f81a80ec5f15ba54d81009049e794`.

Exact reload `20260919T063128Z` matched both owners' city/route snapshots,
including food storage, population, markers, rates, countdowns, gold and capacity.
It exited normally (0) after 56.9 seconds with preservation checks passed. Save
SHA-256: `bf9fe0c56dfd48a86faa23da8ed7e2361b379875fb58b3656ddac2c799141f0a`.

## Reproducible input and retained failures

The initial save is
`build/macos/playtests/20260919T062052Z/autosaves-after/AutoSave_Initial_0165 AD-1700.Civ5Save`,
SHA-256 `0188f0f85281832ab5a71eb8f758f911531fffe6d51566c31f5a8268324d5ce7`.
Run with `--mode single-player-smoke --turns 3 --timeout 480 --stall-seconds 240
--scenario kilwa-routes --scenario-turns 2 --load-save` pointing to that file,
plus `--save-and-exit`. For exact reload use the accepted saved fixture,
`--scenario-turns 0` and its report as `--expected-state`. The new-game path
accepts human `CIVILIZATION_KILWA`, slot 1 `CIVILIZATION_ROME`, Industrial era,
Duel/Continents, two majors and zero minors. Thirty-two runner tests pass.

Earlier attempts remain failed:

- `062052Z`: driver assumed a capital already existed. It was corrected to use
  the starting Settler's normal Found action; no Kilwa ability had been tested.
- `062332Z`: founded/prepared the same initial world, but the scripted trade
  popup request did not complete. That fresh-opening adapter path remains
  unverified; the later mission test is not a popup pass.
- `062653Z`: direct human `PushMission` calls triggered three explicit protocol
  errors because they were outside a game-network message. The synchronization
  guard stopped the run. Its intermediate PASS records are **not accepted
  gameplay coverage**; `validation-notes.json` states this explicitly. The driver
  was corrected to the ordinary synchronized message; no guard or GameCore wait
  flag was changed.

All three stopped with supervisor termination (-9), and restored temporary
settings/hooks/manual saves. They are not normal-exit or successful scenarios.
Only `062930Z` and its exact reload support the accepted native claims above.

## Scope and artifact

No product correction was needed for the creation/settlement checks above. The earlier
17 isolated utility/handler cases remain offline evidence. Native AI-owner,
sea-route, expiry/plunder removal, city-transfer and other Kilwa unique mechanics
remain open. Four-gold route accounting is verified; its isolated treasury
settlement is not claimed by the food-store test.

Installed standard archive `Lekmod-greatwork-swap-20260919.zip` SHA-256:
`014077403f0f6d991f4ff27a5b42955bb2cf3bdbceda9c4239275780da4add0f`;
signed core `689df45d69b4b772e408155c4f443d09ad6a936039205cee6e62747fd8cca3d6`.
This remains the documented intermediate artifact. These tests changed only
temporary drivers and recorded fixtures, not the product package.


## Natural expiry with controlled single-player options

The first expiry attempt, `20260919T063743Z`, loaded the accepted three-route
save at turn 166, with quoted completion turns 180/184/180. Through turn 171
all three remained active and markers matched. Rome then declared war; the
scenario correctly rejected the early disappearance of foreign contracts. The
war log and `validation-notes.json` retain that interruption. The run stopped
with -9 and remains failed, not a natural-expiry result.

A separate fixture used `GAMEOPTION_ALWAYS_PEACE=1` and
`GAMEOPTION_NO_BARBARIANS=1` through normal single-player setup. The shipped
Always Peace option is hidden in the ordinary UI but explicitly supports single
player; its use here is a labeled test input, not multiplayer coverage. The
runner accepts that known boolean option while continuing to reject multiplayer
turn settings; all 32 parser/guard tests pass. Native `064355Z` confirmed both
flags true and passed the six route/food checks again with normal exit/cleanup.
Its save SHA-256 is
`1463c9a99c6e093e7ab236dd4a9cdeecc600a7e21eae1016427cc89b4b224a7b`.

`kilwa-expiry`, run `20260919T064632Z`, followed only those contracts from turn
166 through 184, bounded to 19 ordinary turns and a 900-second recovery timeout.
No duration, marker, yield, return-unit or synchronization flag was assigned.
The countdowns continued to match their original quoted ends. Two contracts
ended at 180, leaving one foreign route and marker 1. The final route ended at
184; both city markers became zero and food modifiers returned to 100%. No
stable marker/count mismatch was observed. All three caravans returned to the
origin city, with occupied capacity still 3. The former internal food cargo
cleared; final food/production trade contributions were zero. This is a bounded
contract lifecycle test, not a reopened long stability campaign.

All four assertions passed, with normal save/exit (0) after 304.9 seconds.
Settings/hooks/manual saves were preserved, with no Lua/protocol/synchronization
errors or new diagnostics. Save SHA-256:
`e49e99bf228ca9453cdfee3435b10a730c8c335760773f43491e489cd5e3f724`.
Exact zero-turn reload `20260919T065236Z` matched options, zero routes/markers,
city food/yield/population states, three returned caravans, capacity and gold.
It exited normally (0) with cleanup verified; save SHA-256:
`4359ede75061922f832be49e7989b5e5951e74cf8937d941591f949f01b178e9`.
No product correction was needed. AI/naval/plunder/war and other unique-content
boundaries remain separate from the natural-expiry evidence.

Reproduce with `--mode single-player-smoke --turns 3 --timeout 900
--stall-seconds 240 --scenario kilwa-expiry --scenario-turns 19 --load-save`
pointing to the `064355Z` save, plus `--save-and-exit`. The scenario requires the
explicit peace/no-barbarian fixture and verifies its options again on reload.


## War cancellation: stale food modifier corrected

The unrestricted pre-war save `062930Z` supports a separate zero-turn cancellation
check. Baseline `20260919T065839Z` submitted the normal synchronized
`Network.SendChangeWar` command. Both foreign routes and the attacker's two
caravans were removed; the internal food/four-gold route and its caravan remained.
However, three successive stable observations at turn 166 retained capital
marker 1, modifier 105% and gross food 10.5 instead of 0/100%/10. The run recorded
the marker assertion as FAIL, saved the result and exited 0; the overall test
remains failed. No turn advanced, so this proves a stale rate/marker, not an
excess food-storage award. Failed save SHA-256:
`e33d388cf0f7bd990b45bf7878ef8c6e7a488308f838af99116aed2448547060`.

`UnitPrekill` runs before its route is cleared, so the existing callback can
observe the last soon-to-be-cancelled connection. The native `DeclareWar` event
runs after cancellation. The product now refreshes Kilwa players belonging to
either affected **team**, preserving the alive/civilization checks in the
existing ability function. It does not treat team IDs as player IDs.

The actual Lua utility/handler suite now has 23 cases. Six new cases failed before
and all pass after: stale prekill count followed by cancellation, internal-route
exclusion, all owners on a matching team, unrelated teams, non-Kilwa participants
and dead owners. Inactive civilization registration remains covered. Native
war testing here is the human attacker case; multiple owners sharing a team
and other owner exclusions are isolated Lua evidence.

Fixed same-input run `20260919T070417Z` passed all three checks, with marker 0,
modifier 100% and gross food 10 across all three observations. The complete
recorded before/after snapshots differ only in those three capital fields;
stored food, route/cargo, caravan, occupied capacity, war and turn are unchanged.
Normal save/exit returned 0 after 61.0 seconds. Save SHA-256:
`df23b6658214de0ecc8daba455ba6b24cccb96ea621bbdc42feafd40d740fc2d`.
Exact reload `20260919T070759Z` passed, save SHA-256:
`0a791ea12962faf0db2daa2e68af1bf3cd44b8582f94969de897025f15fbb94c`.
Both preserved settings/hooks/manual saves without Lua/protocol/sync errors or
new diagnostics.

Affected-save continuation `20260919T070930Z` loaded the preserved failure save.
It initially retained marker 1, as serialized. One ordinary turn (166→167) let
the preexisting PlayerDoTurn handler clear it; all owned city markers became
zero, with the internal route still carrying 175 food/400 gold hundredths and
13 turns remaining. No marker was assigned by the test. This is backward-save
playability and ordinary-turn recovery, not immediate repair on load or a new
food-accrual fix. It saved/exited normally (0) with cleanup verified, save
SHA-256 `72752d1bf58aec1f70743e709acf705c21ffb8ceae521f668724ce4d66a56bce`.

The new intermediate standard archive is `Lekmod-kilwa-war-20260919.zip`, SHA-256
`e4d8d01a89b8cdce9cf1420eac61bb94c0a0dbfd151b770acd1396473aefc13c`.
The signed core remains `689df45d69b4b772e408155c4f443d09ad6a936039205cee6e62747fd8cca3d6`;
the product change is Lua-only. The package was built before this fix's commit
and is not the final clean release.

Reproduce fresh cancellation with `--scenario kilwa-war --scenario-turns 1`
using the unrestricted `062930Z` save; the single allowed turn enables ordinary
notification handling but the scenario requests no turn. Use
`--scenario kilwa-war-continue --scenario-turns 1` for the affected `065839Z`
save. Both use the common explicit smoke-mode/time-budget/save-exit options.

Exact recovered-state reload `20260919T071156Z` also passed with normal exit,
settings/hooks/manual preservation and no Lua/synchronization errors. Save
SHA-256: `87aee9631f16269686dfb7527bbe2c43b1b2d1d95bb79ae030601d8e3db5c729`.
