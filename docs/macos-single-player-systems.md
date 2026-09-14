# Single-player system validation continuation

Scope: standard UI on macOS 26.5.2 (25F84), plus isolated EUI 1.28g checks on
this machine. The long stability phase remains accepted; multiplayer is deferred.
Additional foreground sessions are currently awaiting fresh approval after an
automatic-review rejection. Older macOS versions are not covered.

## Read-only mid-game fixture inventory

`build/macos/playtests/20260913T225017Z` loaded the preserved turn-110 autosave,
finished its stored handoff to turn 111 and recorded the world state without
gameplay commands. Religion is enabled, ten religions exist and two slots remain.
Rome has one unassigned spy and known foreign cities, but zero gold and faith.
There is no active Congress. This is inventory evidence, not functional coverage.

The normal save/exit callbacks created a separate manual fixture:
`build/macos/playtests/20260913T225017Z/Lekmod-Functional-20260913T225017Z.Civ5Save`,
SHA-256 `cd6a85b2d129bced7744541bd1b4b2f3d126cfffe9b47800cc8fd524a948a5e6`.
The process exited normally (0); settings/hooks restored, no Lua runtime errors,
sync failures or new Civ V diagnostics.

## Espionage assignment and persistence

`20260913T225632Z` used that manual fixture. The scenario submitted ordinary
`Network.SendMoveSpy` commands using the game's legal relocation list, then
verified agent coordinates, travelling state and role: home city → HQ → foreign
capital as spy → HQ → foreign capital as diplomat. No spies, resources, cities
or intelligence were granted. All four checks passed; saving and normal exit
also passed. These are scripted command/state checks, not mouse or spy-arrival,
technology-theft or election outcomes.

The resulting save is
`build/macos/playtests/20260913T225632Z/Lekmod-Functional-20260913T225632Z.Civ5Save`,
SHA-256 `7cf5308305808721a488aafe8e88e7f261546b400e675ad7cd96b286d2513a80`.
`20260913T225909Z` reloaded it and matched turn, player, gold/faith and complete
spy records before any action, followed by another normal save/exit. Both runs
restored settings/hooks and recorded no Lua runtime errors, synchronization
failures or new diagnostics. The original reports retain their recorded scope;
the current harness now reports reload-only checks separately from action checks.

Reproduction:

```sh
python3 LEKMOD_DLL/macos/automated-playtest.py --mode single-player-smoke --turns 3 --timeout 180 --stall-seconds 150 --load-save /absolute/path/to/inventory-fixture.Civ5Save --scenario espionage --save-and-exit
python3 LEKMOD_DLL/macos/automated-playtest.py --mode single-player-smoke --turns 3 --timeout 180 --stall-seconds 150 --load-save /absolute/path/to/result.Civ5Save --scenario espionage --expected-state /absolute/path/to/prior/report.json --save-and-exit
```

These runs used the legacy installed GameCore hash `ada65581…fa40a`. The new
product Lua fixes and science-overflow binding received matched-package native
validation later in this report. See [the unit-handler regressions](macos-unit-handler-regressions.md).

## Work still in progress

Religion, trade, Congress, world-wonder production, Wealth settlement and
diplomat arrival now have gameplay evidence below. The earned spy award, AI deal and score-resolution/end-screen checks also passed.
Remaining work is the gated foreground queue/tile/tech-tree tests and EUI mouse
coverage. EUI background turns/save/reload and clean artifact installation/stock
restoration passed. Broader EUI popup coverage remains unverified. EUI, other macOS versions, all victory
routes and every civilization-specific ability are not covered by these standard
UI fixtures. Multiplayer remains deferred by the user.

No full-support claim is made from partial coverage.

## Religion outcomes and persistence

`20260914T000628Z` passed pantheon selection, founding and enhancement through
real popup callbacks after legal prophet missions consumed the two input prophets.
The labeled setup supplied 165 faith and two prophets; the normal missionary
purchase spent 130 faith. The purchased unit was positioned beside a known
foreign city as setup, then waited one ordinary turn for movement. Its normal
spread mission added 7,500 pressure, changed followers 0 → 4 and consumed one
charge (2 → 1). No movement, production, synchronization or wait flags were forced.
Normal save/exit passed. Save SHA-256:
`30c50c4b96988d17c493e2f867ddc45409b16b80279e77eb02d5e32e190061c3`.
`20260914T002648Z` reloaded that save and matched beliefs, holy city/followers,
faith/gold and the missionary's religion/charges/moves; normal exit and manual-save
preservation passed. Earlier failed attempts remain failed: one tried to spread
before the purchased unit regained movement, and one asserted before the network
pantheon response was applied. Bounded result polling corrected the latter.

