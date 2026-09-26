# Lekmod macOS single-player testing handoff

**Resumed September 26 UTC: continue until the user asks to stop.** The user's
rough progress answer was75–85% (about80%), an estimate of remaining work rather
than measured test coverage. Foreground permission remains authorized; keep the
game background by default and never launch while locked. Multiplayer remains
deferred and the accepted long campaign remains closed. No push, Docker restart,
Steam channel change, or scheduled testing.

The [Swiss Armory training defect](macos-swiss-armory-validation.md) is fixed in
`149e6328`. Clean package `build/macos/Lekmod-swiss-armory-20260926.zip`, archive
SHA-256 `6786af0ce4f8fac3aa01fbebcd547ef4b88d84792077549a55ecbf028c05dc5e`.
Run `20260926T163851Z` passed seven native assertions and exact reload with normal
exit0 and full runner restoration. Eight callback regressions failed before the
fix; all66 callback cases now pass. Run `20260926T164435Z` also passed six movement/paid-upgrade/gift assertions
and exact reload. Human Swiss purchase locking and old-save compatibility also passed
nine assertions/two functional replays plus the baseline replay in
`20260926T164936Z`. No saved promotion required repair in the old checkpoint;
affected-save repair is still separate. Final independent preservation verifies
stock, Civ V closed,603 prior manual saves, quicksave/settings,32 stock UI files
and both backups. Evidence: `build/macos/swiss-armory-fix-validation-20260926.json`.

The user requested merging into local `main` at this checkpoint and continuing
there. Check the current branch and ignored continuation state before resuming.
No push is authorized. Next work: remaining ability/state boundaries, including
native affected-save migration, Romania capture/liberation/gift routing and
Yugoslav ideology reward timing.

Startup255 recurred in `20260926T163747Z`, before any gameplay. Metadata trace and
nonempty localization cache are preserved. No root-cause fix is claimed; the
later traced gameplay pass is independent. Further ability/state gaps and
startup/shutdown reliability remain open.

## Special unique-unit acquisition (September 26 UTC)

[Special acquisition](macos-special-unit-acquisition.md) now closes the ten
non-production definitions alongside the earlier Swiss purchase. Nine new cases
passed 42 assertions/nine exact replays, plus two new human-fixture baseline
replays. Combined with ordinary production, all 125 enumerated replacement definitions have at
least one own-civilization acquisition/resulting-state replay path. This is not
full ability, mission, human-owner or every-state coverage.

The tests distinguish supplied GPP/XP/faith/religion inputs from ordinary births,
actual combat awards, purchase callbacks and immediate movement. Method-binding,
callback-order, pressure-unit and turn-observation mistakes are retained as
harness failures. No new product fix was established. The final prophet case
verifies a full low-faith round; a positive City of God free-prophet test is not
claimed from its earlier failed commissioning runs.

Latest independent stock checkpoint: 600 prior manual saves, original quicksave,
settings,32 stock UI files and both backups preserved; Civ V closed. Evidence:
`build/macos/special-acquisition-validation-20260926.json`. The latest continuation instruction above supersedes this historical checkpoint. Remaining: unresolved startup
reliability and the remaining concrete ability/state boundaries. Do not reopen
the accepted campaign or multiplayer.

## Unique-unit production continuation (September 26 UTC)

The [own-civilization production catalogue](macos-unit-production-validation.md)
now covers all **115 production-capable unique definitions**: 145 functional
assertions and ten exact replays across the saved civilization groups. The ten
special-acquisition definitions remain separately enumerated. This adds native
owner-production evidence (nine human / 106 AI acquisitions), not full unique-unit
ability coverage or new physical mouse coverage.

Three fixture issues were corrected: AI resource consumption before test setup,
Colorado's dynamic strength expectation, and Portugal's actual trade-route
prerequisites/three-round budget. The failed pilot and two mixed batches remain
failed; passing stage/reload pairs and focused recoveries are identified in the
report. No new gameplay defect or product fix was established. Startup255 recurred
before one attempt; its nonempty healthy cache was preserved and the cause remains
open. No healthy cache was manually deleted.

Latest independent evidence: `build/macos/unit-production-validation-20260926.json`.
Stock restored, Civ V closed, 569 prior manual saves, original quicksave, settings,
32 stock UI files and both backups verified. Continue broader ability/owner/state
and special-acquisition gaps; do not repeat the accepted campaign or claim full
single-player support from this catalogue.

The [Swiss report](macos-swiss-crusader-validation.md) now closes the earlier
healing-exit and mounted-comparison gaps: `20260926T000754Z` passed six checks/two
exact reloads, 115.8 seconds and two ordinary turns. Additional city-attack gold
cases passed all nine checks/three reloads in `20260926T002908Z` (149.5 seconds,
zero turns). Hostile healing passed two checks/reload in `20260926T005339Z`
(83.7 seconds, one turn): Swiss15 HP/control10, a +5 bonus. Seventeen assertions
and six exact reloads across these three runs are verified, not a claim about
every remaining unit/owner/state variant. No new physical mouse coverage.

A confirmed **harness** bug copied a save before asynchronous writing finished:
532,480-byte copy versus 728,776-byte untouched original, exact prefix. Loading
that partial copy aborted in `20260926T001629Z`. Both files and the delayed crash
report remain preserved. `d7dd1237` now requires closed game write handles,
stable metadata and equal source/candidate bytes before loading. Seven save
regressions and 24 dispatcher cases pass. A 214-checkpoint audit found only the
known mismatch. The successful plunder retest verifies all full source/copy pairs.

