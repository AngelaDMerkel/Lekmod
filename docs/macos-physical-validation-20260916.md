# Expanded physical UI validation

Current Mac only: Apple M2 Max / Mac14,5, macOS 26.5.2 (25F84). Standard UI,
1280×800 window setting, x86-64 GameCore
`4ac6ef335a2d5cdd78c515793fb2fe2ba1e99cbd279642ee86ee4be2b989e9a9`.
Foreground testing was explicitly authorized for longer sessions. Input used
the native computer-use API. The temporary observer only read state.

## Post-victory workflow

`20260916T011304Z` loaded the saved prelaunch science fixture. Actual mouse
interaction opened Military Overview, selected the stasis chamber, closed the
panel and assembled it. The real science-victory event and artwork appeared.
Mouse checks covered Demographics, Ranking scrolling/scrollbar dragging, replay
messages, graphs and civilization filtering, the empty/zero deal-income graph,
and map playback/pause plus scrubbing between turns 165 and 186.

The actual “one more turn” button returned to gameplay. Read-only observations
changed from game state 1 to state 2 while retaining winner 0 and science victory.
A mouse production choice selected a Worker. Keyboard Skip Turn commands
resolved unit orders, then the mouse Next Turn action advanced 186→187 and
produced Worker 147457. An AI-initiated mutual embassy offer was accepted through
the actual trade/Back controls. A new local save was created physically:

`PostVictory-Mouse-20260916.Civ5Save`

SHA-256 `03c38353facca127f57093a6f407198e9ada27ecaad002aeedfdf79cbddace30`.
The data-directory original and run-directory copy are preserved. The session
reached its 1800-second recovery bound before the physical Load button completed.
It is **not** a normal-exit or completed-reload result. Its original report remains
`ended-manual-ui-time-budget`, with supervisor termination signals and verified
settings/hooks/manual-save preservation.

`20260916T014631Z` resumed that save and physically selected/loaded it again.
The loading-screen Continue callback was scripted. Both read-only observations
matched the saved turn-187 state exactly, including game state 2, winner, victory,
gold, queue/buildings/yields and units. The completed embassy exchange remained
visible in relationships and deal history. Normal Exit to Windows → Yes returned
process code 0, with no termination signals. Duration: 1479.6 seconds. Settings,
graphics, hooks and original manual saves were preserved; no Lua/sync errors or
new diagnostics were recorded.

## Additional standard UI checks

The second run used actual mouse controls for:

- Economic Overview tabs and resource/city-happiness breakdowns.
- Diplomacy relationships, completed-deal details and Global Politics.
- All three empty Trade Overview tabs; this is not new route-outcome coverage.
- Espionage Overview, destination-picker cancellation and empty Intrigue.
- Notification Log and its city-attack navigation.
- A city ranged attack: the normal network task targeted (4,10), and the visible
  barbarian target disappeared. No exact damage amount was asserted.
- Victory Progress main, science and score details.
- World Congress and its enacted/available resolution catalogue.
- Advisor Counsel and pagination.
- Civilopedia search for Bolivia and its leader link; Escape dismissal worked.

No multiplayer proposal button was used. Cua screenshots are in the task
transcript; initial runner captures and `physical-validation.json` are local.
Initial native-control focus errors and failed inputs are not counted as actions.
Keyboard focus through Escape enabled the successful mouse workflow. Save-name
editing used double-click focus and forward Delete; Ctrl+A was not established
as working. A later capture/control error coincided with the expired first run,
so no successful Load action was inferred from that attempt.

## Confirmed presentation corrections

The physical work found missing leader scenes, an invisible Civilopedia Close
control, and multiplayer proposal controls exposed in single-player. The scene
audit found 64 playable leaders without ArtDefineTag, not only the previously
noted Nubian leader. Existing scene references were retained; those 64 now use
the existing Lekmod static backdrop. This does not create individual 3D artwork.

`20260916T022923Z` tested archive
`Lekmod-sp-presentation-20260916.zip`, SHA-256
`2531ba88185166b0c9a681a1400eb650604e87a3b616b6d7e3207d3a6ae4944f`.
Actual mouse checks verified the visible header X and closure, single-player
Victory Progress without the three proposal controls, and Leopold II's leader
and trade screens without the gray missing-scene message. Trade Back and Goodbye
worked. Normal Exit/Yes returned code 0, no signals, and verified cleanup.

Its raw status says `failed-early-exit` because the supervisor observed the process
disappear before Popen supplied its exit code. The raw report is preserved and
the supplemental validation records the observed normal exit. The classifier
now waits for an actual process status; its regression tests distinguish pending,
normal manual exit and nonzero exit. Standard native verification passed; EUI
verification of these new presentation changes remains open.