## Trade outcomes and discovered reload defect

`20260914T012819Z` passed gold purchase of a caravan, actual standard trade-popup
selection, active-route/occupied-slot accounting, an 8.10 gold city contribution,
and ordinary treasury settlement (-27 whole gold against a -26.78 net rate).
The fixture supplied a gold budget, a Caravansary/range prerequisites and revealed
its caravan range; these were setup inputs, not earned progression. Earlier
preflight/adapter failures remain in their own reports. The route goes from Rome
to Vaduz. It saved/exited normally and preserved prior manual saves.

Reload found a real building-bonus persistence defect. See
[the trade persistence regression](macos-trade-persistence-regression.md).
`20260914T021912Z` passed the exact previously failing save on the corrected
artifact: the route and city contribution both remained 8.10 gold. Normal save/exit
and manual-save preservation passed. The save format did not change.

## Small Congress fixture progress

The Industrial/Duel fixture uses two majors and four city-states. It establishes
contact and a gold buffer as labeled setup, then lets the ordinary Congress
countdown and production run. `20260914T014945Z` and `20260914T020048Z` both founded
the Congress, submitted an Arts Funding proposal and completed the Globe Theatre
through normal production. They stopped on driver issues (an asynchronous queue
switch, then a first-turn Wealth projection affected by the finished-order guard).
Those failed attempts are superseded by the completed workflow below; their
reports remain unchanged. No session countdown or GameCore wait flags were changed.

## Documented menu and scaffold limitations

The absent extra main-menu controls are version/download and Discord/GitHub
shortcuts. They are not single-player gameplay systems. Aspyr's native menu XML
is retained; these optional shortcuts remain omitted on macOS. The unused
`Improvement_Adjacency_Yields` scaffolding has no shipped schema or rows and is
not evidence that a configured adjacency rule is being applied. Its warning has
not been suppressed or converted into a gameplay pass.

## Physical save and smaller window

At requested 1280×800, `20260914T021133Z` verified a Food Focus mouse selection
and displayed the real save menu, but exhausted its cap during name editing;
no save was created. `20260914T023611Z` used the game's unused proposed filename
and the physical Save button successfully created
`Augustus Caesar_0214 AD-1888.Civ5Save` (SHA-256
`c3b35048e19a09ce40faabbd713c5eee31fbe45cb266337c0914c51cdad9e0b8`).
The new file is also copied into that run's evidence directory. The observer
records Food Focus 0, changed from default -1, before the save. That session
reached its cap before normal exit, so physical saving is verified but a normal
exit is not claimed for it. Both runs restored graphics/settings/hooks and
preserved all earlier manual saves. The original view captures remain in the
conversation; later UI runs also retain an automatic `ui-ready.png`.

`20260914T024120Z` physically opened Load Game, selected the new Augustus Caesar
save and clicked Load Game. The loading adapter dismissed the normal loading
screen; the read-only observer then confirmed the saved Food Focus 0, changed
from the initial default -1. No gameplay callbacks performed the menu selection.
The session later reached its cap, so no normal-exit pass is claimed. Settings,
graphics and existing saves were preserved; the report retains the cap outcome.

The Wealth ledger investigation found that city updates and citizen reassignment
affect settled income after the pre-click UI forecast. The test therefore reads
the existing treasury history, without freezing citizens, altering yields or
clearing finished-order flags.

A preprocessor audit confirmed the current build does **not** enable the optional
`AUI_YIELDS_APPLIED_AFTER_TURN_NOT_BEFORE` cache mode. The final accounting accessor
therefore reads the last actual settlement from the existing treasury history
(`GetLastGoldChangeTimes100`), valid in either configuration. City updates and
citizen reassignment occur before that settlement; the earlier UI forecast alone
was not a valid exact expectation. The initial conditional cached-rate accessor
compiled out in this configuration and is replaced, not used to award a pass.