Startup255 recurred in `20260926T000157Z` and `20260926T003550Z`; neither ran a
scenario. `9bb2b621` now preserves failure caches before stock invalidation.
The latter retained20 files and a healthy 25,509,888-byte merged cache; root cause
remains unisolated. A one-off debugger attachment `20260926T004934Z` stopped at a
Rosetta/dyld trace and confused ordinary process supervision; it was not a game
success. Owned PID18352 required scoped termination, then managed stock restore.
Do not repeat LLDB attachment under this runner; see the startup report.

Current tested product is unchanged: clean `f33cfd33`, archive
`build/macos/Lekmod-college-city-iteration-20260924.zip`, SHA-256
`9005a104f665ea4c5336c9ed8a85f31abdad782e33b277864a923ece3de09b01`.
Latest independent stock checkpoint preserved541 prior manual saves, original
quicksave,32 stock UI files, settings and both canonical/Aspyr backups. No native
process remained at that verification. Evidence:
`build/macos/swiss-completion-validation-20260926.json`.
Check `build/macos/continuation-state.json` for work started after this checkpoint.

The next upgrade/faith continuation also completed: `20260926T010909Z` passed
seven actual upgrade/reward checks and reload (95.8s, two turns), while
`20260926T012117Z` passed five Maccabee faith-purchase gates/outcomes and reload
(79.7s, zero turns). The prior faith startup255 and wrong-Roman-default fixture
remain failed. See `docs/macos-vatican-validation.md` and
`build/macos/upgrade-faith-validation-20260926.json`. Latest stock verification
preserved546 prior manual saves, original quicksave,32 stock UI files, settings
and both backups; no game process remained.

Remaining work concerns broader civilization/owner/state boundaries. The saved
114-civilization fixtures now have the 115-definition production catalogue above;
acquisition/creation evidence remains distinct from unit abilities. Completed
Swiss utility/plunder/healing/calculation paths and Crusader entry/+20/reload
should not be reopened without relevant changes. Broader civilization coverage
and historical startup/shutdown reliability still prevent a full-support claim.

## Previous religious-civilization milestone

**Latest ability milestone (2026-09-24 UTC):** [Vatican/Israel/Jerusalem cases](macos-vatican-validation.md)
add 45 passing assertions across seven functional stage/reload pairs plus a new
Vatican-human baseline replay. St Peter's pressure doubled 90→180, delegates
increased 1→3 and pressure settled exactly; capture/conversion Courthouses,
seven paired Great Person improvements, capped kill faith, Worker Pasture
culture, raw/worked luxury faith, unique-unit acquisition and kill rewards pass.
The final three-stage run `20260924T230221Z` passed 15 checks/three exact replays
in 197.1 seconds, eight ordinary turns, normal exit 0 and full cleanup. Earlier
fixture failures remain failed; no new product fix was needed.

Latest independent stock evidence preserved 518 prior manual saves, original
quicksave, 32 stock UI files, settings and both canonical/Aspyr backups. Evidence:
`build/macos/religious-civilization-validation-20260924.json`. A locked-desktop
launch attempt made no settings changes; the user subsequently unlocked and the
new normally founded Vatican-human fixture `20260924T230005Z` passed. Its save
hash is `7fb1cef635d7cf6425e18c1a7a1c6b23a59123fc0b5f8265071b2491a487af8d`.

Next work: remaining Swiss Guard utility/promotion and Crusader movement/combat
boundaries using the actually acquired unique-unit checkpoint in
`20260924T230221Z`. Broader civilization/owner states and historical startup-255 /
shutdown failures remain open. St Peter's pressure/delegate and terrain/unit
kill-yield checks are now closed; do not reopen stale pending items below.

## Previous College reward milestone

**Latest: all 90 unique building definitions have acquisition/reload coverage;
College city-loss reward defect fixed; stock verified (2026-09-24 22:09 UTC).**
The [special-building batch](macos-special-building-validation.md) closes Israel
College gold/faith purchases, Vatican St Peter's holy-city/free-reward paths,
and Jerusalem Outremer after real capture/annexation/resistance expiry. Together
with the regular catalogue this covers acquisition/persistence for all 90,
with explicitly supplied inputs and selected quantitative effects. It does not
cover every ability/owner/state combination or add physical mouse coverage.

The native College reward test found a real defect: after capture left a gap in
city slots, a surviving city's College granted zero science/faith instead of
50/50 on Quick. `f33cfd33` changes the reward loop to firstCity/nextCity; all
128 source-block sanitizer cases pass. The same old save now grants 50/50 and
reloads exactly. Earlier fixture failures (puppet IsOccupied expectations) and
the original reward failure remain recorded, not relabeled.

Clean package: `build/macos/Lekmod-college-city-iteration-20260924.zip`;
SHA-256 `9005a104f665ea4c5336c9ed8a85f31abdad782e33b277864a923ece3de09b01`.
Source `f33cfd33dfcb38ee7ab0d981b437067f07ad15c3`, dirty false; signed core
`2dcc90942588da45f5c8c04d38aec131a33e3a07333075fdb03df63054c8abc1`.
Payload is unchanged from the earlier Tunisian-flag-fixed candidate.

