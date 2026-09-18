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
| Combat | Human melee/ranged/city attacks, unit death/capture, terrain/war restrictions, naval and air actions | Core land/city/naval attacks, death/capture and reload passed; actual air strike/interception, ground sweep, carrier capacity/movement and exact reload passed |
| Unit lifecycle | Founding, movement/pathing, embark/disembark, promotion/upgrade, worker build/repair/pillage, healing, gifting/deletion, great-person actions | Promotion/upgrade/heal/embark, farm/road/repair, disband/gift and great-person actions passed; pillage, road repair/travel and exact reload passed; Academy/Manufactory/Customs House/Holy Site/Citadel construction and reload passed; other great-person cases remain |
| City lifecycle | Additional founding, capture/puppet/annex/raze/liberation, growth/starvation, building sale, specialists/great works | Core lifecycle, artwork movement/theming and exact reloads passed; Dance Hall bonuses and ordinary artifact/landmark digs passed; further cultural UI/branches remain |
| Economy and policies | Research/free tech, policy/tenet acquisition and switching, happiness/golden age, resources, treasury boundaries | Policy/tenet confirmations, spending and Cuba reward boundaries passed; pressure/revolution, natural anarchy expiry and exact reload passed; remaining economy cases pending |
| Diplomacy | War/peace, friendship/denunciation, resources/GPT/open borders, non-aggression pacts and configured agreement restrictions, city-state interactions | Luxury/GPT gifts, mutual embassies, open borders and persistence passed; natural contract expiry and permanent embassies passed; friendship/denunciation and reload passed; non-aggression creation/expiry and configured-off agreement UI passed; negotiated peace/protection/expiry and reload passed |
| Religion | Found/enhance/buy/spread, conversion/defense and belief effects, save persistence | Core workflow, inquisitor purchase/defense/removal and pressure-retention belief/reload passed; founder gold, Mandir/luxury yields and Holy Warriors purchases/reload passed; further boundaries pending |
| Espionage | Assignment, diplomat, science award, surveillance, counterspy/election/coup paths and persistence | Core workflow, counterspy arrival, scheduled election and successful coup/reload passed; failed coup, dead-agent rejection and five-turn replacement/reloads also passed; defensive interception and further UI remain |
| Trade | Legal routes/income/reload, internal/sea routes, rebasing, expiry/plunder and restrictions | Land external, internal land-food/sea-production, rebasing and reload passed; natural expiry/countdown correction and land plunder/reload passed |
| Civilization content | Inventory every playable civilization and active Lua handler; test unique mechanics and owner/negative boundaries | [Inventory: 114 civilizations and 26 Lua files](macos-civilization-coverage.md); systematic cases in progress |
| UI | Standard/EUI city, production, tech, save/load/exit, then remaining overview/notification/popups, post-victory continuation/replay and screen-size boundaries | Standard post-victory/overview workflow and presentation fixes passed; EUI additional views and dense/size boundaries remain |
| Setup and persistence | Map/era/speed/difficulty/options boundaries, new/reloaded games, autosave/manual/quicksave compatibility | Nine normal setup cases and exact reloads passed across all speeds/difficulties/eras/world sizes; quicksave and further persistence/UI boundaries remain |
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

### City lifecycle

`20260916T031131Z` supplied a settler at a legal site and founded a second city
through its normal action. The actual production popup bought an Aqueduct for
130 gold. CityView sale cancellation preserved it and the treasury; confirmed
sale removed it and refunded 6 gold. Palace sale was rejected. With stored food
provided one whole food below the threshold, an actual 0.75-food/turn surplus
grew population 3→4 over two ordinary turns. The test was corrected to inspect
hundredths rather than truncating that surplus to zero. Population 20 and empty
food were then supplied as a starvation boundary, and one ordinary turn reduced
population to 19. Save SHA-256:
`119e2677146a243a746a26774b36b648b8807041a4c07499a1fd81d9d337b122`.
`20260916T031421Z` matched the exact city/food/building/treasury snapshot on reload.

`20260916T032323Z` supplied an opponent's secondary city, a Giant Death Robot,
uranium and staging positions. Normal war/attack commands captured the city;
the actual capture-popup choice made it a puppet. Normal city tasks annexed it
and razed it over ordinary turns. An original capital was not razable. A minor
city temporarily held by the opponent was a labeled ownership input; another
real human attack and the actual Liberate choice restored city-state owner 22.
Save SHA-256:
`9da9e81e70ca069a95091185d7a0bb04c625c71ab73fd5124ce2e99188d8c726`.
`20260916T032711Z` matched city ownership, original owners, population and
disposition flags on reload. All four final runs exited normally with settings,
hooks and manual saves preserved, without Lua/synchronization errors.

The earlier capture run stalled on a genuine first-contact greeting. Its
supervisor captured the panel and preserved the failed report. The adapter now
uses that informational popup's normal Close callback; no game wait flag was
changed. The same screenshot exposed blank custom-personality text. The standard
greeting now uses the shared personality helper; all ten offline personality
cases pass and `20260916T033220Z` rendered Pacifistic correctly, then closed and
saved/exited normally. Contact was a labeled input, not earned exploration.

### Buganda lake construction and freshwater

`20260916T034956Z` reproduced a product defect after three normal worker turns:
a lake built on naturally dry land gave freshwater to all six neighbors but
reported `IsFreshWater=false` on its own tile, contrary to the in-game ability
text. A legal secondary city and worker were supplied as recorded inputs; no
terrain, improvement, damage or freshwater flag was assigned. The isolated
product-query test reproduced the same failure among nine sanitizer cases.
The correction recognizes the existing artificial-lake state in the freshwater
query. It adds no serialized fields and preserves river, natural-lake, feature
and scripted freshwater behavior.

`20260916T035314Z` repeated normal construction on the rebuilt GameCore and
verified freshwater on the lake and its six formerly dry neighbors. The tile
remained land, with food 3 and gold 1. City-tile construction, duplicate building,
farm replacement were rejected. The original own-unit pillage query does not
isolate permanence because Lekmod blocks all own-tile pillage. Supplemental notes
retain that limit. `20260916T042844Z` supplied an at-war barbarian unit and an
ordinary farm owned by the human as a positive control. The enemy could pillage
the farm and could not pillage the lake. Construction/freshwater checks also
passed again; normal exit and hooks/settings/manual-save preservation passed.
That stronger test's save SHA-256 is
`696e2eeda855d51568b07178f01ccc6cfc4503f398d78e177305578abd52777e`.
No forced lake pillage/repair is claimed as ordinary gameplay.
All nine sanitizer cases passed. The native run saved/exited normally (0), with
hooks/settings/manual saves preserved and no Lua/synchronization errors.
Save SHA-256:
`87f583d799dcd65f23ad5f88b74809a96f12dd2a954dfc4f1ab137cf7da9ba13`.
`20260916T035522Z` matched the exact lake/neighbor freshwater and yield snapshot
on reload, saved and exited normally, with the same cleanup checks passing.

Earlier attempts remain failed reports. `034444Z` had no dry plot beside its
capital; the fixture now supplies a second legal city beside unchanged dry
terrain. `034621Z` exposed a driver loop choosing a legal transit tile that was
not a legal stopping destination. Commit `46a9891d` supplies the destination
argument to the engine query; the same scenario then advanced through the
previously stalled turn. No synchronization or wait state was changed.

### Combat actions and persistence

