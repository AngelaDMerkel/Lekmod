# Romanian city-acquisition reward

The trait promises golden-age points when capturing or liberating a city.
The original Lua handler awarded points to the new Romanian owner for every
CityCaptureComplete event, including peaceful city trades/gifts. The focused fix
uses the existing conquest argument to exclude peaceful recipient transfers.
A liberation disposition follows a real conquest; the conqueror earns its
capture award first, and the subsequent recipient transfer must not award it
again. The separately scoped native liberation checks below verify that ordering.

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
and the Yugoslav revolution regressions. The native gift/capture retest passed on the new clean package below. The fix does not retrospectively remove points from old saves; their
historical sources cannot be inferred safely from the current meter.

## Fixed-package retest

Fix `6d5788ed` is packaged from clean source
`ec9fb383fc360cc913ff961055518e8380be96c3` in
`build/macos/Lekmod-romania-acquisition-20260926.zip`, archive SHA-256
`bca29c261d01a81799ece151001dbc2eaefced4d33f1852b88dbd6a3ee16e785`.
Core remains `2dcc90942588da45f5c8c04d38aec131a33e3a07333075fdb03df63054c8abc1`;
payload SHA-256 `636ad673ef9b1662f71a617c2d4be5598695538972cffe314a9da0dee7bb82b4`.

`20260926T174746Z` exited255 before gameplay in20.5 seconds; no reward test ran.
Its localization cache is preserved and runner restoration passed. Independent
traced **`20260926T175250Z` passed all five assertions and exact reload**,112.2
seconds, one ordinary turn, normal exit0. The same real gift now adds zero points;
the real conquest still adds100, and the former owner remains excluded. All save
copies matched completed originals, with no Lua/synchronization errors/new diagnostic
and full runner restoration. Evidence: `build/macos/romania-validation-20260926.json`.

Native liberation is reported separately below.

## Native liberation in both roles

`20260926T181244Z` passed ten checks, two functional exact replays and the new
human-fixture baseline replay,175.8 seconds, zero ordinary functional turns,
normal exit0 with full runner restoration. A normal human Romania/Poland/Rome
fixture (`20260926T175541Z`, matrix `20260926T175536Z`) supplied the Romanian
liberator; the existing group8 fixture supplied a Polish liberator returning a
Romanian city. Each test supplies a legal third-party city under Roman occupation,
contact, uranium and a staged attacker. The actual attack and original Liberate
choice produce both ownership changes; no damage or reward points are supplied.

Romania as liberator earns100 at conquest and retains it when returning the city
to Poland. Poland as liberator earns zero; Romania as recipient also gains zero
when its city is returned. Both original living owners regain their cities.
Peaceful entry rejection uses an actually visible adjacent target and the API's
explicit destination flag. Each resulting state replays exactly.

The earlier `20260926T175830Z` attempt failed both stages before combat because
the harness queried a distant, unseen target without destination semantics; its
baseline replay passed. This was an invalid movement-preview assumption, not a
product defect. The source Lua binding takes numeric declare-war/destination
arguments. `20260926T180158Z` then hit startup255 in49.7 seconds before loading a
fixture; its healthy localization cache is preserved. The independent traced
passing run does not resolve that startup cause.

The reward round totals15 scoped native assertions/three functional exact replays
plus one new baseline replay. Copies of all recorded saves were independently
compared with completed originals. Final preservation confirms stock/no game,
original603 manual saves/quicksave/settings/backups and32 stock UI hashes.
Evidence: `build/macos/romania-validation-20260926.json`. Detailed wounded-combat,
golden-age culture and other Romanian unique effects remain separately scoped.