Run `20260924T220405Z` passed all 33 checks/seven exact replays in one native
process, 264.1 seconds and five ordinary turns, normal exit 0. Exact signed-core
ABI, every archive entry and all 13 checkpoint hashes were verified. Reproduce
with `LEKMOD_DLL/macos/batch-plans/unique-building-fixed-regression.json`.
Full evidence: `build/macos/special-building-fixed-validation-20260924.json`.
Stock/backups, 489 prior manual saves, original quicksave, 32 stock UI files and
settings are restored/preserved; Lekmod/private EUI are inactive and no game/test
process remains. All work is committed locally; nothing was pushed.

Remaining work concerns individual building/trait/unit mission effects and
owner/state boundaries, plus unisolated historical startup-255/shutdown failures.
For example, St Peter's pressure/delegate effects are not covered by its free
rewards test. All 114 normal civilization starts and 125 unique-unit lifecycles
remain passed under their recorded scopes/artifacts. Full single-player support
is not claimed from acquisition coverage alone.

Foreground permission persists, background is default, and every launch still
requires an unlocked desktop. The accepted long campaign is closed; all
multiplayer is deferred. No quota target, schedule, Docker restart or Steam
channel change is authorized by this continuation. Inspect process/install state
and the ignored continuation record before resuming. Older pending matrix/building
and locked-desktop statements below are historical.

## Previous completed milestone

**Latest completed milestone: additional combat/espionage cases and physical
acceptance passed (2026-09-22 UTC).** Commits `3c19121f` and `ac81a266` add the
five-case plan (20 assertions / five exact reloads / 27-turn aggregate bound),
324 actual counterspy decision cases, and their verified evidence. Defender
old-save recovery and real enemy-ZOC movement, Manhattan/missile production,
real fallout cleanup/repair, city nuclear effects and AI counterspy interception
all have passing native evidence. Earlier failed fixtures retain their verdicts.
The combined five-stage plan itself has not been run uninterrupted.

Physical control `20260922T205259Z` used original settings and no injected helper
or UI hooks. Actual mouse/keyboard loading, spy-loss UI, surviving-agent relocation,
new save, physical reload and normal exit passed. Stock/backups, 417 prior manual
saves, original quicksave and settings were verified after restoration. See
[the counterspy report](macos-counterspy-validation.md) and
[release qualification](macos-release-qualification.md). No product changes were
needed for these cases and nothing was pushed.

**Testing remains active at the user's request.** A broader unique-unit catalogue
scenario is being commissioned next; consult current process state and
`build/macos/continuation-state.json` before touching the installation. Do not
infer stock is currently installed from an earlier restoration verification.
The five controlled lifecycle cycles also passed (commit `caec1035`), but historic
startup-255/shutdown stalls remain unisolated. Remaining civilization/owner/system
combinations are not passed implicitly. The long campaign stays closed; all
multiplayer remains deferred. Foreground authorization persists, background is
the default, and every new launch still requires an unlocked desktop.

Older text below is historical: all five victory routes and the common static
fallback for leaders missing scene definitions were covered in later work. Do not
reopen Nubia's missing-scene limitation or other-victory gaps solely from the older
handoff paragraphs; use the expanded ledger and physical validation reports.

## Previous release qualification milestone

**Latest: clean release candidate passed the complete batch; stock restored
(2026-09-21 00:53 UTC).** Run `20260921T002839Z` passed all 16 stages, 81 functional
checks and 16 exact reloads in one process (813.7 seconds, 23 functional turns),
with normal exit and complete cleanup. All 32 checkpoint hashes were verified.
See [release qualification](macos-release-qualification.md) for the exact clean
`f40fd2b2` artifact, evidence and next command. This adds no physical mouse coverage.

The next five startup/shutdown cycles were blocked **before launch** by the locked
desktop; zero cycles ran. An unlock request is pending. Do not launch while locked.
The user has already authorized foreground testing for as long as needed, but
background remains the default. Startup-255 failures and shutdown stalls remain
unresolved; broader functional/civilization gaps remain in the ledgers. The long
campaign is closed, multiplayer deferred, and there is no active quota target.

Lifecycle tooling and interruption cleanup are committed locally in `a8ffabb3`.
Stock, both backups, 368 prior manual saves, the original quicksave, settings and
35 stock UI files were verified; Lekmod/private EUI are inactive and no test/game
process remains. Nothing was pushed. Current local evidence:
`build/macos/release-qualification-20260921.json` and
`build/macos/release-stock-verification-20260921.json`.

## Previous completed commissioning state

**Latest: batch commissioning completed; stock restored (2026-09-20 23:41 UTC).**
All 81 planned functional checks and 16 exact reload comparisons now have passing
evidence: fifteen pairs in the 783.8-second full run `20260920T231930Z`, plus
Battalion's targeted 83.2-second run `20260920T233452Z` after a test-observer-order
correction. The original full-run FAIL verdict is retained. See the
[batch guide](macos-batch-testing.md) and local
`build/macos/batch-validation-summary-20260920.md`. This is scoped functional
coverage, not full single-player certification or new physical mouse coverage.

Focused local commits: Defender radius `54424e5c`, scoped UI assertions
`474de5f1`, optional-control reload guard `729d16a2`, and observer order `805260e4`.
Nothing was pushed. Tested intermediate archive:
`build/macos/Lekmod-optional-control-20260920.zip`, SHA-256
`f054823b392cd282e7635a475e65b91fe3240b35f29cdfa8e0d3adfe224bd21e`.
Game/test processes are closed; stock and both backups match the canonical hash.
All 366 prior manual saves, the original quicksave, settings and stock UI were
verified preserved. Verification:
`build/macos/batch-final-stock-verification-20260920T234126Z.json`.
Broader remaining work is recorded in the expanded ledger and continuation state.