`20260916T035936Z` supplied full-health combat units and iron/uranium/oil as
explicit inputs on unchanged map plots. Normal commands produced these outcomes:
Archer→Spearman damage 30; Warrior exchange damage 36 to defender and 29 to
attacker; Giant Death Robot killed a Warrior and received damage 1; a Warrior
captured a worker; the capital's ranged strike dealt 13; Frigate→Caravel dealt
57. The recorded Bomber→Infantry damage 37 used the generic ranged mission;
source review during `040955Z` showed that actual air strikes use `MISSION_MOVE_TO`.
That bomber result is not accepted as normal air-combat coverage. Supplemental
validation notes preserve the distinction; both drivers are corrected for retest.
Combat units gained XP, while friendly targeting
and a second ranged attack were rejected. No unit health/death/ownership outcome
was assigned. This is scripted mission/outcome coverage, not mouse interaction.
The turn-179 save SHA-256 is
`bb638a6ce3829cc2fbf462020722bf24bf216885d303f120d86a6a17818f2a5b`.
`20260916T040113Z` matched the exact recorded unit type, owner, damage, XP,
position/movement, city and treasury snapshot on reload. Both runs exited normally
(0) and restored hooks/settings/manual saves, with no Lua/synchronization errors.

The earlier `035733Z` report remains failed after its four land cases: it required
an empty tile immediately beside the already occupied capital. The corrected
fixture uses an empty tile within the city's normal two-tile range. Air strikes, air defense, air sweeps and carrier operations require the corrected
native tests below.

### Unit disposal, gifts and great-person actions

`20260916T040612Z` supplied a Scout, Warrior, Merchant, Scientist and Engineer
as recorded inputs. The actual disband popup's No choice preserved the Scout
and treasury; Yes consumed it and refunded 4 gold. A normal military gift
transferred the Warrior to minor 22 and added 5 influence. Own-territory gifting
and Scout gifts to a city-state were rejected. A merchant staged in that minor's
territory used its normal mission for 469 gold and 30 influence, while its own-city
mission was ineligible. Normal research selection and a Scientist discovery
added exactly 57 research from existing science history. A legal building order
and Engineer hurry added exactly 154 production. All three great people were
consumed. These benefits were not assigned by the fixture.

The run saved/exited normally (0), with no Lua/synchronization errors and all
hooks/settings/manual saves preserved. Save SHA-256:
`2825a69d9916d642a05415a0ee1bc35e0b6c395a8d11efd83771bc8666e9d120`.
`20260916T040742Z` matched the exact saved units, treasury, influence, research
and city-production snapshot, then saved/exited normally with cleanup verified.
The earlier `040246Z` report remains failed: a screenshot showed the real disband
confirmation waiting for a choice. The added adapter captures the actual popup
choice closure and uses its normal close bookkeeping; it does not bypass that
confirmation or alter any GameCore wait flag. These are scripted callback/action
outcomes, not mouse interaction.

### Air missions and carriers

`20260916T041621Z` supplied full-health units and oil/aluminum, then used the
actual WorldView air-strike `MISSION_MOVE_TO` command. The Bomber took 68 damage
from interception/retaliation, the target Infantry took 16, and the anti-air unit
spent its interception. A Fighter's normal air sweep spent another ground
anti-air unit's interception. Both units retained zero damage and the fighter
zero XP, exactly as Lekmod's explicit ground-sweep rule and zero damage multiplier
require. No attack/activity/interception flag was assigned.

Three normal rebase missions loaded three Fighters onto a Carrier. A fourth
fighter was ineligible at its ordinary capacity of three. A normal sea move
carried all three loaded aircraft to the new plot with their transport links
intact. The save SHA-256 is
`1350f0a37344ab649fbc988dfb9dbe178419cd5e7b27148f22e9b561d51eb053`.
`20260916T041755Z` matched every recorded unit's type, damage, XP, position,
movement, spent-interception state and cargo/transport links after reload.
Both runs exited normally (0), with settings/hooks/manual saves preserved and
no Lua/synchronization errors. These are scripted missions and gameplay outcomes.
They do not establish a mouse workflow or fighter-versus-fighter dogfighting.

Earlier air reports remain failed. `040955Z` used a generic ranged mission instead
of the UI's air-strike mission. `041259Z` used the correct strike and observed
interception, then incorrectly required attacker XP from sweeping ground AA.
`20260916T041926Z` also reran all eight combined combat cases with the corrected
air-strike mission and exited normally; save SHA-256
`8c5c4c5b0d26f295d040708bc640f3822e3edc3125378589ed95f850a7cb59cb`.
Source review established that zero attacker XP is deliberate. The corrected
assertions require actual spent interception/movement plus the configured zero
XP/damage outcome; no wait flag or synchronization check was bypassed.

### Pillage, repairs and roads

`20260916T042453Z` loaded the preserved ordinary worker-build fixture. It supplied
a Horseman, horses and damage 40, and verified that own-tile pillaging is rejected.
An unowned farm/road and staging position were supplied explicitly. Normal pillage
of that farm yielded 20 gold, healed 25 damage and removed the improvement yield.
A second pillage damaged the road with no further gold/healing. The engine rejected
another pillage after both were damaged. The original worker was staged there and
used normal repair missions; three ordinary turns restored both farm and road and
the farm's food yield. No pillage/repair outcome flags were assigned.

Finally the Horseman was staged on the originally built own road. An adjacent
road was supplied as the destination, and an actual move consumed 30 movement
points, below an ordinary step's 60. This verifies road travel, not construction
of that additional road. Save SHA-256:
`e10e04691c3206a9fa5a8613bcb6cee55ae7eb4d1974710d330ccaafc493fb86`.
`20260916T042644Z` matched the recorded improvements, routes, pillage states,
yields, treasury, unit positions/health/movement and turn on reload. Both runs
saved/exited normally (0), with hooks/settings/manual saves preserved and no
Lua/synchronization errors. The earlier `042118Z` failed a test assumption that
own improvements were pillageable; the product deliberately forbids that action.

### Georgia golden-age creation boundary

`20260916T043109Z` reproduced a Georgia ability defect: a supplied Artist's normal
golden-age action gave an existing Khevsur +33% combat, but a new Khevsur created
while six golden-age turns remained had neither the promotion nor the modifier.
The product handler listened only for player turns and expended great people.
Adding the actual UnitCreated event fixes first creation. Eight offline event
cases cover creation, existing units, ordinary expiration, other/dead owners and
a duplicate civilization; two creation cases failed before the change.

`20260916T043809Z` verified both existing and newly created Khevsurs had exactly
+33 combat percentage during the real Artist golden age, while an ordinary
Warrior had no benefit. Six ordinary turns (165–171) expired the golden age and
removed both bonuses. Inputs were recorded units/staging; golden-age duration,
promotions and combat modifiers were not assigned. Normal exit (0), hooks/settings
and manual-save preservation passed without Lua/synchronization errors.
Save SHA-256:
`6542cee6267cf30ff55b7a8587460894a3fa0a740a682152ad050416aaf6770f`.
`20260916T044138Z` matched the exact saved turn, golden-age duration and both
Khevsur promotion/combat values, then saved/exited normally with cleanup verified.
The preceding `043451Z` observed the corrected creation bonus but remains failed:
placing every supplied unit in the capital overcrowded the test driver. The
fixture now creates military inputs on empty nearby map plots and selects normal
Wealth production. Paid upgrades are a separate conversion boundary under test;
first-creation coverage does not establish that path.

### Georgia upgrade and ownership conversion

`20260916T044307Z` reproduced a second boundary: the normal 40-gold paid upgrade
created a Khevsur during a golden age but conversion removed its creation-time
promotion. Existing `UnitUpgraded` notification order is retained. A new
synchronized `UnitConverted(oldOwner, newOwner, oldUnitID, newUnitID, isUpgrade)`
hook runs after promotion/state transfer and before the old unit's delayed death.
Georgia refreshes the receiving owner's ability there. No serialized fields,
wait flags or synchronization checks changed. Thirteen offline event cases pass,
including conversion after creation, both gift directions and upgrading away
from the Khevsur; two conversion cases failed before this addition.

