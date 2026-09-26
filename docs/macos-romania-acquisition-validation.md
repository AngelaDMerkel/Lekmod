# Romanian city-acquisition reward

The trait promises golden-age points when capturing or liberating a city.
The original Lua handler awarded points to the new Romanian owner for every
CityCaptureComplete event, including peaceful city trades/gifts. The focused fix
uses the existing conquest argument to exclude peaceful recipient transfers.
A liberation disposition follows a real conquest; the conqueror earns its
capture award first, and the subsequent recipient transfer must not award it
again. This source-order reasoning still requires a separately scoped native
liberation check.

## Authentic gift and capture reproduction

Plan: `LEKMOD_DLL/macos/batch-plans/romania-acquisition.json`. It reuses the original
group8 turn2 save (`20260922T234507Z`, SHA-256
`7eeef6df14b51bcc7a21810c416b40695a3c54207c9543e7bce1df79dd48b9e0`):
human Poland0 and AI Romania4. Supplied inputs are two legal Polish cities near
Romania, contact, one Romanian attacker, uranium and upkeep gold. No golden-age
points, city ownership or damage are assigned.

`20260926T174026Z` used the unchanged Yugoslav package
`dd82a625671b290c2dd83cbb0d34c735c558384385b92ed220f29a488d72cf0f`.
The original city-selection/propose/AI-reply callbacks completed a real city gift
at peace. The actual CityCaptureComplete event had conquest=false, but Romania
received100 golden-age points (28→128). A subsequent actual AI-owner-turn attack
captured the second city with conquest=true and correctly added100 (138→238,
including ordinary happiness progress before that attack). The previous Polish
owner gained no Romanian reward in either acquisition event.

The gift-negative assertion failed; four other checks passed. The run remains
`failed-functional-checks`,87.7 seconds, one ordinary turn, normal exit0, no
Lua/synchronization errors/new diagnostic, and settings/UI/manual saves restored.
Report SHA-256 `a47aeb6580d286bbe275c6b486b18d69e6691c22249af5b78c4cc78e9284dcac`.
Checkpoint:
`build/macos/playtests/20260926T174026Z/checkpoints/Lekmod-Batch-20260926T174026Z-romania-acquisition-run.Civ5Save`,
SHA-256 `16cf134319d5e3784ddc1fdd302cbde52833cce04b0c5a9d57d5ea1d09877932`.
These are scripted UI callbacks and real native deal/combat outcomes, not mouse
interaction or an accepted functional replay.

## Retained harness commissioning failures

- `20260926T172547Z`: generic test trade dismisser overwrote the scenario callback;
  interrupted,178.6 seconds, cleanup required owned-process termination, exit-9.
- `20260926T172923Z`: moving the adapter to outer DiploTrade lost access to local
  TradeLogic deal/player variables; blocked-diplomacy,309.3 seconds, exit-9.
- `20260926T173612Z`: diagnostic attempt confirmed the context/request existed but
  the private variables were still out of scope; interrupted,187.3 seconds, exit-9.

No reward outcome was reached in those attempts. All three preserved manual saves
and restored settings/UI/stock. The second run's temporary read-only control probe
never executed because the scenario driver was suspended; it did not change game
state or wait flags. An early idle-gate hypothesis was not established. The final
adapter restores its original Game.IsProcessingMessages gate, logs processing=false,
and acts through enabled original controls/native trade legality checks.

The correct integration appends the action adapter inside TradeLogic and adds a
passive outer DiploTrade adapter so generic test dismissal cannot replace its
update callback. Original game input/show-hide/message handlers and synchronization
checks remain intact. Shared preflight commit `3f7e8484` now also parses all selected
UI adapters and prefixes before installation;26 dispatcher tests include real
Lua-parser rejection of malformed scenario/adapter/prefix files.

## Focused fix

The offline peaceful-transfer case fails before the conquest gate. All32 city/policy
callback cases pass after it, including four speed scales, unrelated/dead owners,
and the Yugoslav revolution regressions. Native retest on a new clean package is
pending. The fix does not retrospectively remove points from old saves; their
historical sources cannot be inferred safely from the current meter.