## Previous commissioning state

**Latest: batch tooling implemented; native commissioning blocked by locked desktop (2026-09-20 19:45 UTC).**
The user requested a longer broad test. Commit `3693e72b` adds a single-process
runner with 16 scenarios, 81 functional assertions, 16 checkpoint reload checks,
a 60-minute default and a 28-turn aggregate bound across independent fixtures.
See [the batch guide](macos-batch-testing.md) for commands and precise validation
limits. All 61 offline checks pass. Two pilot driver failures are preserved; both
causes are corrected, but the next launch was blocked before starting because
the desktop is locked. The full new batch is not yet certified.

Stock is restored and no game/test process is running. All 416 current save files,
settings, stock UI and both backups were verified unchanged. Evidence:
`build/macos/batch-stock-verification-20260920T194554Z.json`.
The Defender product fix and expanded owner tests remain uncommitted. Its five
native boundary assertions passed inside the second pilot, but checkpoint
reload/normal completion remain pending. Start with the managed `--plan pilot`
command in the guide once the desktop is unlocked, then run comprehensive.
The earlier pause and quota-target notes below are historical. Nothing was pushed.

## Previous state

**Current status: paused at the user's request; stock restored (2026-09-20 16:52 UTC).**
The latest stop instruction supersedes the earlier quota target. No game or test
runner is active. Stock GameCore and both backups match
`0da6a5ffc283c3f147b20a7ec426e4ed85a6838ab891faf61b50af4e25c4a09c`;
Lekmod/private EUI are inactive. All 413 save files, settings, 32 stock UI
files and four pending source/test files were verified unchanged. Evidence:
`build/macos/stock-pause-verification-20260920T165250Z.json`.

Latest completed source is `389871fd`. The Defender native baseline confirmed
an incorrect distance-three bonus for owned and actual-friendship cities. A
two-tile Lua correction passes all 57 owner/handler cases (four new failures
before the fix), and 32 runner regressions pass. **The corrected Defender package
has not been installed or native-retested; four related files remain uncommitted.**
Candidate archive `build/macos/Lekmod-defender-radius-20260919.zip` has SHA-256
`c12bf01668c657ddea481c4f265b0ce12bc98490ca9bf92fad32c2c1c966db94`.
See the [New Zealand report](macos-newzealand-validation.md) and
`build/macos/continuation-state.json` for the precise next retest. Nothing was pushed.

## Previous quota-limited session

**Testing resumed with a quota limit on 2026-09-19.** The user requested testing
until quota reaches 30%, interpreted as 30% remaining. The live account check
started at 40% used / 60% remaining. Check it periodically and reserve enough
quota to restore temporary hooks/settings and stock installation when stopping.
The earlier pause below is historical.

Current intermediate test archive is `build/macos/Lekmod-player-color-holes-20260919.zip`,
SHA-256 `9d31987e6fc86240d7c113b3c76dfb2af788f36b72716a4cf6b0d6923c4ac91a`,
with signed core `4e1a94b9ea8c61c16e18e2bc32a6f46a54941c056bb804b14cfd4c8066bc764b`.
The [player-color allocator fix](macos-player-color-validation.md) corrects a
new-game SIGSEGV with repeated civilizations; exact native retest/reload passed.
It includes the committed farm cache correction (`2f86e2b2`). Tomb and AI Zabonah
cases are committed in `ad9d520c` and `8b1b1b12`. Inspect live processes and
`build/macos/continuation-state.json` before another launch. Broader coverage
and intermittent localization startup failures remain open.

## Previous stock pause

**Current status: testing paused; stock restored and verified (2026-09-19 10:01 UTC).**
The user requested a return to stock and continuation later. The central installer
now reports stock GameCore `0da6a5ffc283c3f147b20a7ec426e4ed85a6838ab891faf61b50af4e25c4a09c`;
Lekmod and private EUI are inactive. No game or test runner is running. All
392 save files, both stock/Aspyr backups, settings and 32 restored stock UI files
matched their pre-restoration hashes. Verification: `build/macos/stock-pause-verification-20260919T100137Z.json`.

Source is `205bfcca`, with the uncommitted farm scenario and its runner registration
preserved. Last run `20260919T095253Z` failed the Nabataean Mathematics farm check:
three read-only samples showed cached food 2 versus calculated food 3. No farm
product fix has been made; Civil Service and persistence checks remain pending.
The runner restored settings/hooks and preserved saves. Its report records
SIGTERM and native return code 0, so this is not claimed as a normal-exit pass.
The failed save SHA-256 is
`79b3a199f593e2085d99f8ae7641230e6e47787f7cabf4ba900eeb8b30890e16`.
See `build/macos/continuation-state.json` when testing is explicitly resumed.
The resumed installation described below is historical.

## Previous resumed session

**Testing resumed at the user's request, 2026-09-19.** The current standard test
package is `build/macos/Lekmod-zabonah-removal-20260919.zip`, archive SHA-256
`9d10cd396769a678ebd23da76a017fd171bd3050976195caf34c14c6f63fbbfb`,
with signed GameCore
`7a4a5abb38928278e940bdd83ee05d234972d1ffceef4125d46b637e8c8fdca9`.