`20260916T044753Z` used a normal Medieval Georgia setup, supplied Guilds/iron/gold
and units, then completed one ordinary turn, an Artist golden age and the actual
40-gold upgrade. The new Khevsur retained +33 combat and the real post-conversion
event identified the correct owner and IDs. A separate supplied Khevsur with the
bonus was staged in peaceful foreign territory and gifted through the normal
command. Its new owner retained the unit type and lost Georgia's promotion.
Save SHA-256:
`5b9c0ea42f7c1673e1bf3317d9ad1f24d014d0df670ec24fe76265da190d2cc3`.
`20260916T045001Z` matched the exact saved treasury, golden-age duration and both
owners' Khevsur promotions/combat/level/XP. Both runs saved/exited normally (0),
with hooks/settings/manual saves preserved and no Lua/synchronization errors.
`20260916T045132Z` reran all seven ordinary Roman disposal/gift/great-person
cases on the new GameCore, including the real minor-unit gift conversion. All
passed with normal save/exit and cleanup. Gift-to-Georgia coverage remains
offline; the native Georgian gift check was away from Georgia. No multiplayer coverage is inferred from the synchronized event.

### Great-work creation, movement and theming

`20260916T050010Z` supplied a legal second city, two Museums and two Artists.
Normal Artist actions created two artworks and consumed the artists; both real
animated popups used their normal Close callback. The first artwork was captured
and visually inspected. Normal CultureOverview move commands placed the works in
one Museum, swapped its two occupied slots, moved one work to the second city,
and returned it. The full pair gave theme 2 and tourism 6; separating the works
removed both themes; restoration returned the original totals. These commands
are scripted gameplay outcomes, not mouse clicks or full CultureOverview UI
coverage. The save SHA-256 is
`1d63533eb6243274daa93f1fe3c4fb392d2883b0515b808c44b77d17861a8afa`.

`20260916T050213Z` matched exact slots, work classes/creators/controllers/era,
city counts, themes and tourism on reload. `20260916T050343Z` reran the same
mutations with stronger intermediate assertions: the split works yielded exactly
2 tourism in each city, rather than merely less than the themed total. Its final
snapshot equals the previously reloaded snapshot; its distinct save SHA-256 is
`7bacab6f4212ae9a16e8f6e3239b01e83d15fc15e4910bdc15aa7617f87b5718`.
All three runs saved/exited normally (0), preserved settings/hooks/manual saves,
and had no Lua/synchronization errors. Slot-type rejection through real UI,
foreign swaps, special building bonuses and archaeology remain separate cases.

### Cuba music holdings and cached bonuses

On the unchanged GameCore, `20260916T051509Z` recorded music culture 2 in Cuba's
Dance Hall instead of the data-defined 2+4. Moving it to another city's Broadcast
Tower left local happiness 3 instead of the original 2, and empire happiness -32
instead of -33. The optional work-class column was NULL in the shipped holding-
bonus row, but an inner join discarded it. Removing a work also failed to refresh
happiness and class-count caches. Three SQL cases and extracted product C++ cases
reproduced these failures before correction.

The first candidate, `052428Z`, fixed creation/removal/return but exposed a third
case: swapping two occupied music slots from the later city to the earlier one
left both works producing 6 culture. A global location search found a temporary
duplicate during the two slot assignments. The calculation now resolves each
city's own slot. Current yields and tooltip values use the same read-only
calculation; they do not write serialized caches during a query. Happiness is
also derived from current holdings. Class-count caches are invalidated on all
changes. The save format and object layout are unchanged.

`20260916T054630Z` passed normal Music creation, removal, return and occupied
cross-city swapping. The Dance Hall consistently supplied 6 culture and one
happiness; the Broadcast Tower supplied 2 culture and no work happiness. Both
tooltip values matched. Inputs were two legal cities, populations 20 to avoid
happiness caps, holding buildings and Musicians; work creation and moves were
actual commands. Save SHA-256:
`e9456497a486ee6e8d22a3b00f556265a549ffd34a784869f72637d06281e9be`.
`20260916T055052Z` matched exact music slots, local/global happiness, culture,
tourism, populations and work count on reload. Both saved/exited normally (0),
restored hooks/settings/manual saves, and had no Lua/synchronization errors.

`20260916T055316Z` also reloaded the prior ordinary Museum/artwork save and
matched its exact pre-change snapshot on the rebuilt GameCore, with normal exit
and cleanup.

A full native rebuild was performed because a shared C++ declaration changed.
The ABI check retained the sole GameContext export, 474 imports and 359 dynamic
lookups. Three SQL cases and thirteen sanitizer cases pass, including both swap
directions and stale derived values after a cache reset. Those cache-reset cases
are offline evidence; no pre-fix native reload failure is claimed.

### Archaeology and improvement-yield arguments

`20260916T065002Z` supplied Archaeology and archaeologists at two natural sites,
then completed normal build missions and ordinary turns. The actual archaeology
popup's No choice preserved the pending dig; its confirmed artifact choice
created a work whose origin matched minor 25. A second confirmed choice created
a Landmark, consumed its archaeologist and removed the antiquity resource.
The unowned, current-era Landmark had tile yields +2 science, +2 gold and zero
culture, matching Lekmod's data. This is not worked-city income coverage.
A read-only native preview at the older site returned four culture if owned by
the human; it is not a claim that an aged Landmark was worked in gameplay.

The plot-yield Lua binding read both the optimal flag and route from argument 5.
The corrected route position is 6. The actual binding/helper against Lua 5.1
passes nineteen default/boolean/route combinations and an invalid-route guard;
the old code failed forwarding. The native preview accepted explicit boolean and
route arguments. The landmark choice's English wording now includes its science
and gold. A native capture verified the wording; the science icon token was then
aligned with the shipped Yields definition, `[ICON_RESEARCH]`.

Save SHA-256:
`27f6801da2a12a5486d3283d0ea6b16c899543433029dcf6e0a2ddea907b9335`.
`20260916T065356Z` matched the exact artifact slots/origins, remaining sites,
Landmark/resource state, tile yields and turn after reload. Both final runs
saved/exited normally (0), restored hooks/settings/manual saves and had no
Lua/synchronization errors. All actions here were scripted missions/callbacks.
Written artifacts, foreign-work exchange and physical archaeology clicks remain
separate coverage.

Earlier reports remain failed: `055525Z` chose an exposed site subsequently
entered by a barbarian; site selection now excludes nearby enemies and checks
for lost/displaced workers. `060026Z` completed the first artifact but its second
Build command was followed by Skip in the same frame, canceling the dig. The
scenario now waits for an acknowledged build mission before delegating turns.
`060915Z` completed both digs but incorrectly expected positive culture from a
current-era Landmark. None of these corrections bypassed synchronization.
`062914Z` failed before the menu with the separately documented database attach
error; the later successful run is not a replacement for that failure.

### Ideology selection and Cuba's first-tenet reward

`20260916T070316Z` used normal Modern/Duel Cuba setup and one ordinary turn.
The actual ideology popup's No choice preserved the unchosen state, then its Yes
choice selected Freedom. The actual tenet confirmation's No choice preserved
culture and policy state. Two distinct eligible level-one tenets were then
adopted through the real confirmation callback and observed PlayerAdoptPolicy
events. Culture inputs of 90 and 235 were recorded; exact culture/free-token
spending was checked. The first tenet unlocked the Cuban dummy policy/building
and created exactly two Guerrilleros. The later tenet did not repeat that reward.
Level-two choices without prerequisites and duplicate adoption were rejected;
the actual revolution button was disabled while public opinion was content.

Save SHA-256:
`d0e6c0fab16ac24b24acd6c914d2d36af11436da1a72edb1f212b169b7efcb7c`.
`20260916T070605Z` matched exact ideology, policies, culture/free counters,
reward units/building, public-opinion unhappiness and anarchy on reload. Both
runs saved/exited normally (0), preserved settings/hooks/manual saves, and had
no Lua/synchronization errors. This is scripted callback/gameplay coverage;
ideology switching under pressure and physical policy clicks remain separate.

