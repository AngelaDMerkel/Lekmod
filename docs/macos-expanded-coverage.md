# Expanded single-player coverage

The user requested broader coverage after the earlier bounded suite and selected
**this Mac only** for platform scope. The accepted stability campaign remains
closed; multiplayer, hotseat and PBEM remain deferred. Foreground testing is
authorized for sessions as long as required, with explicit recovery timeouts.

This checklist is the completion ledger. Existing evidence is retained, while
new rows require reproducible positive outcomes, relevant rejection/boundary
cases, and persistence checks where state is saved. Fixture inputs are recorded
separately from earned gameplay. No winner, elapsed-turn, synchronization or
GameCore wait flag may be assigned to obtain a pass. Other hardware/macOS
versions are outside the user-selected scope. A completed checklist will not
mean every possible combination of game state has been tested.

| Area | Remaining checks | Status |
| --- | --- | --- |
| Science victory | Apollo/project completion, part production and assembly, wrong-location rejection, prelaunch reload, final victory and presentation | Passed with explicitly supplied prerequisites/near-complete production |
| Domination victory | Legal attack, capital capture, owner transfer, city disposition and victory | Attack/capture/victory passed; disposition choices remain under city lifecycle |
| Cultural victory | Tourism/influence, musician action, threshold crossing and victory | Pending |
| Diplomatic victory | World Leader session, vote eligibility/count, winning resolution and victory | Pending |
| Score victory | Score resolution and defeat presentation | Passed in earlier suite; human victory presentation still pending |
| Combat | Human melee/ranged/city attacks, unit death/capture, terrain/war restrictions, naval and air actions | Pending dedicated cases |
| Unit lifecycle | Founding, movement/pathing, embark/disembark, promotion/upgrade, worker build/repair/pillage, healing, gifting/deletion, great-person actions | Partial earlier evidence; systematic cases pending |
| City lifecycle | Additional founding, capture/puppet/annex/raze/liberation, growth/starvation, building sale, specialists/great works | Partial earlier evidence; remaining cases pending |
| Economy and policies | Research/free tech, policy/tenet acquisition and switching, happiness/golden age, resources, treasury boundaries | Partial earlier evidence; remaining cases pending |
| Diplomacy | War/peace, friendship/denunciation, resources/GPT/open borders/research agreements, city-state interactions | Embassy workflow passed; remaining cases pending |
| Religion | Found/enhance/buy/spread, conversion/defense and belief effects, save persistence | Core workflow passed; additional cases pending |
| Espionage | Assignment, diplomat, science award, surveillance, counterspy/election/coup paths and persistence | Core workflow passed; additional cases pending |
| Trade | Legal routes/income/reload, internal/sea routes, rebasing, expiry/plunder and restrictions | Land external workflow passed; additional cases pending |
| Civilization content | Inventory every playable civilization and active Lua handler; test unique mechanics and owner/negative boundaries | Inventory: 114 playable civilizations, 26 Lua files; systematic cases in progress |
| UI | Standard/EUI city, production, tech, save/load/exit, then remaining overview/notification/popups and screen-size boundaries | Earlier core mouse workflow passed; additional cases pending |
| Setup and persistence | Map/era/speed/difficulty/options boundaries, new/reloaded games, autosave/manual/quicksave compatibility | Partial earlier evidence; additional cases pending |
| Startup reliability | Isolate recorded startup-only exit 255; compare identical artifact/configuration and retain failures | Unresolved |
| Release regression | Recheck exact final product bytes, affected save compatibility, settings/backups and installer restore | Earlier artifact passed; repeat only for changed product code |

Evidence details and fixture commands will be added as each row progresses.
Unchecked rows are not implicitly passed by a successful smoke test.

## Expanded phase evidence

### Science prelaunch

`20260915T232701Z` completed seven ordinary turns (179–186), Apollo and six
spaceship parts through normal production orders. Prerequisite technologies,
six aluminum and production accumulated to one hammer below completion were
explicit fixture inputs, not earned research/resource/production claims.
Five parts were assembled through the actual unit action; the engine rejected
assembly eligibility on a non-city plot. The final stasis chamber remained
unassembled and the engine had no winner. The unique prelaunch save has SHA-256
`60d692655512ddb98dee385a700911e11a012b54deb616e941b914cc390ae8ca`.
Normal save/exit returned 0, with no termination signals, Lua errors, new crash
diagnostics or synchronization failures. Hooks/settings and original manual saves
were preserved. `20260915T233128Z` reloaded the exact recorded prelaunch state
and exited normally. `20260915T233448Z` then used the final normal spaceship
action, observed human/team 0 science victory and the complete 1/3/1/1 part
counts, captured the correct science artwork/text, and exited normally (0,
no signals). Its final unit was marked `delayed_death=true`: the engine uses
`kill(true)` and the victory panel pauses world updates before deletion. The
preceding `20260915T233248Z` report remains failed because its test incorrectly
required immediate absence from the unit iterator. No product behavior was
changed for that test correction. This completes the listed science workflow;
it is scripted action/outcome evidence, not mouse interaction or an earned
full-length science campaign.