The latest [Zabonah lifecycle correction](macos-nabatea-validation.md) guards
missing, inactive and off-map unit states. Normal disbanding no longer raises a
Lua error; a Roman-owned Zabonah still receives its exact capital-discovery reward
through normal movement. Polynesian conversion/load, trade-removal/Kilwa and
standard/EUI Great Work fixes have separate native/persistence reports. Startup
exit 255 remains intermittent and open. This intermediate package was built
with the Zabonah change uncommitted and is not the final clean release. Inspect
processes and `build/macos/continuation-state.json` before launching. Original
quicksave, canonical stock and Aspyr backup remain preserved. The broad
civilization/system ledger is still open; the historical pause below does not
describe the current installation.

## Previous pause

At the user-requested pause on 2026-09-19 UTC, stock Civ V was restored and
verified. Installed GameCore, canonical stock and Aspyr backup all matched
`0da6a5ffc283c3f147b20a7ec426e4ed85a6838ab891faf61b50af4e25c4a09c`.
Lekmod/private EUI were inactive. Settings, 216 manual saves and stock UI files
were verified. A separate Civ V process appeared afterward and was left untouched.

Source was then `0a4521b7` with the Māori changes uncommitted and the later-era
test unrun. Evidence is retained in
`build/macos/stock-pause-verification-20260919.json`. Use the resumed status at
the top and the current continuation record for the latest installation and work.

Last updated: 2026-09-16. This is a same-machine, same-workspace handoff, not a
claim that the macOS port is fully certified. No new task or schedule was created.

The user subsequently requested expanded functional coverage on **this Mac
only**, with foreground sessions allowed as long as needed. The active completion
ledger is [expanded coverage](macos-expanded-coverage.md). The old planned suite
below is complete, but that is not the user's expanded completion criterion.
All five primary victory outcomes, expanded city/unit workflows, standard
post-victory UI, and bounded combat with exact reloads now have evidence. The
broader completion ledger still has open rows. Check current processes and ignored
evidence before launching. The current test archive and signed GameCore hashes are recorded in the
expanded ledger and local continuation state. Later artifacts include the voting,
presentation, greeting, artificial-lake freshwater, Georgia creation/conversion,
great-work holdings, archaeology binding and trade-countdown fixes.
Startup exit 255 was reproduced with generated-database save/open failures.
Empty-localization-cache recovery passed, but the original intermittent failure
remains under investigation; a later database-save failure involved nonempty,
healthy SQLite files and did not justify deleting them.

## Current continuation results

Read [the system-validation report](macos-single-player-systems.md) for the new
bounded gameplay evidence: religion founding/enhancement/purchase/spread, trade
route income and corrected save persistence, spy science and diplomat arrival,
AI embassy acceptance, Congress enactment, Globe Theatre, Wealth settlement,
unit-owner regressions, and ordinary score resolution/end screen. Exact reload
checks passed for religion, trade, espionage, diplomacy and Congress. These are
scoped tests, not certification of every feature or victory route.

The tested signed GameCore is
`04904d1ff7d8db789816b8fe900d4518ed77bb5a5e1032f727b180a84e60b40c`.
The installed standard package is `build/macos/Lekmod-native-single-player-20260914.zip`
(SHA-256 `2a9b3ce98ba1d303ad80095f1ae59ccbb3d9523e9397083616b7dfed07dca84f`),
built from clean source commit `293e2235`. Actual stock restoration, reinstallation,
all 4,086 payload files, backup/save preservation and final native smoke
`20260914T051747Z` passed. The detailed artifact section is in the system report. The central
`Civ5ModDlcPacker/civ5_dlc_installer.py` now owns installation and stock restoration;
do not overwrite its managed GameCore or LEKMOD payload manually. Legacy payload,
binary and Aspyr backups are preserved locally.

EUI 1.28g is a private ignored dependency with a reversible test wrapper. Check
`build/macos/continuation-state.json`, the latest runner/wrapper reports, actual
processes and installer state before launching anything; a background EUI test
may temporarily own the installed variant. No original manual save is disposable.

The earlier automatic-review foreground block was resolved by the user's
2026-09-15 messages: permission is restored and sessions may be as long as
required. Standard queue/tile/tech-tree mouse checks and normal exit passed in
`20260915T104347Z`; see [the physical report](macos-physical-validation-20260915.md).
The earlier locked-desktop EUI attempt launched no game and restored its changes.
EUI mouse testing subsequently completed in `20260915T222014Z`: city controls,
purchase, queue selection/reorder, tech-tree Close and physical save/load with
normal exit passed. The standard installation, text/options and backups were
restored. No game or test supervisor remains running.

## Start here

Workspace: `/Users/duffy/Documents/GitHub/Lekmod`. The original handoff used
`main`; the current existing branch is `codex/shared-macos-gamecore`, checked
out by the intervening task. The resumed testing did not switch branches.
At the resumed 2026-09-13 inspection, `HEAD` was `ef173459` and the worktree
was clean. Another task had committed the fourteen changes below in `0952b9e5`,
then extracted/pinned the shared compatibility layer in `ee1f207f`/`ef173459`.
Those commits are preserved. The binary and checkout values from that initial
inspection are historical; use the current continuation results above.