### Diplomatic resources, payments and borders

`20260916T072213Z` started ordinary Ancient/Duel Rome. Civil Service/Writing
prerequisites, contact and a two-copy whale surplus were supplied and recorded.
Actual resource/GPT pocket callbacks and Propose gave the AI one luxury copy and
1 gold per turn. Both players' resource and diplomatic GPT balances changed by
exactly one in opposite directions. Subsequent real proposals established mutual
embassies and granted open borders to the AI. Requests exceeding available GPT,
open borders without the required embassy, and another copy of a luxury already
held by the recipient were rejected. An ordinary turn settled exactly 2 gold
at the recorded net 2-GPT rate, which included the outgoing payment.

Save SHA-256:
`2087405331a61db6474b873c9a6646c0f3218896cdbec15db19f19e6c2ba0814`.
`20260916T072431Z` matched resources, treasury, diplomatic GPT, open-border state
and turn after reload, and separately asserted both embassy directions. Both
saved/exited normally (0), preserved settings/hooks/manual saves, and had no
Lua/synchronization errors. These are actual scripted trade/reply callbacks and
engine outcomes, not mouse input, negotiated research agreements or peace deals.

Earlier `071522Z` was interrupted when generic turn-driver dialog adapters had
overwritten the scenario's handlers. Explicit handlers now take precedence.
`071815Z` retained an accepted AI reply but stalled because completion was watched
from the hidden trade context. The visible reply context now verifies accepted
state and uses its ordinary Back action, followed by the root's Goodbye action.
Both earlier records remain incomplete/failed; no game wait flag was cleared.

### Trade rebasing and internal land/sea routes

`20260916T073026Z` supplied two legal coastal cities on the same sea, origin
buildings, trade-range visibility and trade units. The actual new-home popup's
No choice preserved the caravan's position; Yes moved it to the selected city.
After ordinary movement refresh, the actual route popup created a legal internal
land-food route. Its quoted 175 hundredths of food matched the destination's
trade contribution. A supplied cargo ship then created an internal sea-production
route, with quoted and observed production both 350 hundredths. A current-home
rebase destination and same-city routes were rejected. These are city yield
contributions, not a separate completed-production or food-settlement claim.

Save SHA-256:
`a919359413d0dabc28907a4dda23876681f4d5cb1b7a604cb44442c9fb1e817d`.
`20260916T073412Z` matched exact routes, domains, destinations, quoted yields,
remaining durations, city contributions and trade-unit positions/movement on
reload. Both saved/exited normally (0), preserved settings/hooks/manual saves,
and had no Lua/synchronization errors. Normal contract expiry and plunder are
separate cases; no route duration was assigned by these tests.

### Trade countdown and natural expiry

`20260916T073646Z` exposed an incorrect countdown: a sea contract remained active
past its quoted completion turn. The report remains failed. The read-only native
diagnostic `20260916T075115Z` loaded its late autosave and observed nine of ten
circuits, six path nodes and speed four. The UI said -3 turns at turn 203; normal
movement completed the tenth circuit and returned the ship on turn 204. This was
a duration-display defect, not a stalled trade route.

The countdown now derives remaining steps from current circuit count, position,
direction and speed, then rounds once. All three Lua route-list bindings share
that calculation, including incoming routes whose previous expression had the
opposite sign. Gameplay speed/circuits, serialized fields and route duration are
unchanged. Old saves use their actual saved progress without rewriting counters.
An extracted-product sanitizer test compares 15,720 reachable states against the
actual StepUnit progression, including fractional sea circuits and endpoints.
The full native build and ABI checks passed.

`20260916T080136Z` resumed the preserved turn-198 autosave. Loading finished the
stored turn, so assertions began at turn 199: the land route had already returned,
and the sea route correctly quoted five remaining turns. Five subsequent ordinary
turns preserved its exact projected end at 204. Natural expiry returned the ship,
left both trade units at their origin, retained two occupied capacity slots and
cleared all internal food/production contributions. Save SHA-256:
`b9ee2dd6696c2fb602a0c4489e1c12b83ec3ea3d255ba994884e7607f9c7ccc1`.
It saved/exited normally (0), restored settings/hooks/manual saves and reported
no Lua or synchronization errors. This is scripted turn/gameplay evidence, not
mouse interaction. The short continuation avoided repeating the full contract.
`20260916T080434Z` matched its exact expired-route snapshot after reload,
with normal exit and all cleanup verified.

`20260916T080553Z` recreated both internal routes through the real rebase/route
popups on the corrected build. All five prior creation/restriction cases passed;
outgoing and available lists agreed on 19 turns for land and 24 for sea after
initial movement. Save SHA-256:
`7c39f84765f6976d6a9dbdc24c24faaba4e317fbcf79b1db7c4d34f74528dc30`.
It saved/exited normally with cleanup and no Lua/synchronization errors.
`20260916T080910Z` matched both active routes, their corrected countdowns, yields
and unit state exactly after reload, with normal exit and complete cleanup.

`20260916T080736Z` loaded the older external-route save and checked outgoing,
available and incoming list APIs. All three agreed on 26 remaining turns; its
810-hundredths gold contribution remained unchanged. This was a read-only check,
followed by normal save/exit and verified cleanup. Incoming-list consistency is
native query evidence, not a mouse inspection of that overview.

### Palmyra city ownership

`20260916T081118Z` reproduced the owner-selection defect in normal single-player
setup with both the human and AI choosing Palmyra. The supplied AI secondary
city at (34,8) gave its naturally dry neighbor (33,9) freshwater through the real
founding event. A supplied Giant Death Robot/uranium and recorded staging position
then used a normal war/attack and the actual Puppet callback. Capture removed the
freshwater even though the current owner was also Palmyra. The failed report and
its pre-capture autosave remain intact.

The handler now determines the benefit from the actual current city owner.
The old owner's civilization still makes a capture relevant even when that
player has already been eliminated before CityCaptureComplete. Eight actual-Lua
boundary cases pass (two failed before): founding, gaining/losing a city,
duplicate Palmyra owners, eliminated old owners and unrelated civilizations.
The eliminated-owner cases are offline evidence, not native elimination tests.

`20260916T082254Z` replayed the same preserved starting save and coordinates.
The actual founding event added freshwater, and the normal attack/Puppet choice
retained it for the new Palmyra owner. Save SHA-256:
`e948987602a8ec29266af2204bed308191f161f5d7f1adec9b51045f455c4f2e`.
`20260916T082529Z` matched exact city ownership/puppet state and adjacent
freshwater after reload. Both saved/exited normally (0), restored settings/hooks,
preserved manual saves and reported no Lua/synchronization errors. These are
scripted commands/callbacks and native outcomes, not physical mouse actions.

The intervening `081444Z` and `081937Z` failures occurred before gameplay and
remain recorded separately in the startup-cache report. The successful bounded
empty-cache recovery does not establish that the original startup defect is fixed.

### Counterspy arrival, city-state election and coup

`20260916T083052Z` used the existing spy and twelve ordinary turns (179–191).
A normal relocation reached counterintelligence duty in the human capital;
this establishes arrival/state, not interception of a foreign spy. Relocating
the same spy to minor 22 completed travel/surveillance and entered election
rigging. Contact, capital visibility and initial influence (human 70, AI 140)
were recorded fixture inputs. The scheduled election at turn 190 produced the
real success notification and an observed net influence increase of 19 by the
next human turn (with recorded ordinary decay -1.25 per turn).

