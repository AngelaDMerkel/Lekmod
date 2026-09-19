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

No Kilwa product defect was confirmed or changed in this phase. The earlier
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
