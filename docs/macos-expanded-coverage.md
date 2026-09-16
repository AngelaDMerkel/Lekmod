# Expanded single-player coverage

The user requested broader coverage after the earlier bounded suite and selected
**this Mac only** for platform scope. The accepted stability campaign remains
closed; multiplayer, hotseat and PBEM remain deferred. Foreground testing is
authorized for sessions as long as required, with explicit recovery timeouts.
The tested host is Mac14,5 / Apple M2 Max, macOS 26.5.2 (25F84), running the
x86-64 Civ V executable on arm64 macOS.

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
| Cultural victory | Tourism/influence, musician action, threshold crossing and victory | Passed with supplied great people and staging positions |
| Diplomatic victory | World Leader session, vote eligibility/count, winning resolution and victory | Passed with supplied technology/gold; natural gifts, sessions and ballots |
| Score victory | Score resolution, human victory and defeat presentation | Passed |
| Combat | Human melee/ranged/city attacks, unit death/capture, terrain/war restrictions, naval and air actions | Pending dedicated cases |
| Unit lifecycle | Founding, movement/pathing, embark/disembark, promotion/upgrade, worker build/repair/pillage, healing, gifting/deletion, great-person actions | Promotion/upgrade/heal/embark, farm/road/repair and reload passed; other cases remain |
| City lifecycle | Additional founding, capture/puppet/annex/raze/liberation, growth/starvation, building sale, specialists/great works | Partial earlier evidence; remaining cases pending |
| Economy and policies | Research/free tech, policy/tenet acquisition and switching, happiness/golden age, resources, treasury boundaries | Partial earlier evidence; remaining cases pending |
| Diplomacy | War/peace, friendship/denunciation, resources/GPT/open borders/research agreements, city-state interactions | Embassy workflow passed; remaining cases pending |
| Religion | Found/enhance/buy/spread, conversion/defense and belief effects, save persistence | Core workflow passed; additional cases pending |
| Espionage | Assignment, diplomat, science award, surveillance, counterspy/election/coup paths and persistence | Core workflow passed; additional cases pending |
| Trade | Legal routes/income/reload, internal/sea routes, rebasing, expiry/plunder and restrictions | Land external workflow passed; additional cases pending |
| Civilization content | Inventory every playable civilization and active Lua handler; test unique mechanics and owner/negative boundaries | Inventory: 114 playable civilizations, 26 Lua files; systematic cases in progress |
| UI | Standard/EUI city, production, tech, save/load/exit, then remaining overview/notification/popups, post-victory continuation/replay and screen-size boundaries | Standard post-victory/overview workflow and presentation fixes passed; EUI additional views and dense/size boundaries remain |
| Setup and persistence | Map/era/speed/difficulty/options boundaries, new/reloaded games, autosave/manual/quicksave compatibility | Partial earlier evidence; additional cases pending |
| Startup reliability | Isolate recorded startup-only exit 255; compare identical artifact/configuration and retain failures | Localization-cache failure identified; empty-cache recovery passed; original creation failure still under investigation |
| Release regression | Recheck exact final product bytes, affected save compatibility, settings/backups and installer restore | Earlier artifact passed; repeat only for changed product code |

Evidence details and fixture commands will be added as each row progresses.
Unchecked rows are not implicitly passed by a successful smoke test.

See [the expanded physical report](macos-physical-validation-20260916.md) for
actual mouse/keyboard actions, post-victory save persistence, normal exit,
presentation fixes and the explicit limits of the earlier timed session.

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
were initially unexplained. The subsequent immediate-exit observer also covers
`_exit`; six real x86-64 subprocess paths retained their original statuses.

`20260916T001510Z` and `20260916T001834Z` reproduced exit 255 before the menu.
The latter captured Aspyr's `_exit(-1)` call stack. Both historical exit-255
Database logs, and these new failures, contain merged-localization errors.
The latest `Localization-Merged.db` was zero bytes and had no tables; the source
localization databases passed SQLite quick checks. Disk space and the descriptor
limit were sufficient. The complete cache was preserved under
`build/macos/cache-investigation/20260916T002558Z`, then only the confirmed
empty merged cache was removed. On the unchanged artifact,
`20260916T002602Z` rebuilt a 27,500,544-byte merged cache containing the required
tables and successfully resumed gameplay. This establishes the immediate failure
and a tested recovery; it does not explain the original cache-creation failure.

`repair-localization-cache.py` defaults to read-only inspection. Its explicit
`--repair-empty` option requires the game to be closed, preserves the zero-byte
file, and refuses nonempty files, symlinks and SQLite sidecars. Six offline cases
verify these boundaries. The runner reports this startup failure separately and
does not silently retry or turn a failed launch into a pass.

### Cultural victory

`20260915T235204Z` used a supplied writer's normal Great Work action and observed
one new work and two tourism. Its original popup animation ran and the normal
Close callback dismissed it. One ordinary turn added two influence. Four
supplied/staged musicians then used normal concert actions, each adding exactly
100 influence and being consumed. The normal action was unavailable on own
territory. The pre-victory save had 402 influence against the other major's 427
lifetime culture, one Great Work and one remaining musician (strength 100).
Save SHA-256: `2caf71226e9f062520aaa8b79af222cb66151716f7d0b9c2d866a741eb79b203`.

`20260915T235441Z` matched that exact recorded state on reload.
`20260915T235657Z` performed the final concert, then one ordinary turn resolved
human/team 0 cultural victory. The correct cultural artwork/text was captured
and visually inspected. All three runs exited normally and preserved original
saves/settings/hooks, with no Lua or synchronization errors. This tests action
outcomes and persistence with supplied great people, not an earned cultural
campaign or mouse interaction. Earlier run `20260915T235007Z` remains failed:
the first test driver omitted the Great Work popup's normal Close callback and
timed out waiting for a notification while that popup paused world updates.