For the coup branch, explicit influence inputs supplied human 100 and AI 110,
leaving the AI allied and a quoted 85% chance. The normal Network.SendStageCoup
command succeeded through the engine RNG: human influence became 110, the
previous ally fell to 80, and the alliance transferred to the human. No random
seed, spy progress/rank, election clock or outcome counter was changed. Coup
eligibility was rejected while unassigned, at home, while travelling and after
the human became allied. The failed-coup/dead-spy branch remains separate.

Save SHA-256:
`bbd7c688d516da77b93f3ce6f9a9e27f9dfb91039f0155010b8aee4d398faa4d`.
`20260916T083513Z` matched exact spy states, election countdown, minor alliances
and influence on reload. Both saved/exited normally (0), restored settings/hooks,
preserved manual saves and reported no Lua/synchronization errors. These were
normal scripted game commands and observed outcomes. The coup confirmation UI
and actual mouse workflow were not exercised by this scenario.

### Trade plunder and restrictions

`20260916T084330Z` supplied an AI secondary city, origin buildings/range visibility
and a caravan. Its real active PlayerDoTurn callback issued a legal internal-food
route mission; the engine created and moved the route during one ordinary turn.
A supplied human Horseman could not plunder that route at peace or the existing
human-owned route. At war a supplied noncombat Worker remained ineligible, while
the Horseman was eligible against the same foreign route. The raider's position
was supplied explicitly; the actual normal unit action then plundered the route.
The real UnitPlundered event fired, the AI route/visual unit and one used capacity
slot disappeared, human treasury increased by exactly 100 gold, and the AI city's
food contribution returned to baseline. A repeat on the empty tile was rejected.

Save SHA-256:
`301b8c4d12b302e3cd7c15bf927fad692e4e1b8eb72bf7d5f4cf5d00c169506d`.
`20260916T084524Z` matched exact treasuries, routes/units, capacity, city food and
war state on reload. Both saved/exited normally (0), restored settings/hooks,
preserved manual saves and reported no Lua/synchronization errors. This is
scripted command/action evidence; it does not establish a mouse plunder workflow
or earned construction of the supplied AI route prerequisites.

The earlier `083710Z` failed because an AI mission queued during the human turn
had not executed. `083933Z` allowed an owner turn, but the ordinary AI strategy
replaced that queued order with a different external route. Both reports remain
failed harness attempts. The final setup issues its mission inside the actual
active owner-turn callback before unit planning; no active-player, wait or
synchronization flag is assigned, and the AI remains computer-controlled.

### Coup percentages and dead-spy relocation

The actual coup comparison accepted one extra result from the engine's 0–99 RNG:
0% accepted one roll and 85% accepted 86 rolls. An extracted-product sanitizer
test exhausts all 8,600 combinations across quoted chances 0–85; all 86
percentages failed before the strict comparison and now match exactly. The RNG
call and its order remain unchanged. This exhaustive probability evidence is
offline; no native zero-percent success is claimed.

`20260916T084759Z` then reproduced an independent native boundary defect. An
actual zero-chance coup failed, killed/extracted the spy and set human influence
to -10, but the dead spy still had three advertised relocation destinations.
A normal Network.SendMoveSpy command immediately changed it to travelling,
bypassing the existing five-turn replacement delay. The original failed report
is retained. The relocation predicate now validates the index and dead state
before either a city destination or recall. Fifteen extracted-product sanitizer
cases pass; four dead/invalid cases failed before correction.

`20260916T085153Z` repeated the same input on the corrected GameCore. The real
failed-coup outcome retained the AI alliance/influence and treasury, the dead spy
had zero destinations, and the same normal relocation command left it dead at
HQ. Save SHA-256:
`3144b9e05aef3dd69b69d6f9fe43d9cd1919c5232245e33ed4d7b245988431f4`.
`20260916T085327Z` matched the exact dead-spy/treasury/influence snapshot on reload.

`20260916T085517Z` followed five ordinary turns (191–196). The spy remained dead
and ineligible for the first four turns; on the fifth, the engine supplied its
normal replacement, unassigned at HQ with no surveillance and the same agent-slot
count. Save SHA-256:
`04f5c6a9e2aabaa89b5113ae6d3a7d8cd54efb09dff872e2d269a05603c8e21b`.
`20260916T085911Z` matched the replacement state exactly after reload.
`20260916T090115Z` also matched the older successful-coup save's exact spy,
alliance and influence snapshot on the new GameCore. All five final runs
saved/exited normally (0), preserved settings/hooks/manual saves, and reported
no Lua/synchronization errors. No spy counter, rank, RNG state or wait flag was
assigned. These are scripted commands and outcomes, not mouse or coup-popup
confirmation checks.

### Inquisitor defense, ownership and pressure retention

`20260916T090658Z` supplied a legal owned secondary city, an 80-faith budget and
a foreign missionary. The actual purchase callback spent exactly 80 faith on an
inquisitor of the human religion. Staging it in the target city blocked foreign
spread, while a same-religion control remained eligible. Moving the defender
away enabled the foreign missionary. Its real active owner-turn callback used a
normal spread mission, consuming one charge and establishing 7,500 pressure/one
follower. The human's actual Remove Heresy action then consumed the inquisitor
and removed that foreign religion. Those positive checks passed.

The run failed the ownership boundary: native mission queries rejected the
foreign city's adjacent plot but accepted its center. The shipped inquisitor
strategy limits removal to the player's own cities. The predicate checked
ownership only inside the adjacent-city branch; it now applies to both city
positions. Nine extracted-product sanitizer cases pass, including own/foreign
centers and neighbors, no foreign religion, non-inquisitors and consumed units.
Only the foreign-center case failed before correction. The bad native result was
a query; the test did not actually purge the foreign-owned city.

`20260916T091332Z` passed all five original cases on the corrected build.
`20260916T092352Z` added exact pressure-retention assertions to the same fixture.
The existing Unity of the Prophets belief preserved 180 → 90 pressure (50%) for
religion 2; religion 3's 180 and religion 7's 7,500 cleared; the inquisitor's own
religion 9 kept all 180. No belief or pressure value was supplied for that check.
The final snapshot equals the earlier five-case pass exactly. Save SHA-256:
`d1af3d1cc0266cbe788fe8b797b90eb64dcf87aa81449feb635132d0d1dbf08d`.

`20260916T092839Z` matched exact city pressures/followers, faith and surviving
religious units after reload. All three final runs saved/exited normally (0),
restored settings/hooks, preserved manual saves and had no Lua/synchronization
errors. These are scripted callbacks, mission queries and gameplay outcomes,
not mouse input. The supplied own-religion missionary served as a query control;
its creation is not an earned faith-purchase claim. The saved city remained
without a majority after removal; restoration of the human religion is not
claimed by this case.

### First-conversion and faith-purchase beliefs

`20260916T093309Z` loaded the defense fixture's existing religion and supplied
another legal city plus a missionary. The unconverted city could not purchase
its Mandir or military faith unit, while the existing religious capital could.
An actual missionary action converted the new city and awarded exactly 40 gold:
Promised Land's data value 60 scaled by Quick speed's 67% training rate.
Faith purchases became available after conversion.

The actual production-popup callbacks bought a Mandir for 180 faith and an
Archer for 50 faith. Separate exact budgets were supplied and recorded; exact
spending, building presence and the actual CityTrained faith event were verified.
A supplied raw gem node assigned to the Mandir city changed from food 0/production
2 to food 1/production 3, matching its luxury-class building bonus. This establishes
tile yields, not worked-city food/production settlement. Duplicate Mandir purchase
was rejected. No religion, conversion, bonus gold or purchase outcome was assigned.

Save SHA-256:
`fcd7e7143454d84e6fb92576d669290445ff20af66e01324a6fa9260599acfa6`.
`20260916T093933Z` matched exact gold/faith, city religion/buildings, resource-tile
yields and owned-unit states after reload. Both saved/exited normally (0), restored
settings/hooks, preserved manual saves and had no Lua/synchronization errors.
These are scripted callbacks/missions and outcomes; physical purchase clicks and
repeat-adoption boundaries are separate checks.

