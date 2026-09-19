# Incoming trade routes, 2026-09-19

## Native route creation and identity defect

Scenario `trade-incoming`, run `20260919T045912Z`, loaded the preserved internal
route fixture `20260916T080553Z`. Supplied inputs were one legally placed Belgian
AI city (Liege), a Caravansary, range reveal and two caravans. Both routes used
`MISSION_ESTABLISH_TRADE_ROUTE` during Belgium's real `PlayerDoTurn` callback,
with active-turn and eligibility checks. One ordinary human turn advanced
180→181. No route, yield, movement budget or wait flag was assigned.

| Route | Origin gold (hundredths) | Recipient gold | Recipient science | Turns left |
| --- | --- | --- | --- | --- |
| Liege→Rome | 515 | 250 | 100 | 19 |
| Liege→Antium | 473 | 200 | 100 | 15 |

Incoming and outgoing queries agreed on rates/countdowns, and the actual city
trade contributions were Rome 250 and Antium 200 gold hundredths (Cumae zero).
The real tooltip rendered incoming 2.5/2 gold and 1 science. These are rate and
command-outcome checks, not an isolated treasury settlement experiment.
The saved fixture SHA-256 is
`09fd83887d42b536ecd781f9d9126837d9331836566d947ae487d565aef4a4cd`.

The original three assertions passed, but inspection exposed another defect:
`GetTradeRoutesToYou` returned `FromCivilizationType=14` (Rome) for Belgian
owner 1, while the corresponding outgoing rows correctly returned 46. The
binding used the querying recipient instead of the already-resolved origin
player. The one-line correction uses `pFromPlayer->getCivilizationType()`.
The original report is retained with a separate `validation-notes.json`; its
narrow passing checks are not treated as complete route-data validation.
Standard overview icons use `FromID`, so this finding does not establish a
visible icon regression or an incorrect gameplay owner.

`test-trade-incoming-owner.py` extracts the actual four identity assignments
and runs 36 source/destination/civilization combinations under ASan/UBSan,
including distinct players sharing a civilization. Before the correction, 32
failed; afterward all 36 pass. These are isolated binding checks, not minor-civ
native gameplay evidence. Baseline output is retained in
`build/macos/trade-incoming-owner-baseline-20260919.log`.

Run `20260919T050333Z` read the affected saved fixture without setup mutations or
turn advancement. Native checks now verify both civilization types against real
owners and outgoing rows, plus the prior route rates and tooltip. Comparing the
complete recorded scenario snapshots shows exactly two changed fields: incoming
origin civilization IDs 14→46. Gold 2,217, turn 181 and all other recorded fields
are unchanged. Its save SHA-256 is
`7a9a4da8b9e6efc10ca76ccce482e7ebbfb1029fbe4f6096f5481ea8a3cc53ee`.
Exact reload `20260919T050453Z` passed; its save SHA-256 is
`093281494cdc1893f944c839f6452ac1ab443ad7e1a79b7b1fbd63d71e459669`.
The legacy `incoming-route-creation` check name on the read-only retest denotes
presence of the two routes; only `045912Z` contains fresh mission events.
All three runs exited normally (0), preserved settings/hooks/manual saves and
reported no Lua/synchronization errors or new diagnostics.

## Physical standard and EUI controls

Standard `20260919T050622Z` and EUI `20260919T051007Z` loaded the corrected save
at requested 1440×900. Actual CUA mouse input opened Trade Route Overview and
selected Trade Routes with You. Both displayed Belgian origins and Roman
destinations, with rounded origin gold 5.2/4.7, recipient gold 2.5/2, science 1/1
and remaining turns 19/15. Destination header clicks toggled Antium/Rome order
both ways; countdown header clicks toggled 15/19 and 19/15 while retaining the
correct row values. Close/reopen preserved the selected incoming tab and order.

Physical top-counter clicks exposed readable tooltips in both UIs: own food
1.75/production 3.5 and incoming Belgian 2.5/2 gold, each with 1 science. This
adds standard physical rendering and populated incoming evidence to the
[precision correction](macos-trade-tooltip-validation.md).

Actual Close → Escape → Exit to Windows → Yes exited both games normally (0),
after 195.0 and 182.8 seconds respectively. Each observer recorded one unchanged
state; no turns advanced and no save was requested. Settings, graphics, hooks
and manual saves were restored. No Lua/sync errors or new diagnostics appeared.
The manual runner's CLI result 1 means `ended-manual-ui-session`, not native
failure. Wrapper `eui-tests/20260919T050959Z` verified exact standard payload,
EUI text and options restoration.

| Run/screenshot | SHA-256 |
| --- | --- |
| `050622Z/standard-incoming-routes.png` | `8d0fc4448238a5682c61023654a5b04bc4901ad2abf00b85de87a80ab99c9c82` |
| `050622Z/standard-incoming-countdown.png` | `689896107a539b8b6372e3ee79492d02be860e5ed97fb92bb72586d1d4083bbe` |
| `050622Z/standard-incoming-tooltip.png` | `5d02834a281c4f81f7350fbe468f675aaf7ad594d4d2ebcb424ad29f87cff57f` |
| `051007Z/eui-incoming-tooltip.png` | `37bf531a60c06b9acbe8545be4e692fef9ec8fb1c5ff721c0fb0bc2f132e5e6e` |
| `051007Z/eui-incoming-countdown.png` | `e29b786b6c9118c33c39f46d1044644ebdf3e8980aa9708b2aecce2e17caf022` |

Evidence lives under `build/macos/playtests/20260919T…`, with physical actions
in `physical-overview-events.json` and `physical-completion.json`.

## Artifacts and remaining limits

The source-only incremental build passed ABI checks and produced standard
`Lekmod-incoming-owner-20260919.zip`, SHA-256
`820ca7ca27bd1aeb9dddb3b716a8d8ce6c18d0835339a9cc313f16b6129b767f`.
Signed GameCore:
`2995cf0267255023fb1f98517291c7070d8ee2ea3046b57c4b5611852a0104e7`.
Private paired EUI archive `Lekmod-eui-incoming-owner-20260919.zip`:
`50c825b9e0d99416f6dbb7c5082865a089c4d474266026850f316523b7ca8e14`.
The intermediate packages were built before this correction's commit and are
not final clean release artifacts. The private dependency is not redistributed.

This closes the two-row incoming-table workflow at this display size, alongside
the earlier own/available-table checks. Dense incoming scrolling, nonzero
religion/tourism data, additional languages and foreign Great Work exchange are
not covered here. Full single-player coverage remains open in the expanded ledger.