`20260914T024711Z` ended during startup with process code 255 before gameplay.
There were no new diagnostic reports or synchronization failures; settings and
hooks restored. A subsequent check found the desktop unlocked and Steam still
running. No Steam channel, Docker or scheduling changes were made. This remains
a startup failure, not an espionage result.

## Diplomat arrival

`20260914T025943Z` reloaded the saved travelling diplomat and let four ordinary
turns (112–115) run. The observer recorded travelling → making introductions
(0%, 33%, 66%) → schmoozing with established surveillance, and the engine's
`IsSpySchmoozing` check passed. No spy progress was supplied. Normal save/exit,
settings/hooks restoration and prior-manual-save preservation passed. Saved copy
SHA-256: `e105d40a8ab5bc045b7f6ac671dde5f2a017783e7a280f9322874fe54b6fc4bb`.

## Completed Congress and world-wonder workflow

`20260914T030822Z` passed the small Industrial/Duel workflow: ordinary Congress formation, Arts Funding proposal, three yes votes, engine-confirmed enactment matching active resolution ID 1, Globe Theatre production, and Wealth settlement checked against actual treasury history. The normal countdown was retained. Completed turns: 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179. Normal save/exit and manual-save preservation passed. No Lua runtime errors, synchronization failures or new diagnostics were recorded.

Save: `build/macos/playtests/20260914T030822Z/Lekmod-Functional-20260914T030822Z.Civ5Save`, SHA-256 `c2ca4e6c8c3a16ae7b6e7ed3294df1d2f733d8f815d43c820090302328ad95ea`. Earlier interrupted/driver-failed Congress reports remain unchanged.

`20260914T031447Z` reloaded the completed Congress save and matched active
resolutions, buildings, treasury, session/countdown, host and votes before any
action. Normal save/exit and restoration passed.

## Unit-owner fixture correction

`20260914T031738Z` observed PlayerDoTurn inputs before the gameplay handlers;
`20260914T032514Z` correctly observed the Defender active promotion after the
ordinary turn, but its synthetic scout retained embark. Read-only tracing in
`20260914T032909Z` proved the actual hover handler removed embark; the scout's
combat class regained it when moving in friendly territory later that turn.
The native fixture now uses real Helicopter Gunships, which ship with the
all-terrain promotion. These failed synthetic-fixture reports remain failed;
no gameplay rule was changed to satisfy them.

The first earned-spy attempt (`20260914T033212Z`) reached surveillance normally
but the ancient fixture lacked any researchable medieval technology. Lekmod's
`CANT_STEAL_CLASSICAL_ERA_TECHS` rule excludes ancient/classical awards. The runner
was stopped with cleanup; this is not a failed espionage implementation. The
retest explicitly supplies prerequisites for a technology already known by the
foreign target, then leaves travel, surveillance and the science award untouched.

## Earned espionage science

`20260914T034613Z` passed ordinary travel, surveillance, intelligence gathering,
the real tech-popup award, and recall over eight normal turns (112–119). The
fixture explicitly supplied Philosophy/Drama prerequisites, a 1,000-gold upkeep
buffer, and a foreign research city (population 11 → 32; University, Public
School and Laboratory added; existing Library retained). Destination science
rose 16.50 → 148.23 before ordinary turn updates. These inputs reduced a 35-turn
collection time to four; spy progress, rank, timers and waiting flags were never
assigned. The preceding original-capacity attempt remains interrupted.

The spy earned promotion to rank 1 and an available 230-science award. The actual
technology popup applied it to technology 21, completing the research. Recall
returned the spy to HQ. Normal save/exit, restoration and prior-save preservation
passed, with no Lua/synchronization errors or new diagnostics. Save SHA-256:
`3592770aaa7cacd349bffec67a6ef3a87cb009f39f9eb74b51e15a9973c0caf1`.

## Diplomacy fixture preparation

`20260914T035518Z` correctly rejected the planned lump-sum gold offer: none of
the eligible AI partners had a declaration of friendship. The replacement uses
a legally available embassy offer with no granted friendship or resources.
`20260914T035853Z` opened the actual leader/trade UI but exposed a test-driver
context issue: the game-level processing guard waits while diplomacy needs UI
input. The adapters now submit/close the deal within the real trade and leader
contexts; the game-level scenario only verifies the result after that guard
releases normally. No synchronization or wait flag is cleared.