### Repeat adoption and retained religious buildings

`20260916T094500Z` loaded the saved first-conversion/Mandir fixture, supplied one
prophet for each religion and recorded their staging positions. A normal foreign
owner-turn spread changed the Mandir city's majority from religion 9 to 7. The
human prophet's actual spread action changed it back to 9. Each spent one charge.
The second adoption of religion 9 added zero gold, establishing that the paid
first-conversion bonus survived save/reload and did not repeat after genuine
conversion away and back. The Mandir and all recorded food/production yields
of its assigned resource plots remained unchanged through both conversions.

Save SHA-256:
`06c02596f0897494dd5ebbb80dc365fb6f57775607fda8c21b1bf5755386292c`.
`20260916T095206Z` matched the final religions, building, tile yields, treasury,
faith and owned units with religion data exactly after reload. Both saved/exited
normally (0), restored settings/hooks, preserved manual saves and reported no
Lua/synchronization errors. Prophets/positions were supplied; conversions and
one-time reward behavior were actual outcomes, not assigned counters or mouse
interaction.

### Diplomatic contract expiry

`20260916T095618Z` loaded the actual resource/GPT/open-border agreements created
in `072213Z`. Read-only current-deal queries supplied their quoted final turns;
no duration, deal counter or diplomatic outcome was assigned. Twenty-four ordinary
turns (2–26) retained one resource export/import, outgoing/incoming 1 GPT and open
borders until the quoted end. On turn 26 all three ended together: both diplomatic
GPT values and the resource import/export returned to zero, and open borders
became false. Both permanent embassy directions remained true throughout. Imports
and exports were checked separately from total resource availability, so ordinary
map/resource development could not masquerade as contract expiry.

Save SHA-256:
`89d341bbbaacbc3cf826baee100f967bd58764bda838a5c5c0a87c4f0b6b1f24`.
`20260916T100120Z` matched exact accounting, current-deal records and permanent
embassies on reload. Both saved/exited normally (0), restored settings/hooks,
preserved manual saves and reported no Lua/synchronization errors. This was a
bounded agreement test, not a restarted stability campaign or mouse workflow.

### Friendship decisions and denunciation

The first friendship fixtures recorded genuine refusals, not a confirmed product
defect: `100820Z` (Belgium), `101319Z` (larger-world partners, including one too
recently met), and `102429Z` (Belgium after explicitly supplied military inputs).
Their failed positive-case reports remain preserved. Read-only engine diagnostics
then showed Belgium had 26 turns of contact, willingness 2, favorable opinion and
score 8 against threshold 12. `20260916T104454Z` recorded that refusal and exited
normally; its diagnostic pass is not acceptance coverage. The original single RNG
call and all decision conditions remain unchanged by the trace.

`20260916T105154Z` used normal Ancient/Duel setup with Argentina selected as the
AI opponent. The prior six resource/GPT/embassy/border cases passed. The next
case, `20260916T105738Z`, waited eighteen ordinary turns (2–20) for the normal
contact requirement. The actual Discuss/Button6 request received acceptance;
Argentina's recorded score was 15 against 12. Both friendship flags became true,
and the actual duplicate-request button became unavailable. No friendship,
opinion, willingness or contact counter was assigned. Save SHA-256:
`4257141f236b0c8e43c1216b0f2b5a5b492a8bbb5e9d5f43606fef07177901a0`.
`20260916T110147Z` matched the friendship/counters exactly on reload. The helper's
AI-initiated offer branch did not fire in this run; its acceptance was human-requested.

`20260916T110343Z` loaded that friendship. The actual denouncement confirmation's
No choice preserved friendship and the embassy. Its Yes choice then denounced
the AI, ended both friendship flags and closed both embassies while remaining
at peace. Normal Back/Goodbye closed the reply. Save SHA-256:
`952ada162c116c52a93a4ec830a12c0d550499815f26f795ad0684129ec75fee`.
`20260916T110703Z` matched the denunciation, ended friendship, embassies and war
state exactly after reload. All five final Argentina/denunciation runs saved and
exited normally (0), restored settings/hooks, preserved manual saves and reported
no Lua/synchronization errors. These are scripted callbacks and outcomes, not
mouse interaction or a claim that every AI should accept every proposal.

The shipped technology data has no research- or trade-agreement unlock. The
compiled NEW_DEFENSIVE_PACT rule and shipped non-aggression text instead define
a ten-turn peace commitment. The checklist now follows those configured rules;
it does not require forcing an otherwise unavailable research agreement into a
positive test. Native unavailable-control and non-aggression checks are next.

### Configured treaty rules and non-aggression pacts

The shipped technology rows explicitly disable research- and trade-agreement
unlocks. With science enabled, unfinished research, mutual friendship/embassies
and sufficient supplied affordability budgets, `20260916T112417Z` verified the
native research unlock remained false and both actual research-agreement controls
were disabled. It then used the actual pact pocket/proposal/AI-reply callbacks.
The live label was “NON-AGGRESSION PACT (10 Turns)”, matching the compiled rule
and shipped text. Both treaty items had duration ten; both pact flags became
true and both sides lost the ability to declare war, without a treasury charge.
One ordinary turn before the proposal let the AI update its opinion after the
new friendship. The earlier `111607Z` correctly received an AI refusal but its
adapter waited on a hidden reply context; that blocked harness report is retained.
The corrected adapter handles trade-screen refusals and only submits checked
counterterms. No counteroffer was needed in the passing run.

Active-pact save SHA-256:
`07766cd8fad0403a16b3066b9ef79f81fdef4d0b836cbf0b6530b825006af357`.
`20260916T112641Z` matched exact pact/protection/treasury/embassy/friendship state
on reload. `20260916T112946Z` followed ten ordinary turns (21–31), preserving
both protections through turn 30. At the quoted end, 31, both pact flags cleared
and ordinary war eligibility returned, with no declaration made. Expired save:
`365b28c4cdd9ffb6dbef3943f0abf0b649de1d2d6cf3df85d15e902d2f94ea82`.
`20260916T113314Z` matched that expired state exactly after reload.

`20260916T113600Z` separately opened the actual funded, friendly trade screen and
verified both research controls were disabled and both trade-agreement controls
were hidden or disabled. Native unlock counts were false, while funds, friendship,
embassies and science were otherwise available. This closes configuration/UI
coverage for these unavailable agreements; no positive research-agreement payout
is claimed. All five final runs saved/exited normally (0), restored settings/hooks,
preserved manual saves and had no Lua/synchronization errors. Actions were
scripted callbacks/queries and ordinary gameplay, not mouse input.

### Negotiated AI peace and treaty expiry

`20260916T113841Z` resumed the real city-capture war and used the actual leader
Negotiate Peace, trade proposal, AI reply, Back and Goodbye callbacks. The normal
UI supplied two five-turn peace items, with no asset concession. Both war flags
cleared, both forced-peace protections became true, and neither side could declare
war. Gold was unchanged. No war score, AI willingness or peace flag was assigned.
Save SHA-256:
`e9aeca4db1665da7f21490378e28501f52f173819f89bdfca286fc047b2216e5`.
`20260916T114119Z` matched the accepted peace and treasury state exactly on reload.

`20260916T114406Z` followed five ordinary turns (182–187). Both protections held
until the quoted end, then cleared together; both sides regained war-declaration
eligibility without actually declaring war. Save SHA-256:
`c26a37def26443f23a2bee6a9292e48e52a157e1403d9026119f4c3b77901dcd`.
`20260916T114747Z` matched that expired state exactly. All four runs saved/exited
normally (0), restored settings/hooks, preserved manual saves and reported no
Lua/synchronization errors. These are scripted callbacks and gameplay outcomes,
not mouse input. No early refusal occurred in this fixture; the shipped
AI_GIMP_ALWAYS_WHITE_PEACE option defaults to enabled, so an unconditional
five-war-turn refusal must not be inferred from the alternate code path.