The original one-off permission, three-minute cap and dirty-file inventory
below are historical. Current foreground authorization permits longer sessions;
use an explicit bounded recovery timeout and retain the desktop-lock guard.

Read this document, [validation status](macos-validation.md), and the
[test-tool operator guide](../LEKMOD_DLL/macos/TESTING.md) before taking actions.
The historical 100-turn requirements do not override the user's decisions;
the README's stale instructions have now been corrected. Background work is
complete through the final clean-package regression; only the explicitly listed
coverage limits remain; the planned foreground continuation is also complete.

Suggested prompt for the next task:

> Resume the remaining Lekmod macOS single-player testing in
> /Users/duffy/Documents/GitHub/Lekmod. First read docs/macos-testing-handoff.md,
> docs/macos-validation.md, docs/macos-single-player-systems.md, and
> LEKMOD_DLL/macos/TESTING.md. Preserve the current checkout and existing edits.
> Do not resume the completed long turn campaign, test multiplayer,
> restart Docker, change Steam's channel, or enable a schedule. The one-off
> foreground permission in the original handoff was later renewed for that task;
> check the current conversation's authorization before another foreground session.
> Use evidence-backed checks and commit verified
> fixes in focused local commits without pushing.

### Non-negotiable scope and permission boundaries

- The user accepted the accumulated turn-stability evidence and ended that
  phase. The previous uninterrupted 100-additional-turn target was **not met**
  and is not claimed as passed. Do not reinstate it or start another long run.
- Remaining work is single-player functionality. Network/cross-platform
  multiplayer, hotseat, and PBEM are explicitly deferred and untested.
- Keep Steam and Civ V in the background by default. Foreground testing is now
  authorized for this resumed task, including longer sessions as needed.
  A CLI flag or this historical handoff alone is not authorization for a new
  unrelated task.
- Do not disrupt Docker, alter Steam's channel, or undo the accepted Steam
  workaround casually. Do not bypass synchronization checks, clear GameCore
  wait flags, or dismiss required gameplay decisions to manufacture progress.
- No new launches while the desktop is locked. Do not unlock the Mac.
- Scheduled testing was canceled/paused at the user's request. No automation
  configuration remained in the local automation directory at handoff. Do not
  recreate `lekmod-extended-background-testing` or the older monitor.
- Commit confirmed changes; do not push. Preserve unrelated edits and manual
  saves. Do not use blanket staging, resetting, or cleaning of the worktree.

## State at original handoff

- Civ V and the Python test supervisor are closed. Last native run's temporary
  configuration/UI hooks were restored, and a source scan found no leftover
  test-hook markers in the installed UI directories.
- Steam is running (PID 99607 at inspection; always recheck). The existing
  socket helper is present and both libraries match its recorded patched hashes.
  No Steam or game installation was changed while preparing this handoff.
- The game installation is **standard UI**, not EUI. Native-control inventory
  requests work. Foreground attachment/input worked; guarded background
  attachment timed out. Foregrounding and disabling the guard changed together,
  so their individual effects have not been isolated.
- The user paused testing to review uncommitted files, then requested that the
  testing tools be committed and this handoff be produced. Do not treat that as
  approval for the previously proposed longer foreground session.

### Installed app, data, and binaries

App:
`/Users/duffy/Library/Application Support/Steam/steamapps/common/Sid Meier's Civilization V/Civilization V.app`

Data:
`/Users/duffy/Library/Application Support/Sid Meier's Civilization 5`

The actual game is `Contents/MacOS/Civilization V`. `AppBundleExe` is its launcher;
do not confuse its presence with a running game or kill an unrelated user instance.
Native-control app ID: `com.aspyr.civ5xp.steam`.

Installed GameCore:
`Contents/MacOS/libCvGameCoreDLL_Expansion2_DLL.dylib`

| Artifact | SHA-256 |
| --- | --- |
| Installed, signed, smoke-tested cleanup binary | `ada65581fbe74cce79801c92690923d0a35fd50d1fcbf093cfcabcfc923fa40a` |
| `build/macos/libCvGameCoreDLL_Expansion2_DLL.dylib` (unsigned counterpart) | `bb31cfa89c413b1188ea9a4a91fc5c5bfa4bc4fbc0cd8cc2dbaf40bc28b646d2` |
| `build/macos/pre-render-cleanup.dylib` (previous signed build) | `ccc945046a9fab534029c6f5ffa0d016c5fbe11a07fd2d5aca37bd927ce1c97e` |

Aspyr's original backup remains beside the installed DLL as
`libCvGameCoreDLL_Expansion2_DLL.dylib.lekmod-original`. Preserve it.
The installed binary includes some remaining uncommitted compatibility changes;
it is not asserted to be a reproducible build of clean `HEAD`. The committed
test tools can resume against this identified local installation, but a clean
release rebuild/install is separate work. Do not reinstall just to start a test.

## What is committed

Confirmed fixes predating this handoff:

- `1024d1e8`: normalize RNG arithmetic/state to Windows' 32-bit behavior.
- `5deafa1d`: return actual `CanMoveOrAttackInto` eligibility to Lua.
- `e7cc7580`: preserve the temporary string until Lua copies unit script data.
- `ded7a74d`: use pointer-width integers in batch allocator alignment.
- `c05a602d`: standard tech-tree vertical geometry.

Testing dependencies committed for the handoff:

- `bd815e71`: turn/render diagnostics, header/logger, installed/ABI validator.
- `0448f5a6`: isolated UI-configuration regressions and paired configurator/XML
  fixes. This is **offline EUI assembly coverage**, not native EUI certification.
- `74b9dc46`: separate local Steam socket-lookup/launch workaround source.
- `31d22c9f`: bounded runner, 18 Lua adapters, native helpers, classifier tests,
  CI test steps, and `TESTING.md`.

The handoff preparation ran the offline tests from a clean export of committed
files, not just the dirty tree: 5 UI-configuration tests, 14 runner/classifier
tests, 2 string-lifetime sanitizer tests, 1 allocator sanitizer test with 256
cases, and the million-transition RNG test passed. Native helper compilation
passed (including both background/foreground helpers and the universal Steam
socket helper). The RNG regression also passed separately on arm64 and x86-64.
The installed binary passed ABI/payload/signature validation. GitHub-hosted CI
and a full fresh GameCore rebuild were not run for this handoff; nothing was pushed.

## Evidence and reusable fixtures

All directories below are under
`/Users/duffy/Documents/GitHub/Lekmod/build/macos/playtests/`.
They are Git-ignored local artifacts, **not included by cloning the repository**.
Preserve them. On another machine, transfer the relevant permitted fixtures and
reports separately or create a new ordinary setup fixture; do not invent missing
evidence or represent a recreated fixture as the original.

| Run | What it establishes |
| --- | --- |
| `20260912T233131Z` | 72 consecutive human turns 41–112, 12 majors/40 city-states; then a test-driver policy loop, not a recorded native crash |
| `20260913T001716Z` | Reloaded turn 110, policy correction verified, progressed through 122; stopped when the user accepted turn testing |
| `20260913T012710Z` | Rendering-suppression cleanup: turns 111–113, no sync/Lua errors or new diagnostics; supervisor closed its game |
| `20260913T015307Z` | Early saved-fixture callback checks; wonder/process had no legal choices and were skipped |
| `20260913T020332Z` | Normal Modern-era setup, legal capital founding; all four production categories, native panel captures, local save, normal exit code 0 |
| `20260913T020622Z` | Reload of that manual save matched the recorded logical-state fingerprint; all four production callbacks; another normal save/exit |
| `20260913T020944Z` | All nine real CityView focus callbacks, including golden-age focus, and avoid-growth toggle/restore; captures, production checks, normal save/exit |
| `20260913T023845Z` | Enabled native-control service but failed attachment to the guarded background game; no physical input; supervisor interrupted/restored |
| `20260913T031707Z` | User-approved foreground attachment; real clicks Choose Research → Open Technology Tree → Close. The 180-second cap interrupted shutdown; **not** a normal-exit result |

Important fixture paths:

- Modern manual save:
  `build/macos/playtests/20260913T020332Z/Lekmod-Functional-20260913T020332Z.Civ5Save`
  SHA-256 `9c4760dda103a62025b5e859ab4dbe10db25537b5d8d7410cbf91eb3a31f1bc6`.
  Its sibling `report.json` contains `saved_state` for reload comparison.
- Huge-map turn-110 autosave:
  `build/macos/playtests/20260912T233131Z/autosaves-after/AutoSave_0110 AD-1000.Civ5Save`
  SHA-256 `50b61ec7b753b6bf3131f8f9be9b0d0c2806e88f918f57613f4174a1037b3c0c`.

Earlier failed test runs remain failed. In particular, an initialization check
ran before the human turn was active, and earlier exit adapters mistook a modal
context's hidden flag for its presentation state. `IsTopModal` fixed the latter.
Do not rewrite old reports as passes. Use accompanying notes/screenshots.

## Resume sequence

1. Read current user instructions and the three documents linked above. Check
   `git status`, process state, desktop lock state, and the installed binary hash.
   Do not assume saved PIDs or foreground approval remain valid.
2. Review the fourteen historical edits and later commits listed below before
   changing anything overlapping them. In particular, handle the older Lua exclusions
   separately from the already removed C++ rendering suppressions.
3. Continue remaining single-player coverage with an explicit fixture and
   assertions. Foreground work is authorized in the resumed conversation;
   use a bounded recovery timeout and do not infer permission in an unrelated task.
4. Record exact game/UI configuration, observed input or callback path, expected
   result, actual result, artifacts, errors, and cleanup. Commit each verified
   defect correction and update the validation checklist.

Reference background callback command (only rerun when a focused change warrants
it; it is not the whole remaining test plan):

```sh
cd /Users/duffy/Documents/GitHub/Lekmod
python3 LEKMOD_DLL/macos/automated-playtest.py \
  --mode single-player-smoke --turns 3 --timeout 300 --stall-seconds 180 \
  --load-save '/Users/duffy/Documents/GitHub/Lekmod/build/macos/playtests/20260913T020332Z/Lekmod-Functional-20260913T020332Z.Civ5Save' \
  --expected-state build/macos/playtests/20260913T020332Z/report.json \
  --city-controls --capture-panels --save-and-exit
```

For genuine mouse input, use `ui-interaction`: it loads the fixture but only
observes state, without invoking gameplay callbacks. The current foreground
flag accepts an explicit recovery timeout up to one hour; the user explicitly
removed the earlier three-minute restriction on 2026-09-15. About 50–80 seconds of prior
runs were spent starting/loading; leave shutdown time inside any approved window.