## EUI test input

The author's [version history](https://forums.civfanatics.com/resources/civ5-enhanced-user-interface.24303/history)
provides EUI 1.28g. The private local archive is
`build/macos/test-deps/eui_v1_28g.zip`, SHA-256
`772a3dae6c512725f6bb5d51c70a4ed8bcf70ca0fc454a1c5019448f3ff666e5`.
It was downloaded through the browser; a direct HTTP attempt returned a browser
challenge and was not used. The original download is preserved. EUI's full code
and assets are ignored local dependencies, not redistributed in Git.

`temporary-eui-test.py` switches only the LEKMOD payload through the central
installer, uses a previously absent temporary UI_bc1 directory, and preserves
any original EUI user text. Its failure-path test verifies standard payload/text
restoration and removal of the temporary directory. Native EUI results are
pending; an offline configurator check is not a runtime compatibility pass.

`20260914T040943Z` completed the AI embassy deal without supplied resources or
friendship: real leader Trade → embassy item → Propose → accepted reply Back →
root Goodbye. The engine granted the embassy to Nubia and both treasuries stayed
unchanged. Normal save/exit and restoration passed; prior manual saves remained
byte-identical, with no Lua/synchronization errors or new diagnostics. Saved copy
SHA-256: `13715b2b2f90921eb939e3d422c8d8d94bd78e8e28bc1671824fefce93d93539`.
The earlier adapter attempts remain incomplete rather than being relabeled.

The Nubia screenshot also exposes a content limitation: LEADER_AMANITORE has no
ArtDefineTag/leader scene in the shipped override. The engine displays its empty
scene message behind working dialogue controls. No replacement leader artwork
is claimed or synthesized by these tests.

`20260914T041235Z` passed the corrected native owner fixture using actual
Helicopter Gunships: minor/barbarian all-terrain ability retained and embark
removed, and the minor Defender's own-city active promotion applied. Results
were read after one ordinary turn, with a separate observer after the actual
handler registration. Normal save/exit, settings/hooks restoration and prior
manual-save preservation passed, without Lua/synchronization errors.

`20260914T041608Z` reloaded the earned-spy save and matched the complete spy and
research snapshot. `20260914T041738Z` reloaded the embassy save and matched
embassy ownership, diplomacy/war state and treasury values. Both comparisons ran
before test mutations and both used normal save/exit with restoration.

## Ordinary score resolution and end screen

`20260914T042512Z` started an ordinary Industrial/Duel game with two majors,
four city-states, score victory enabled and a two-turn setup limit. The human
driver founded Rome, chose legal production/research/policies and ended two
ordinary turns. The engine selected AI team 1 as score winner. The real end-game
event and `GetVictory` matched a time/score victory; the captured human defeat
screen shows its artwork, text, tabs and both bottom controls in bounds. Normal
exit, settings/hooks restoration and prior-save preservation passed, without
Lua/synchronization errors or new diagnostics. No score, winner, elapsed turn or
wait flag was assigned. This covers score resolution and the loss screen, not
all victory routes or a full-length game. Earlier driver/observer attempts remain
incomplete: Scouts were obsolete, then the menu's show handler replaced the test
update callback. Both test-tool issues were corrected.

## Foreground approval boundary

After the above background checks, automatic approval review rejected the planned
180-second queue/tile mouse session twice, interpreting earlier foreground
authorization as consumed even when the later permission was quoted. No game was
launched by either rejected request. Fresh approval was requested for two capped
three-minute standard/EUI mouse sessions; background work continues meanwhile.
The older optional ten-minute request is not being used.

The first EUI run (`20260914T043047Z`) loaded its city banners, unit panel,
notifications, city view, tech tree and top panel, and rendered its loading
screen. It stopped there because the standard loading adapter targeted a
different context. The runner now calls the original EUI loading callback and
rejects standard-UI scenario adapters when EUI is installed. The wrapper restored
the standard payload, EUI text and options database after that interruption.
`20260914T043639Z` exited during startup with code 255 before menu/gameplay; no
new diagnostic was recorded and restoration passed.