### Current test artifact

The current standard test package is
`build/macos/Lekmod-diplomacy-diagnostics-20260916.zip`, SHA-256
`295c7ecc5bd916da7514aef03322b6d55f79c1c30d07829c0722c0234df0b946`.
Its signed GameCore is
`e07f67902ebbc0a88f5c104a92f0eecd5b82f38f2c107291bb22c1c3eb5a75ed`.
It includes the earlier voting, presentation, greeting and lake fixes plus
the Georgia hooks, great-work holding corrections and plot-yield argument fix.
It includes the science-icon, trade-countdown, Palmyra owner and espionage
boundary and inquisitor ownership corrections, plus read-only friendship decision
tracing. It was packaged from `89a9afdb` plus the diagnostic changes (dirty source
manifest). It is an intermediate test artifact; final release regression remains
open while the broader checklist is unfinished. Its provenance is recorded in the archive manifest. Installation used the central
installer with the canonical stock backup retained.

Earlier voting/presentation/greeting tests used signed GameCore
`4ac6ef335a2d5cdd78c515793fb2fe2ba1e99cbd279642ee86ee4be2b989e9a9`.
Earlier expanded science, domination, cultural and civilization results used
GameCore `04904d1f…` and, for the civilization fixes,
`Lekmod-civ-regressions-20260915b.zip` (SHA-256
`349afefb42bef3713ff1bba83f3749951a32ba43e6fe1dbd89241bc785d300f6`).
All prior packages and their reports remain preserved locally.

### Ideological pressure and revolution

`20260918T011415Z` read the existing Cuba fixture: Freedom, two tenets,
no tourism or pressure, and an AI without an ideology. `011646Z` supplied
Radio and let the AI choose normally; it also chose Freedom, so the opposing
pressure fixture correctly failed. `011943Z` exposed an overly restrictive
empty-tile staging assumption. `012125Z` then executed a legal foreign concert
for 100 influence, but the small city's rounded public-opinion penalty remained
zero. These failed reports and their exact scenario sources are retained; none
establish a product defect or a completed revolution.

`20260918T012412Z` explicitly supplied the AI's Order ideology and Radio, human
capital population 25, and five positioned foreign Musicians. During the AI's
actual active turn, five normal concert missions each added 100 influence and
consumed the corresponding unit. One ordinary turn reached 216; human population
was 24, lifetime culture 675, foreign influence 500/level 3, public-opinion
unhappiness 1, preferred ideology Order, and no winner. The one-point result
reflects Lekmod's base halving and Cuba's additional 50% reduction. Influence,
opinion, elapsed turns and victory state were never assigned. Save SHA-256:
`219b71aa4ddf1c3a45c93e9bd5c7d28be8d7cd61e08d0839e4e9469fcae98651`.
Exact reload `012545Z` matched that state and exited normally.

`20260918T012640Z` loaded the pressure save and supplied 37 additional culture
to make retention observable. The actual SocialPolicyPopup revolution No callback
preserved Freedom, 47 culture, tenets and zero anarchy. Its Yes callback sent the
normal network command: Order became active, Freedom and both old tenets cleared,
47 culture remained, one replacement free tenet appeared under the shipped
one-tenet-loss rule, and two turns of anarchy began. Public-opinion unhappiness
cleared; the actual switch control became disabled. Cuba's two reward units and
first-tenet marker were unchanged. Save SHA-256:
`5979138ab271cc918c1e9a58ae2e4dfddbeb84fd0f5f29ec07c8410efec651a4`.
These are scripted UI callback and native outcome checks, not physical clicks
or an earned tourism campaign. All successful runs above exited normally (0),
preserved original manual saves and restored hooks/settings, with no Lua runtime
or synchronization errors. Exact revolution reload `012805Z` passed. `012901Z` advanced two ordinary turns
216→218: the anarchy counter was 2→1→0, player yields and city production rates
were zero while active, and culture/science/production rates returned afterward.
The recorded settlement audit retained culture 47, treasury 132 and production 0
through both turns. The normal policy command spent the replacement tenet on
Hero of the People. Expiry save SHA-256:
`6a2485c8d834b0adfb4c6ff1042ef729c286e472af239339c518e07ae98c0500`.
`013033Z` reloaded that exact state. These three follow-ups also exited normally
and passed the same preservation and error checks. No product change was needed
for this workflow. The offline runner's 25 cases and scenario-supervisor checks
passed; multiplayer and the wider unfinished ledger remain outside this result.

### Venice Compass award: independent owners and save recovery

On the old payload, `20260918T014048Z` selected human and AI Venice normally
on separate single-player teams. Supplied prerequisite technologies emitted
real `TeamTechResearched(team, tech, change)` events. The first player gained
one miscellaneous route (capacity 3), but the second retained zero (capacity 2)
after its own Compass event. The shared Lua listener had removed itself after
the first team. The failed verdict was retained alongside a diagnostic save
(SHA-256 `d69fe6e6d7ac8d0c77bfbd2ca73dcf5409d7debb1ab5f565ed69e6f983e377a7`),
real exit confirmation, return code 0 and no termination signals. The earlier
activation-only `013746Z` remains a buffered-log stall, not a functional pass.

The handler now keeps listening for other teams and applies the native change
sign only to living Venice players on the affected team. Game initialization
also repairs a zero miscellaneous-route count when Compass is already known;
existing positive counts are preserved. Venice is the sole caller of this
miscellaneous-route award in the shipped product. This covers affected saves
and starts whose initial technologies predate the Lua context. Eight offline
event/reload cases pass; the original source fails six of those cases.
Shared-team/negative-change cases are offline boundaries, not multiplayer tests.

The centrally installed intermediate test package is
`build/macos/Lekmod-venice-20260918.zip`, archive SHA-256
`c8f05428a77ef519c8d2ef17511d6b20c0e1141e38438f16804154a132e1cb0c`.
The signed GameCore remains
`e07f67902ebbc0a88f5c104a92f0eecd5b82f38f2c107291bb22c1c3eb5a75ed`;
this fix changes Lua only. All five native retests used the separately labeled
activation-only process control:

- `014611Z`: both independent Compass events awarded one route, both capacities
  became 3, and re-submitting already-known technology added nothing. Save SHA-256
  `de08d6d68f5d774871a3a90d91f5132595feecd2781ed3e5bed5f2c6bd5fc018`;
  `014719Z` matched its exact snapshot after reload.
- `014817Z`: loading the actual failed save restored only the missing AI award,
  yielding one bonus/capacity 3 for each player. Save SHA-256
  `703dda17f1463c5f3a8a61dc30d10ff35f73fd9ee915baa6b163958611a0b6fe`;
  exact reload `014914Z` proved no repeated award.
- `015014Z`: a normal Industrial/Duel start had Compass and one bonus for both
  owners, with capacity 6. Save SHA-256
  `ff61873680bcc45f6c145763f30ddf6bafd22f00c60a92c379ca48a222f705af`.

All five passed normal exit, settings/hook restoration, manual-save preservation,
Lua and synchronization checks. Technology grants are fixture inputs, not earned
research; this does not cover Venice's other unique mechanics or resolve startup
reliability.

### Italy rewards apply to AI players

`20260918T015326Z` selected human and AI Italy normally. Prerequisite policies
and one free policy choice were supplied separately; the final Tradition policy
was legally adopted through the human network command and the AI's actual
active-turn `DoAdoptPolicy` path. The human received 250 golden-age points under
the installed Quick speed's 80% scaling. The AI spent its choice and completed
Tradition but received zero points (27→27): the handler incorrectly required
`Game.GetActivePlayer()` to match the reward owner. The supervisor retained a
failed result and stopped the test; cleanup and manual-save preservation passed.

