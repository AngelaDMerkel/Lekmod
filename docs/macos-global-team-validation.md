# Single-player team callback ownership

The normal fixture `20261003T012818Z` uses one human Wales player0 and AI
Mongols player1 on team7, plus opposing AI Timurids player2 on team0. All slots
were configured before StartGame through the ordinary single-player setup API.
Initialization and founding passed in77.4seconds/two ordinary turns, normal exit0
and full956-file preservation. This is not multiplayer/hotseat/PBEM testing.
Fixture SHA-256: `8d352e069d418a8a1b9cd75d4f87ed41657214a1c81fd11c3ce8ddfd41086d9b`.

## Confirmed native failure

Run `20261003T013721Z` first reloaded the exact fixture and passed shared-team
Consulates: both Industrial adopters received2delegates, shared Modern advancement
changed both to3, and actual unrelated team0 era events left player0/team7 and
its teammate unchanged. The nonowner received0. All five assertions and exact
replay passed. The full batch remained failed for the following global handlers:

- Normal Timurids owner2/team0 capital had no Ulug building despite its configured
  unconditional capital grant.
- Human0 and AI1 Economic Union adoption gave no city marker.
- Subsequent normal human Found also missed the policy marker.
- Human0 policy adoption instead refreshed unrelated owner2/team0, adding its
  previously missing Ulug building.

The helper compared a Player object with a numeric owner ID, then matched the
number as a team ID. Ordinary fixtures whose player and team numbers coincided
hid the mistake. Genuine team research already used the team ID correctly.
This is a shared original-Lua routing defect, not a newly inferred ABI failure.

The batch completed in237.2seconds/2aggregate turns, native exit0,
no Lua/synchronization/new crash diagnostics and full957-file restoration.
Both failures were saved with closed writer/source-copy verification:

- `global-team-initial`: `975a10724f13d85a198c2c7a3bdd8050d7a89e4fce9a8411368bd376ad54bcb0`.
- `global-team-policy`: `a67fab63fda2de8bf558f0f860da73ba242c2c5d7d91ba9e2071f894056b13be`.

Original reports/checkpoints are under `build/macos/playtests/20261003T013721Z/`,
and the preservation proof is `build/macos/team-events-preservation-20261003.json`.
Original source is retained at `build/macos/global-dummies-before-20261003.lua`.

## Focused correction and required retest

Player callbacks now match `player:GetID()`. Research has a separate team
dispatcher which refreshes every member. A load callback reconciles derived
markers after civilization dummy policies initialize. Existing predicates,
multiple-row OR behavior, capital restrictions and original dummy-policy logic
remain unchanged. No configured global dummy grants free units during rebuilding.

Nineteen actual-Lua cases using pinned shipped rows pass; eight failed before.
The fixture includes owner0 in iteration, matching the native container and
avoiding the earlier plain-table `ipairs` false failure. It checks all four
configured tech predicates, dead/minor/barbarian/foreign controls, all three
Yugoslav branch combinations, switch removal, capture owner routing, repeat
callbacks and missing/stale load repair. Capture and some predicates are still
isolated evidence until native verification.

`global-team-fixed-regression.json` prepares41assertions/seven exact replays,
a30-turn aggregate cap and40-minute ceiling. It includes same-input team cases,
both authentic failed saves and existing Yugoslav adoption/revolution regressions.
The pre-fix initialization snapshot is retained instead of requiring it unchanged
after an intentional Ulug repair. Fresh normal founding must also be checked on
the new package. Native fixed results are pending; G0/F/R acceptance remains open.

## Interrupted qualification and fixture correction

`20261003T015353Z` reached the old policy save after passing earlier stage
assertions/replays, but its next-round driver repeatedly adopted policies and
then had no valid choice. The runner terminated its process (SIGTERM/SIGKILL,
return−9); the incomplete batch is not admitted as acceptance evidence. Settings,
UI, stock,963baseline files and no game process were independently verified.
The two marker-repair assertions had passed before the unrelated policy failure.

Source review traced the fixture's discarded native ideology tenets to retained
lifetime policy history. Native read-only diagnostic `20261003T021936Z` confirmed
the original human next-policy cost was−14,388,120 at culture3/free0/tenets0.
The new helper preserves native awards and checks exact debit/positive cost.
On the unchanged pre-global-fix package, it reproduces the same missing-marker
defect with valid next cost15/culture3. That run exited normally and preserved
972baseline files. The new authentic policy failure save is
`becd9a0688bc84fee4fe46745c35b893326c870791492fe8bb21db95dfab298f`;
the malformed `a67…` save is retained for diagnosis only.

The fixed regression now includes all affected policy tests:73assertions and
12replays,28aggregate maximum turns and40minutes. The two deterministic Yugoslav
cases retain8-turn caps, compared with their previously observed4/6turns. Both
original failed global states remain documented; valid-accounting policy repair
uses the new failure save and protects its culture/choice/cost fields. Normal
fresh founding on the fixed package already passed in `20261003T015024Z`,
79.6seconds, two ordinary turns, with Ulug1/foreign0 and full962-file preservation.
Full fixed acceptance remains pending.

## Corrected full regression passed

`20261003T022959Z` passed all73declared assertions and12exact replays in one
859.0-second process,15aggregate ordinary turns, normal exit0. All23checkpoint
source/copy hashes and closed-writer records were verified. No Lua runtime,
synchronization or new crash diagnostic was recorded; stock, settings, UI and
975baseline files were restored and verified.

The run includes both valid global old-save repairs/next rounds, shared-team
Consulates, all three Yugoslav ideology destinations, human/AI promotion grants,
Rome/Akkad Resettlement and Colonialism. Corrected policy snapshots preserve
free-tenet accounting, culture and positive next-policy cost across replay.
The earlier interrupted run and malformed fixture remain failed/diagnostic.

Package `build/macos/Lekmod-global-teams-fixed-20261003.zip`, SHA-256
`7325b13ec0873c055c38d4a8711a21478a11c4f930354299017f2d725d74e746`,
clean product source `aff628c29916fe714eba203e1925c35cd99d977b`; GameCore
`c8f1723c7588fdf54465781ebbca9d8de009e3e11c76ba6375b5200fd9687aa2`.
Independent evidence: `build/macos/global-policy-corrected-preservation-20261003.json`.
Native capital transfer, remaining configured consumers and final G0/F/R gates
remain separate work.

## Real capital-transfer boundary

`20261003T025118Z` passed six global-capture assertions and exact replay. An
actual AI2/team0 GDR attack captured human0/team7's original capital while its
second city kept the human alive. The surviving Welsh capital received its
capital-only marker and retained Economic Union. The captured noncapital had
no foreign or capital-only markers; Timurids kept Ulug in its own capital, and
the Mongol teammate's city-marker state stayed exact. One further ordinary round
preserved the results. No city damage, owner or reward was assigned.

That full six-stage process passed36assertions/six exact replays in426.6seconds
with16aggregate ordinary turns, normal exit0, no Lua/synchronization/new crash
diagnostics, all12closed source/copy checkpoint identities and998baseline files
verified. Stock was restored. It also refreshes the Vatican cases described in
[their report](macos-vatican-validation.md). Evidence:
`build/macos/capture-vatican-preservation-20261003.json`.

The twelve global assignment rows are now mapped using the common predicate
loop, all-row actual-Lua checks and these native representative/owner/transition
checks. Ukraine/Wheel and Colombia/Chemistry remain isolated parameter coverage
through that same implementation, not native civilization-specific runs. Each
dummy building's numerical effects remain separately in scope.
