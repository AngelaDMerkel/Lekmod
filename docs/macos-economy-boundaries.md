# Economy boundary checks on the current Mac

## Treasury and science queries

`20260918T064121Z` loaded the accepted turn-111 Huge-map fixture in a bounded
background test. Its ordinary income was -39 gold per turn and city science 24.
Only treasury balances were supplied as explicit inputs; no income rate, research
progress, technology, elapsed-turn or synchronization value was assigned.

| Supplied gold | Science deficit | Canonical science | General yield query |
| --- | --- | --- | --- |
| 139 | 0 | 24 | 24 |
| 0 | -39 | 0 | -15 |
| 1 | -38 | 0 | -14 |
| 38 | -1 | 23 | 23 |
| 39 | 0 | 24 | 24 |

The original zero treasury was restored. The test verified that every technology
count, known flag, progress value and research overflow remained unchanged.
The ordinary save and Exit confirmation callbacks returned process 0 with no
signals, Lua or synchronization errors. Hooks/settings/manual saves were preserved.
Save SHA-256: `577c234ed2ba6b1abb06a9cb45e51140e64369cb51fdb8c2cdc97e56fd3a0f5b`.
This is native query coverage with supplied balances, not turn settlement.

## EUI science display correction

Physical overview runs `060233Z` and `061609Z` showed a red `+-15` science HUD
on this same zero-treasury fixture. Standard UI showed No Science. EUI's HUD and
tooltip used `GetYieldTimes100(SCIENCE)`, which returns an unclamped aggregate.
`GetScienceTimes100` returns the rate actually cached for research settlement,
including its zero floor. Both EUI display paths now use that query; gameplay
yield rules are unchanged, and the deficit warning color remains.

The extracted real Lua HUD block and tooltip query fail the negative/fractional
floor cases before correction. All five cases pass afterward, including partial
deficit, positive science and zero without deficit. Thirty runner tests pass.

`20260918T064450Z` loaded the exact budget-test save with the corrected private
EUI package at 1024x768. The visible HUD displayed red +0. The read-only observer
simultaneously reported canonical science 0, general science -1500 and deficit -3900
in hundredths. No treasury or research mutation was made in this physical session.
The screenshot `eui-science-zero.png` has SHA-256
`388c50054cb048d285b8a129b7132e58deafdccbc79e4f32f279b91432526f99`.
A real science-HUD click opened the technology tree; actual Close returned.
Tooltip rate selection is offline coverage; no native tooltip-hover pass is claimed.

Actual Escape / Exit to Windows / Yes returned 0 after 138.5 seconds. Settings,
graphics, hooks and original manual saves were preserved, with no Lua/sync errors.
Wrapper `064441Z` restored standard payload, EUI text and options.

Private EUI archive: `Lekmod-eui-science-floor-20260918.zip`, SHA-256
`fc55a598707ef4b8e2f0e9aebe67aff4e4c1341a84f4d97e3113fa133881e855`.
Signed GameCore remains `cf5273574eb622c53b700d6a0dbfa1e2ff882f5475d4c9a486aa4cdac740e798`.
The archive includes uncommitted test/display changes and is an intermediate
local artifact. It is not the final release package; private EUI is not distributed.

## Ordinary deficit and recovery settlement

`20260918T065530Z` started a normal Ancient/Duel Rome game with two majors, no
city-states, barbarians disabled and religion disabled. The normal human driver
founded the capital. Supplied Museum, Opera House, Broadcast Tower and Airport
maintenance plus a zero treasury created -7 GPT and zero science. These buildings
were explicit test inputs, not earned Ancient-era construction.

One ordinary turn (0 to 1) retained gold 0 and every technology's known flag,
count, progress and research overflow. The supplied buildings were then restored
to their original counts and 100 gold was supplied. One more ordinary turn
(1 to 2) settled exactly to 103 gold and added 400 research hundredths to Pottery,
matching the quoted +3 GPT and four science. No technology completed, and no
temporary maintenance building remained. The save SHA-256 is
`574511e03f58fc064d98b15fa57b4acf24072fdbfe434ec62db2230a6e7f0e3d`.
Normal save/exit returned 0, preserved settings/hooks/manual saves and recorded
no Lua or synchronization failures.

Earlier attempts remain failed fixture evidence: `064910Z` asserted a capital
before normal founding; `065102Z` supplied insufficient maintenance (the Military
Base has zero maintenance in the shipped data); `065354Z` checked the next-turn
result before the ordinary driver finished its same-turn choices. The corrected
observer waits for the actual turn to advance and records supplied costs/rates.
It never changes GameCore wait flags, synchronization or elapsed turns.

This covers the treasury/science floor and positive recovery settlement. It does
not establish random deficit disbanding, every resource/happiness boundary or
other economic mechanics.

`20260918T065705Z` reloaded that exact saved state with all treasury, science,
research and building fields equal. Its normal save/exit returned 0 and passed
the same preservation and error checks. Reload-save SHA-256:
`c5b37c62e9f6406785066a47e68fc91bb044afd7abc9b9eefe6dfdea2f57c896`.