The active-human restriction now applies only to the UI alert. Gameplay rewards
retain their existing eligibility, amount and timing for every eligible owner.
Ten offline cases cover human/AI point awards and golden-age extension, unrelated
civilizations, incomplete/unowned/branchless policies, fractional scaling and
shipped Quick values. Four fail on the original source; all ten pass after the fix.

`20260918T015729Z` passed all four native outcomes. Human and AI Tradition
completion each awarded 250 points. Supplied Artists then used normal golden-age
actions; completing Honor legally extended each golden age by four turns. AI
commands required the owning AI's actual active turn while the active human
remained player 0. Only prerequisites/free choices/Artists were supplied; reward
points, golden-age state and outcomes were not assigned. Save SHA-256:
`24ad0a92396713522a4dfd8832c93d07c0947c66db0099507023a59e1858318f`.
`015907Z` matched the exact saved policies, free choices, points and durations.
The action test used the activation-only process control; reload used the normal
full diagnostic mode. Both exited normally, restored hooks/settings, preserved
manual saves, and had no Lua or synchronization failures. These are native
command/event checks, not physical clicks or validation of Italy's other uniques.

The intermediate managed package is `build/macos/Lekmod-italy-20260918.zip`,
SHA-256 `c4e4bda52c53532e1f3a6d752daa9008c42724c4fac6a90d29bc71910e34a60c`.
Its GameCore remains `e07f67902ebbc0a88f5c104a92f0eecd5b82f38f2c107291bb22c1c3eb5a75ed`;
this is another Lua-only fix, built on the Venice package's product changes.

### Great-person improvements and used-prophet restriction

`20260918T020634Z` loaded the existing reconversion save. Supplied Scientists,
Engineers, Merchants, Prophets and Generals used normal build actions on naturally
eligible owned plots. Each produced the expected improvement, emitted the real
BuildFinished event and consumed its builder. Completed plot yields matched the
native build preview: Academy +8 science, Manufactory +6 production, Customs
House +4 gold and Holy Site +6 faith. Underlying resources and road state were
retained. The Citadel claimed four adjacent neutral tiles through the normal
construction/culture-bomb path; no tile owner was assigned.

All five actions rejected city/water/duplicate builds. An existing prophet that
had actually spread religion before the source save was ineligible to build a
Holy Site. The positive prophet was supplied in the capital, inherited religion
9 and four spread charges, and was positioned on its legal build tile. The
earlier `020409Z` passed the same construction checks with a religionless
plot-created prophet; its exact source is retained in that run directory.

The final save SHA-256 is
`ae1af29f901eb4f05e7aaf15169c60ec36be4ab015b9d5802bb43c70a28ac34d`.
`022855Z` matched its exact saved improvements, six plot yields, adjacent owners,
resources/routes and surviving units. That reload used an explicitly authorized
foreground startup control without an injected test library, QuickStart=0 and
SkipIntroVideo=1. Both successful runs saved/exited normally (0), preserved manual
saves, restored settings/hooks and had no Lua/synchronization errors. Intermediate
reload attempts `020756Z`, `021045Z`, `021357Z` and `021800Z` failed during
localization startup before opening the save and remain failed startup evidence.

These are scripted build/action and native outcome checks, not mouse input,
earned great-person generation or worked-city yield settlement. The Citadel
case covers neutral territory, not foreign-city/territory seizure. No product
change was needed for the five build paths.

### Native MovementCost object arguments

While exercising a crowded Atomic start, `20260918T033425Z` crashed with signal
11 at `CvPlot::movementCost` (+145), called by `CvLuaPlot::lMovementCost`. The
OS report arrived after the runner's initial diagnostic scan and is retained
inside that run directory as `Civilization V-2026-09-17-233522.ips`. Its fault
address was 0x48. The binding used BasicLuaMethod, whose generic conversion casts
Lua values through `lua_tointeger`; valid unit/plot objects are tables and became
null pointers.

The binding now retrieves the unit and source-plot instances explicitly and reads
the optional remaining-movement integer from the correct argument. An extracted
product-binding regression runs real Lua 5.1 under AddressSanitizer: 24 combinations
of distinct unit/source objects and default/nil/explicit movement arguments, plus
six invalid-argument guards, pass. The original binding fails its first object
routing assertion. This changes argument decoding, not movement rules or save data.

The managed intermediate package `build/macos/Lekmod-movement-cost-20260918.zip`
has SHA-256 `2ea17a1232f3ccf8d9cf5b59c34bbe967ec460095ab1b724f670e792f01e2567`.
Its signed GameCore is
`cf5273574eb622c53b700d6a0dbfa1e2ff882f5475d4c9a486aa4cdac740e798`.
The preserved initial save from the crashing run was used for retesting.
`035222Z` and `035746Z` no longer crashed but exposed separate driver limitations
in handling crowded starting units. Those failures remain recorded.

The driver now submits normal moves to legal nearby destinations, checks native
movement costs for intermediate steps, allows the legal final step to spend the
remaining movement, and resolves overstacked units before skipping possible
blockers. Where necessary it moves a matching adjacent blocker outward. Every
issued move must reach its destination; no position, movement count or game
wait flag is assigned. Eleven offline destination/boundary cases pass.

`040228Z` completed the exact Atomic starting fixture through two ordinary turns
325→327, including legal stack resolution, the normal ideology choice, disabled
espionage, save and normal exit. Save SHA-256:
`bf1423a006e7d841d7e5f9a6a27e7a10e0b08a461de5557fa680a450914c9bae`.
`040718Z` matched the exact saved setup/city/unit state and exited normally.
Both restored hooks/settings, preserved manual saves and passed Lua and
synchronization checks. These are scripted commands and native outcomes.

### Setup matrix

The [current-Mac setup matrix](macos-setup-matrix.md) records nine passing
two-turn configurations and exact reloads, selected option outcomes, hashes and
all retained failed attempts. This closes the finite setup-variation matrix;
quicksave, additional UI boundaries, civilization mechanics and the other open
ledger rows remain. It does not restart the accepted long-turn phase or claim
every possible combination.

### Qasimi Raider movement reward

`20260918T043955Z` selected human UAE and AI Rome normally. Supplied AI coastal
city/buildings/reveal and a cargo ship produced a legal internal sea route on
the AI's actual turn. After normal war declaration, a supplied/positioned Qasimi
Raider used the actual plunder action. The sea route and visual unit disappeared,
gold rose by 100 and XP by 15. Movement rose 480→680: the Lua reward used 200
raw points, but the shipped MOVE_DENOMINATOR is 60 and the tooltip promises two
moves (including overfill). The failed verdict and diagnostic save were retained;
its process exited 0 with cleanup, not a functional pass.

The reward now uses `2 * GameDefines.MOVE_DENOMINATOR`. Four offline cases cover
the amount, overfill, an ordinary unit and a missing-unit guard; the original
source fails the two movement cases. Native retest `045245Z` repeated the sea
plunder, XP and gold outcomes with movement 480→600. Save SHA-256:
`474f04881ab7f466cad393d4f9ac7e7058387c4ee7945343fbe3978cf5ec9fdc`.
`045420Z` matched the exact saved movement/XP/route/war/treasury state. Both
passed normal exit, restoration, manual-save preservation and Lua/sync checks.
This is scripted mission/action coverage with supplied inputs; it does not
cover foreign-owner Raiders or all UAE abilities.

The combined civilization test package is `build/macos/Lekmod-uae-aksum-20260918.zip`,
SHA-256 `79859cd8c9b03a20f8d7508e9a30f5a5dd6175c25af082362c7844d3fedeff8a`.
Its signed GameCore remains
`cf5273574eb622c53b700d6a0dbfa1e2ff882f5475d4c9a486aa4cdac740e798`.