Earlier expanded science attempts remain failed reports. They exposed driver
gaps: an inherited Congress proposal needed a legal proposal command; batches
of announced fixture technologies pause notification updates and require the
driver to wait through the real Continue/show-hide sequence. The test also used
a boolean where `CanBuildSpaceship` accepts an optional numeric visibility flag;
omitting that optional argument corrected the test. No game wait flag or
synchronization check was altered.

### Civilization and data regressions

The strict XML parser found a missing `>` in the carrier movement trait's
closing Row tag. Local commit `eea31e0c` fixes that character and adds three
passing data checks: unique core definitions, spaceship references/thresholds,
and civilization/leader/trait links.

The offline civilization harness executes the product Lua with the engine's
event argument contracts. Sixteen cases now pass after reproducing Mughal
capture/conversion/holy-city cleanup issues and Bolivia unit-ID, event-arity,
capital-transfer and duplicate-player history issues. Mughal conversion was
also subscribed to an event the engine never emits; the actual event is
`CityConvertsReligion`. Local commit `e8e00ca4` contains these fixes. The core
native ability regressions below passed; additional owner/capture boundaries
remain offline evidence and are not native gameplay certification.

`20260915T233623Z` started an ordinary Industrial/Duel Bolivia game. It supplied
a Colorado, artist and writer as labeled inputs; the engine's UnitCreated event
set Colorado strength to 42 at happiness 5. One normal turn supplied real culture
history. The normal artist golden-age action added the production benefit;
the writer's political-treatise action increased culture and switched the
benefit to food. Save SHA-256:
`2023f97f3d500b4dd0653c8508043ed16a73b47f581bbc5025daf00cfbdf8d4a`.
Reload `20260915T233900Z` matched the recorded city benefits, Colorado, culture,
happiness, golden-age duration and turn. Both runs exited normally with no Lua
or synchronization errors and restored hooks/settings/manual saves.

`20260915T234025Z` started an ordinary Ancient/Duel Mughal game. After one
ordinary turn it supplied two religions and scripted conversions as explicit
inputs. The actual engine CityConvertsReligion events added the Mughal and
foreign holy-city benefits, removed both on own-religion conversion, then
restored both on reconversion. Save SHA-256:
`f213d9b48b0c0cb759d3ea85fe9ffcbc7ff6ed6372772e58b2865fd202812054`.
It exited normally with no Lua/synchronization errors and preserved settings,
hooks and original saves. `20260915T234151Z` reloaded the exact recorded state
and exited normally with cleanup verified. This is native event
handler coverage; supplied religion/conversion steps are not earned gameplay.

### Domination

`20260915T234324Z` loaded the prior Duel Congress fixture. One uranium, a Giant
Death Robot and its staging position were supplied and recorded; neither city
damage nor ownership was assigned. Entry to the foreign capital at peace was
rejected. A normal war command enabled combat, and one normal move/attack from
full health captured the undamaged original capital. The actual capture event
and final owner were checked, followed by human/team 0 domination victory and
the correct artwork/text. Normal exit returned 0 with no signals, Lua errors,
new diagnostics or synchronization failures; settings/hooks/manual saves were
preserved. City disposition choices and save/reload of captured cities remain
under the broader city lifecycle row.

### Startup diagnostics

`5f36fb62` adds a test-process-only observer for nonzero calls to `exit`. It
records a call stack without changing the requested status. A real x86-64
subprocess test verified statuses 0, 42 and 255; status 0 adds no failure trace.
Future ordinary tests carry this diagnostic. The two historical exit-255 runs
remain unexplained; successful later starts do not resolve their cause.

The current temporary standard test package is
`build/macos/Lekmod-civ-regressions-20260915b.zip`, SHA-256
`349afefb42bef3713ff1bba83f3749951a32ba43e6fe1dbd89241bc785d300f6`.
It contains the reviewed XML/Lua changes and the unchanged signed GameCore
`04904d1ff7d8db789816b8fe900d4518ed77bb5a5e1032f727b180a84e60b40c`.
Its manifest correctly records a dirty source tree; it is not a final clean
release artifact. Installation used the central installer, and the three changed
product files match their manifest hashes. The preceding clean package remains
available for restoration.