Use the native computer-use tool for UI actions. In the successful foreground
run the accessibility tree exposed only the window, so coordinates came from
fresh screenshots. The first Choose Research click had no visible effect; the
second opened it. Do not assume saved coordinates or an unexplained first click
are a game defect. Do not call `getApp` after quitting: it may start a launcher.

## Completed continuation and coverage boundaries

- The planned standard/EUI mouse continuation is complete; see the physical
  report and its supplemental assertions. No further launch is needed merely
  to repeat these passed cases.
- The reusable queue fixture remains at
  `build/macos/playtests/20260914T041903Z/Lekmod-Functional-20260914T041903Z.Civ5Save`,
  SHA-256 `596f3151a32f222d516ed08b8ef25c0c9f87fce384c2fff0b7c181b54579c7dc`.
  The new EUI physical save and exact observed reload result are documented.
- EUI background turns, shared save/exit and inventory reload passed alongside
  the later physical workflow. Every popup and civilization ability is not covered.
- Clean-source artifact installation, stock restoration and exact-byte native
  smoke are complete; preserve the archive and verification evidence.
- Keep limits explicit: omitted optional menu shortcuts, Nubia's undefined
  leader scene, unused adjacency-table scaffolding, other victory routes and
  other macOS releases are not made supported by these tests. Earlier startup
  code 255 exits remain unexplained; later successful retries do not erase them.
- Multiplayer, hotseat and PBEM remain deferred. The accepted long turn-testing
  phase is closed. No full-support certification is inferred from this coverage.

## Original uncommitted work (now preserved in `0952b9e5`)

At the original handoff there were 14 modified tracked files and no untracked
testing sources after the tool commits. Review this historical inventory and
the later shared-compatibility commits before changing overlapping code:

| Files | Remaining changes |
| --- | --- |
| `LEKMOD/Lua/Civilizations/Lekmod_newzealand.lua`, `LEKMOD/Lua/Lekmod_units.lua` | Earlier city-state/barbarian unit-handler exclusions; behavioral experiments not established as necessary |
| `CvDllPreGame.cpp`, `CvPreGame.cpp`, `CvPreGame.h` under `LEKMOD_DLL/CvGameCoreDLL_Expansion2/` | Configured SMTP-host getter instead of an empty value, plus header-text cleanup; PBEM untested/deferred |
| `LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvRandom.cpp` | Pointer formatting in logs and header-text cleanup; the RNG-width correction is already committed |
| `LEKMOD_DLL/CvGameCoreDLL_Expansion2/FirePlace/include/FireWorks/FBatchAllocate.h`, `LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaUnit.cpp` | Only final-newline/blank-line remnants; substantive fixes are committed |
| `LEKMOD_DLL/macos/build-macos.sh` | Incremental mode and compiler flags. Incremental checks only `.cpp` mtimes; it is unsafe after header/flag changes. Use a full build when rebuilding is actually required |
| `LEKMOD_DLL/macos/install-macos.sh`, `LEKMOD_DLL/macos/package-macos.sh` | Self-contained package installation/verification changes; do not deploy them casually while auditing |
| `LEKMOD_DLL/macos/README.md`, `docs/installation.md`, `readme.md` | Documentation backlog, including superseded historical test requirements |

## Failure diagnosis and cleanup reminders

The confirmed resync defect was LP64 RNG arithmetic: `unsigned long` grows to
64 bits on macOS, but Aspyr serializes/restores only 32 seed bits. The fixed
LCG normalizes reset/reseed/transitions. Earlier OpenGL-heavy samples did not
establish rendering as the root cause. Do not reintroduce suppressed hidden-AI
visualization/turn-status callbacks based only on GPU stacks.

Read `report.json` and the actual logs; `run-state.json` can lack final fields.
Required logs live under the data directory's `Logs/`: `Lua.log`,
`net_message_debug.log`, `LekmodRender.log`. Duplicate/backward turn ends,
RNG mismatch, `NetForceResync`, protocol errors, and new crash/hang reports are
real failure signals. An ordinary prompt, a driver bug, or a deliberately idle
UI-interaction fixture is not automatically a gameplay hang.

For a suspected sustained stall, preserve the render/Lua tails and take a short
sample of the verified game PID. Historical comparison samples may still exist
at `/tmp/civ5-city-state-turn.sample.txt`,
`/tmp/civ5-city-state-turn-postfix.sample.txt`, and
`/tmp/civ5-render-events-enabled-hang.sample.txt`; their rendering interpretation
was superseded by the RNG evidence. Never clear waits/checks to produce a pass.

Interrupt the verified **runner** with SIGINT for normal tool cleanup, not
SIGKILL. It may TERM/KILL its own game; that is reported explicitly and is not
a native crash or a successful user-initiated exit. See `TESTING.md` for recovery
from a supervisor that died before restoring its settings/UI backups. Preserve
Aspyr originals and user manual saves; test-generated saves have unique names.

Steam's workaround is separate: `LEKMOD_DLL/macos/steam-compat/README.md` explains
the real socket-metadata query replacing the problematic `lsof` command literal.
If Steam is already running, leave it alone. If startup is necessary, use the
existing `Launch-Steam.command` as previously authorized; it preserves backups,
does not change Docker, and refuses unfamiliar patch states. Do not apply a
different Steam update/channel or restore/modify its libraries as a routine game
test step. Original signed backups and the manifest are in
`/Users/duffy/.steam-socket-compat`; helper `/Users/duffy/.steam-ls`.
