# Post-removal trade event and Kilwa naval plunder

## Confirmed defect and correction

Native run `20260919T072202Z` used a Small/Archipelago/Industrial single-player
fixture: human Rome 0, AI Kilwa 1 and another Roman AI 2, with no barbarians.
Supplied inputs were legal coastal cities, a Harbor where absent, contact/range
reveal, an AI cargo ship and a human Privateer with an explicit staging position.
No route, gold reward, food marker or unit-loss outcome was assigned.

Kilwa created its sea route to player 2 during its real AI owner turn, using the
normal AI mission API. Its origin gained marker 1 and a 5% food modifier; other
cities and both Roman owners kept zero markers. The human's synchronized war
command against Kilwa left the unrelated AI-to-AI route and its bonus intact.
A normal human plunder action then emitted the native UnitPlundered event,
removed the cargo/route/capacity and awarded exactly 200 gold, as quoted from
the shipped sea-domain modifier and the native reward formula.

However, three stable post-action observations retained Kilwa marker 1,
modifier 105% and gross food 12.6 with zero routes. The overall test recorded
FAIL, saved the result and exited 0 without synchronization errors. No further
turn was requested after plunder; this is a stale marker/rate finding, not proof
of an excess food-storage award. Failed save SHA-256:
`a4fe7dea61a2ea54cf7f75f49386d3d06c6814f1852f67dd467fd58c991d1305`.

Both UnitPrekill and UnitPlundered occur before the connection is removed.
`CvGameTrade::EmptyTradeRoute` now emits
`TradeRouteRemoved(originPlayerID, destinationPlayerID)` after clearing the
connection and cached yields, updating both players' trade values and issuing
visual destruction. It reports player IDs, unlike the separate DeclareWar team
IDs. Kilwa's existing food refresh subscribes to this event. The creation-time
prekill and post-war refresh remain. No save format, route duration, reward,
movement or synchronization flag is changed. This event describes route removal;
it does not imply that every enclosing action's later effects have finished.

## Offline regression and native retest

`test-trade-removal-event.py` compiles the actual EmptyTradeRoute method under
ASan/UBSan. Its 57 cases vary owner pairs, present/absent/missing visualization
units, script-system availability and invalid indices. The callback verifies
that owner arguments retain their original values, connection/yields are cleared,
trade updates occurred and visual destruction was requested. Before: 27 missing-
event failures. After: all 57 pass. The actual Lua handler suite has 26 cases;
three new post-removal cases failed before and pass after. They verify clearing
stale counts, retaining other active foreign routes and refreshing only the origin.
These stand-ins are isolated checks, not native gameplay or graphics evidence.

The original initial save is
`072202Z/autosaves-after/AutoSave_Initial_0165 AD-1700.Civ5Save`, SHA-256
`e46a100ac5b1adfe543f58180edea5295e50c90f75183ef89b883126eeb60746`.
Fixed same-input run `20260919T073048Z` passed all five native checks. The new
hook logged origin 1, destination 2 and zero remaining routes. All three stable
samples now show marker 0, modifier 100% and gross food 12. The complete recorded
snapshot differs from the failed baseline only in those three AI city fields;
route/unit/capacity removal, 200-gold reward, other cities, wars and turn match.
Normal save/exit returned 0 after 87.4 seconds; save SHA-256:
`bdd748c647843d437e4b23d1cca86dd0610d0cfeb3e75568ad69e3b5eae98734`.
Exact reload `20260919T073425Z` passed with normal exit; save SHA-256:
`6fe77cb0d30a63702e1475ed692f2ab5f150622114087b1408da5168ace51aa1`.
Both restored settings/hooks/manual saves without Lua/protocol/synchronization
errors or new diagnostics. These are scripted commands and native outcomes;
no physical mouse interaction is claimed.

## Other removal paths on the changed core

Late-expiry regression `20260919T073644Z` used
`064632Z/autosaves-after/AutoSave_0182 AD-1785.Civ5Save`, SHA-256
`e825fb377de37aeeb55dfaae261b80d71b223aae67df678cb2b8aff9fa717e58`.
Normal loading finished into turn 183, with one contract still due at 184 and
two already returned caravans. One ordinary turn completed that final contract;
the post-removal event observed zero routes, all three caravans were at the origin,
markers/cargo were zero and capacity stayed 3. All five checks passed with normal
exit (0), save SHA-256:
`bb09b3ab7be8cd6186e411811ad3d038076dd52cc17c265b6c64fc4fcb90d1fc`.
This is a one-turn regression from a preserved late fixture, not a repetition of
the earlier full contract run or the closed long stability campaign.

War regression `20260919T073835Z` repeated the normal declaration from the
unrestricted three-route save. All three checks passed; its complete logical
snapshot exactly matches the preceding Lua-only war fix's `070417Z` result.
It exited normally and saved with SHA-256
`37a622716149a2d603bb1910564fdfdfdf49de8d6ca80a96e14bcd98d9744ca7`.
Both regressions preserved settings/hooks/manual saves without Lua or sync errors.

## Artifact and limits

The incremental build changed one C++ source file and passed ABI validation.
Archive `Lekmod-trade-removal-20260919.zip` SHA-256:
`f1e5dc58f79a2308c3e971529066d17edd513f1606b9f55a9fe29f9aab9db5cd`;
signed GameCore:
`7a4a5abb38928278e940bdd83ee05d234972d1ffceef4125d46b637e8c8fdca9`.
The package was built with this correction uncommitted and is not the final
clean release. Old failed saves remain preserved. Startup reliability and the
broader civilization/system ledger remain open; multiplayer is deferred.

Run `--scenario kilwa-sea-plunder --scenario-turns 6` on the preserved initial
sea fixture, with explicit `--mode single-player-smoke --turns 3 --timeout 600
--stall-seconds 240 --save-and-exit`. Only one ordinary turn was needed in the
accepted retest. `--expected-state` plus the saved result checks exact reload.
`kilwa-expiry` now accepts a late fixture with one to three remaining contracts
and additionally counts post-removal events; keep a three-turn bound for the
quoted late autosave.


## Preserved pre-fix save

`20260919T074043Z` loaded the saved failed plunder state with AI marker 1 and
zero routes at turn 166. One ordinary AI owner turn restored marker 0/modifier
100% at 167, with zero routes/capacity. This uses the preexisting PlayerDoTurn
refresh; immediate repair on loading an already-stale save is not claimed. The
run passed both checks and exited normally (0), preserving settings/hooks/manual
saves without Lua/synchronization errors. Save SHA-256:
`4b4ed1c227d646ab6b9d4eb338241db0a715ca79928b4856613e121ac6be0959`.
The food-storage values are recorded, but this compatibility check does not
isolate city growth modifiers or assert a food-accrual correction.

Exact recovered-state reload `20260919T074658Z` matched and exited normally
(0), with preservation checks passed and no Lua/protocol/synchronization errors.
Save SHA-256:
`9a35f3fd6ce97b812f252db6cdcc233a65f1b8926896cc2c14015ffdb2794c35`.
