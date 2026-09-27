# Palmyra freshwater at last-city elimination

`20260927T181349Z` passed **12 native assertions and two exact replays** in one
168-second process, across three ordinary turns. This closes
`LIFE-PALMYRA-ELIMINATED-FOREIGN-OWNERSHIP`. The parent case's duplicate-Palmyra
recipient/eliminated-old-owner combination remains open; the older duplicate
capture with a surviving old owner is separate evidence. G0 and final acceptance
remain open.

## Fixture and actions

The unchanged [September 26 candidate](macos-city-god-validation.md) was installed
through WSDLC `950a329`/v1.0.10 with its isolated pinned dependency runtime.
The normal group-07 save from `20260922T234351Z` has SHA-256
`97d0604bff2fe5082d99ef48af07e2550d21a91dd4bc554918583fa1390164ce`.
Each stage reloads this untouched input. Contact, war, one Giant Death Robot,
+1 uranium, +1000 upkeep gold and legal adjacent positioning are supplied inputs.
City damage, ownership, freshwater and player-alive state are not assigned.

- **Loss:** human Nabatea captures Palmyra's last original capital using the
  normal selection/network mission, original advisor Confirm callback and
  original Puppet callback. At `CityCaptureComplete`, Palmyra is already dead
  with zero cities. Two naturally dry neighboring plots lose trait freshwater;
  four naturally fresh neighbors retain it.
- **Gain:** AI Palmyra attacks the Netherlands' last original capital on its
  actual owner turn, using a scripted native mission. At the callback the Dutch
  player is already dead. One naturally dry neighbor gains freshwater, four
  naturally fresh neighbors remain fresh, and the adjacent water tile remains
  unchanged. This does not claim autonomous AI strategic target selection.

Both stages verify unaffected city neighborhoods, a distinct post-capture owner
turn and exact city/owner/alive/freshwater replay. The native callback timing is
observed directly, not simulated with a manual event call. Other civilizations
remain alive, so these tests do not end the game or start a new campaign.

These are scripted callbacks and native gameplay outcomes. No physical mouse
coverage is added, and the advisor Cancel branch is not claimed.

## Recovered preferences and retained commissioning failures

The recovered **current** UserSettings.ini has `AdvisorCityAttackInterrupt=1`;
the pre-deletion testing settings had it disabled. Those current preferences
were deliberately preserved. `CvUnitMission.cpp:467–490` pauses a human city
attack at the advisor modal when that preference is enabled.

| Run | Result and diagnosis |
| --- | --- |
| `20260927T180033Z` | Human controller exhausted its repeated-request bound; AI capture/replay passed. Selection/completion waiting and the distinct-owner-turn assertion needed correction. Whole batch remains failed. |
| `20260927T180409Z` | Verified human selection/target visibility, but no attack outcome. AI passed with a distinct next owner turn/replay. Whole batch remains failed. |
| `20260927T181030Z` | Birth-at-capital/adjacent staging matched an older successful capture procedure; the human attack still paused. Read-only observations showed the correct active player, legal queued target, full movement and zero city damage. |
| `20260927T181349Z` | The same birth/staging sequence passed after adding the original advisor Confirm callback. Both complete stages and replays passed. |

The temporary `playtest-scenario-advisor-attack-popup.lua` adapter arms only the
expected city, owner and selected unit, waits for the actual visible modal, checks
that Don't Show Again is unchecked, and invokes `OnConfirmButtonClicked`.
The original callback performs its normal combat-warning and popup bookkeeping.
The adapter never directly changes combat-warning flags, synchronization checks,
GameCore wait flags, preferences or popup semaphores. The human path requires one
observed confirmation; the AI control requires none. This plan specifically
requires the enabled city-attack advisor and standard UI configuration.

The first three failures are retained. The controlled fourth run establishes
missing advisor handling as the human test blockage; no new gameplay defect or
product code change was established.

## Evidence and restoration

Raw reports, injected/original UI, native logs and verified save copies are in
`build/macos/playtests/<run>/`. The acceptance register pins the successful report,
batch report and every required assertion/replay pair. All save copies have
closed-writer/stability checks and source/copy SHA-256 matches.

The successful batch exited normally with code0, restored temporary hooks/settings,
and reported no Lua runtime error, synchronization failure or new crash diagnostic.
`build/macos/palmyra-preservation-20260927.json` independently verifies:

- all672 recovered single-player saves and the original quicksave;
- all95 newer save files and three current settings files;
- all699 single-player files present before the last run;
- 34 original stock UI files and original host/GameCore/canonical/Aspyr backups;
- stock active, installed Lekmod removed, and no game or launcher left running.

The two save counts overlap; they are not additive. No multiplayer testing took
place. The eight existing actual-Lua Palmyra boundary tests, 29 Python batch tests
and 34 runner tests also pass. Nothing was pushed.