### Diplomatic victory and score

The diplomatic fixture supplied Atomic Theory prerequisites and 20,000 gold,
then submitted actual city-state gift commands. Three city-states accepted the
gifts with verified treasury/influence changes. The isolationist fourth rejected
the command without changing either value, as its personality requires. Earlier
attempts incorrectly expected that gift to succeed, and one used a proposal's
current decision value where the UI looks up its decision type; failed reports
remain preserved. The isolationist later changed personality through normal
gameplay and accepted gifts in the resumed fixture, yielding four allies.

`20260916T000633Z` reached the UN and turn 187, then was interrupted after an
unhandled Great Engineer birth popup was captured. Its turn-180 autosave was
preserved. The popup's real Close callback was added. After the cache recovery
described above, `20260916T002602Z` resumed that autosave, retained ordinary
session timing and verified the corrected self-only human candidate list.
At turn 199 a 14-vote World Leader ballot did not win against the required 16;
the next starting allocation became 16 through the ordinary additional-delegate
rule. That run reached turn 209 before its 600-second recovery bound. It is
incomplete evidence, not a completed scenario or an uninterrupted campaign claim.

`20260916T003735Z` resumed its preserved turn-200 autosave, reached the next
World Leader session at turn 211, and saved with 16 votes unspent and no winner.
Save SHA-256: `d0d4e3513333d3688ba0e1364f1bdb21d120d0bf2827d5295a339d0ca31613c3`.
That continuation inherited the four alliances and made no new gifts. Its old
adapter's `gifts=0` PASS line is not accepted as new gift coverage; the sibling
`validation-notes.json` records this distinction, and the adapter is corrected.
`20260916T004309Z` matched the exact saved ballot/treasury/alliance snapshot.
`20260916T004509Z` cast the normal 16-vote ballot, observed resolution 9/type 0
enacted in the native log, and verified human/team 0 diplomatic victory after
one ordinary turn. Its correct artwork/text was visually inspected. All three
final runs saved/exited as applicable with process code 0 and verified cleanup,
without Lua or synchronization errors.

`20260916T004712Z` started an ordinary Ancient/Duel Shoshone game with a two-turn
score limit. No units, resources, scores or winner were assigned. The human
finished with score 51 against the AI's 42, both with one city. The engine selected
human/team 0 for score victory, the score artwork was inspected, and normal exit
returned 0 with settings/hooks/saves preserved. The prior ordinary score-defeat
case remains valid. These checks complete the five primary victory outcomes;
post-victory UI actions and the remaining rows above are still open.

### Unit actions and worker outcomes

`20260916T010204Z` supplied a Warrior, XP to the first promotion threshold and
two iron. An ordinary unit turn refreshed promotion readiness. The normal
promotion action selected Drill I (level 2, XP 10), and a normal paid upgrade
created a Roman Legion for 25 gold while retaining that promotion, XP and level.
Engine queries rejected mountain entry and upgrading in neutral territory,
while the same unit could upgrade in friendly territory. Supplied damage 50
was healed to zero by a normal heal mission over three ordinary turns.
After a labeled coastal staging move, actual movement embarked and disembarked
the unit. The final save at turn 185 has SHA-256
`2876a4b4d76bb33c04a43622a2a3f3ffc85f3d9319f59c8036947f03111a60cc`.
`20260916T010519Z` matched unit types, promotions, XP, health, coordinates,
movement, embark state, gold and iron on reload. Both runs exited normally with
cleanup verified and no Lua/synchronization errors.

Earlier unit attempts remain failed test reports. One assumed SetExperience
immediately refreshes readiness, whereas this build does that on the ordinary
unit turn. Another used general movement eligibility for a domain transition;
the corrected test uses CanEmbarkOnto/CanDisembarkOnto, then the same normal
movement command and actual position/state assertions. No readiness or embark
flag was assigned to obtain these outcomes.

`20260916T010732Z` started an ordinary Ancient/Duel Rome game and legally founded
its capital. A worker and Wheel prerequisites were supplied. Normal build
missions completed a farm (food 1→2) and a road without replacing that farm.
After a labeled pillaged-farm input, the normal repair mission restored food 2
and retained both improvement and road. City, water and duplicate-farm build
eligibility were rejected. The turn-8 save has SHA-256
`9cfc1e4a5e92dfbe2fef264a8a8bf62dc3738778b16b1862a04ee58ed7e0c547`.
`20260916T011046Z` matched the recorded improvement/route/pillage flags, yields,
units and treasury on reload. Normal exit and settings/hooks/save preservation
passed for both runs, without Lua/synchronization errors. Combat pillaging,
road repair and actual road travel remain separate coverage items.

The current temporary standard test package is
`build/macos/Lekmod-league-choices-20260916.zip`, SHA-256
`d46d4784a9d4fbbf47d532e5302f3259e9e74aadd56b862d1097aee6cbf78b25`.
It contains the reviewed XML/Lua changes and the voting-choice correction in
signed GameCore `4ac6ef335a2d5cdd78c515793fb2fe2ba1e99cbd279642ee86ee4be2b989e9a9`.
`7ba4560c` commits that correction after 17 sanitizer cases and the native
World Leader candidate check. Earlier expanded science, domination, cultural and
civilization results used GameCore `04904d1f…` and, for the civilization fixes,
`Lekmod-civ-regressions-20260915b.zip` (SHA-256
`349afefb42bef3713ff1bba83f3749951a32ba43e6fe1dbd89241bc785d300f6`).
Its manifest correctly records a dirty source tree; it is not a final clean
release artifact. Installation used the central installer, and the three changed
product files match their manifest hashes. The preceding clean package remains
available for restoration.
