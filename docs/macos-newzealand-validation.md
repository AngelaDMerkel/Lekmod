# New Zealand native contact rewards, 2026-09-19

## First contact through ordinary movement

Run `20260919T120139Z` used an Ancient/Standard/Pangaea single-player opening
with human New Zealand in slot 0, AI New Zealand in slot 1, ten Roman controls,
no city-states, Always Peace, no barbarians and no ruins. Its initial duplicate-
civilization crash and correction are documented separately in
[the player-color report](macos-player-color-validation.md).

A supplied human Scout and AI Warrior started at an isolated three-tile sight
boundary. Their creation did not cause contact. One normal synchronized human
movement reduced the separation to two, triggering the actual engine TeamMeet
event and mutual contact. Both New Zealand owners received exactly 12 science
in overflow, with no technology selected. All ten unrelated Romans' gold,
faith, culture and overflow stayed unchanged. No product Lua callback or
TeamMeet event was invoked manually for this movement check.

## Engine contacts and random reward branches

Twenty further first contacts were explicitly supplied through the native
`Teams:Meet` API, one per New Zealand/Roman pair. Each emitted exactly one
engine TeamMeet event, affected only the correct New Zealand owner, and drew
one of the four real rewards: 40 gold, 10 faith, 6 culture or 12 science.
No RNG function, seed, result, reward balance or synchronization flag was
changed by the scenario. The runner's ordinary fixed setup seeds were retained.
These are native contact/reward integration checks, not twenty naturally
explored encounters or mouse interactions.

The naturally drawn reward counts were:

| Owner | Gold awards | Faith awards | Culture awards | Science awards |
| --- | --- | --- | --- | --- |
| Human New Zealand | 3 | 3 | 2 | 3 |
| AI New Zealand | 1 | 2 | 3 | 5 |

Final human balances were 120 gold, 30 faith, 12 culture and 36 overflow science;
AI balances were 40 gold, 20 faith, 18 culture and 60 overflow. No current
research was selected, so this checks the overflow branch specifically.
The existing isolated handler tests cover the selected-research branch;
its live native completion/overflow boundary remains separate.

Calling the engine Meet API again on the known New Zealand pair emitted no
new event and changed no balance. A genuinely new Roman/Roman contact emitted
one native event, with no reward to either Roman or either unrelated New Zealand
owner. The complete twelve-player mutual-contact matrix was recorded.

## Persistence and evidence limits

All five reward checks and the twelve-color check passed on turn zero, with
normal save/exit (0), settings/hooks/manual-save preservation, no Lua/sync errors
and no new diagnostics. Save SHA-256:
`851b8c32390b2e93ecb0213c444fe2bb9e2d94590be7f84165fa57262c7dd69d`.
Exact zero-turn reload `20260919T120411Z` matched every recorded balance,
civilization, color and contact, then exited normally with the same cleanup.
Reload save SHA-256:
`83d6c91943ade95eaacd4c71d4a037884704f41f1e472714cc8020050ee2de9e`.

Reproduce with `--scenario newzealand-meeting --scenario-turns 1` and the normal
setup above, including explicit Roman `--slot-civilization` arguments for 2–11.
Use `--mode single-player-smoke --turns 3 --timeout 480 --stall-seconds 240
--save-and-exit`. The turn allowance supplies ordinary popup handlers; no turn
was requested. Exact reload uses the saved file/report with zero turns.

The tested package is `Lekmod-player-color-holes-20260919.zip`, SHA-256
`9d31987e6fc86240d7c113b3c76dfb2af788f36b72716a4cf6b0d6923c4ac91a`,
signed core `4e1a94b9ea8c61c16e18e2bc32a6f46a54941c056bb804b14cfd4c8066bc764b`.
No New Zealand gameplay change was needed. Battalion influence, Defender
radius/friendship behavior, selected-research rewards and city-state contacts
remain distinct native cases; this is not full civilization certification.