`20260914T043839Z` completed turns 215–217 in EUI with no Lua/synchronization
errors, but the report retained a validation failure because the existing Wealth
order never required a newly issued production command. The driver now records
and checks inherited queue/active-production agreement separately. Such an
observation is not labeled a new order or production-click pass. The old report
remains unchanged, and a fresh native retest is required.

`20260914T044458Z` passed three ordinary scripted human turns in EUI (215–217),
with the inherited Wealth queue explicitly observed and no new-order claim.
No Lua/synchronization errors or new diagnostics were recorded. The supervisor
stopped this bounded turn check; it is not a normal-exit test. Its automatic HUD
capture was unavailable, so that run does not provide screenshot evidence.

`20260914T045117Z` used read-only inventory and the shared real save/exit
callbacks under EUI. It saved and exited normally, creating a separate fixture
with SHA-256 `65dd6a224adc162a6e5f1b6185fb09be223d80212bdeb3c0eead5521dbebfc6d`.
`20260914T045454Z` reloaded it with an exact inventory snapshot match and another
normal exit. These runs do not use standard production/city adapters or claim
EUI-specific mouse coverage.

`20260914T045856Z` verified the read-only observer in its own context, leaving
EUI's original city/HUD update handlers intact. It sent no mouse or turn commands.
A separate background-only capture, `eui-hud-small.png`, shows the gameplay HUD at
2560×1656 backing pixels for requested 1280×800; SHA-256
`da1929a2d615577590aad47f39b8c6ceb79c2805b6d261d7647821ba0f671f98`.
The timer ended this observation session; its report remains
`ended-manual-ui-time-budget`, which names the runner mode, not evidence of
physical input. `manual-captures.json` records the independent capture method
and `physical_input: false`. All EUI wrapper runs restored the standard payload,
original text, options database/journals and temporary EUI folder state.

## Clean artifact and final installation regression

The standard package is
`build/macos/Lekmod-native-single-player-20260914.zip`, SHA-256
`2a9b3ce98ba1d303ad80095f1ae59ccbb3d9523e9397083616b7dfed07dca84f`.
It was packaged from clean source commit
`293e223598e6bfa43366bbee93bd4ac8169a895f` (`dirty: false`). Its signed GameCore
SHA-256 is `04904d1ff7d8db789816b8fe900d4518ed77bb5a5e1032f727b180a84e60b40c`;
standard payload SHA-256 is
`08e643ae1bad6bd73ebc508f8c7d0c2eead5df013bcaeac25221ecc24670b560`. These
installed bytes exactly match the relevant preceding outcome tests. The manifest
retains `runtime_validated: false`; it is not a blanket support certification.

The central installer actually restored the original stock DLL and removed the
managed LEKMOD payload, then installed this clean package. Independent checks
matched all 4,086 payload files and the signed DLL. All 25 then-existing manual
saves and both stock/Aspyr backups remained byte-identical. The canonical and
Aspyr backup hash is
`0da6a5ffc283c3f147b20a7ec426e4ed85a6838ab891faf61b50af4e25c4a09c`. Details:
`build/macos/final-install-verification.json`, `final-stock-restore.log`,
`final-clean-install.log`, and `single-player-package.log`.

`20260914T051747Z` then loaded the preserved old Modern save on the clean
installation and passed script-data lifetime, science overflow, boolean SetXY
flags, all nine city-focus callbacks, avoid-growth restoration, tech-tree
open/close and all four production-selection callbacks. These remain scripted
callback/binding checks; the earlier bounded gameplay outcomes are separate.
Normal save/exit, settings/hooks restoration and manual-save preservation passed,
with no Lua errors, synchronization failures or new diagnostics. Its new save
SHA-256 is `63599940116aaf50a2402c0ae6143440f803ab114e57e74e83b381ee8d026d9b`.
The local `single-player-outcome-index.json` links the qualified passing reports
without relabeling earlier failures or incomplete observation sessions.

Full support is not claimed: the requested additional foreground tests remain
blocked pending fresh approval; EUI's broader popup/mouse paths, other victory
routes and other macOS versions are unverified. The recorded startup-only code
255 exits remain unexplained even though subsequent retries succeeded.
