# Native startup control: 2026-09-18 UTC

Scope: the current Mac (macOS 26.5.2, build 25F84), standard UI, existing
managed Italy/Venice test package. Foreground permission was renewed by the
user for sessions as long as required. This was single-player startup/menu
coverage; no multiplayer screen was opened.

Evidence directory: `build/macos/native-startup-controls/20260918T022247Z/`.
The supervised game PID was 57713. The tool changed no configuration or UI
files before launch and set no injected process library. The opening movie
was visible; an actual Escape key skipped it. The loading screen transitioned
to the native main menu. Actual mouse clicks selected Exit and then Yes in
the displayed confirmation dialog. CUA reported that the app quit. The
supervisor independently recorded return code 0, 230.2 seconds, no termination
signals, no settings changed by the game, and all original manual-save hashes
preserved. This is physical keyboard/mouse evidence, not scripted callbacks.

The saved main-menu screenshot is `main-menu.png`, SHA-256
`b231b50cbf8a08dce8a3f24223f8743bc4666c9896552d837ea7bc71feba5e93`.
The report records the exact original configuration bytes and save hashes.
The later foreground great-person reload `022855Z` was scripted and is not
additional mouse coverage. Startup reliability remains qualified by the
[cache investigation](macos-startup-cache.md).

## Stock menu comparison

The managed installer temporarily selected the stock GameCore and payload.
Evidence: `build/macos/native-startup-controls/20260918T042052Z/`, PID 67721.
Original settings/UI were used with no injected library. Actual Escape skipped
the opening movie; an actual click dismissed the non-binding copyright notice.
The stock main menu was visually verified. Actual Exit/Yes clicks closed the
app, with return code 0 and no termination signals. The 229.0-second control
changed no settings and preserved all manual-save hashes. No game was loaded.
The exact Lekmod movement-cost archive was then reinstalled with its expected
signed-core hash. Steam's channel/session and Aspyr backups were preserved.

`stock-main-menu.png` SHA-256:
`7fa8be6cb7e33c4391fc1f61d5a167e63f50ed7e1e399faeddcb0ccb96ee2782`.

## Physical quicksave and quickload

`20260918T050401Z` used real F11 and Ctrl+F11 on the preserved worker fixture.
The initial quicksave was created at
`Saves/single/quick/QuickSave.Civ5Save`; no quicksave existed before this test.
Actual city clicks changed Food Focus/Avoid Growth, and quickload restored the
original complete observed state without advancing turn 8. Exit-to-Windows/Yes
were physical clicks; process exit was 0 and restoration/preservation checks
passed. Its two local screenshot captures proved to be thin 3024×66 title-bar
windows, so those files are not visual evidence for the city controls. The CUA
views and observer records remain, and the stronger repeat below supersedes the
local capture evidence.

The capture helper now filters both width and height and selects the largest
window belonging to the game PID. An offline regression rejects an unrelated
process's larger window and the game's thin title bar.

`20260918T053742Z` repeated the workflow with a distinct marker. Actual city
clicks selected Production Focus and Avoid Growth before F11. The quicksave
therefore differed from the original default-focus/growth-enabled fixture.
Actual clicks then restored Default Focus and unchecked Avoid Growth without
saving. Ctrl+F11 restored Production Focus/Avoid Growth and the exact recorded
city/unit/queue/yield/treasury state at turn 8. The save file itself was unchanged
by loading. The complete 2560×1656 frame was captured and visually inspected.

Quicksave SHA-256:
`9ef8ba467989a1874a8802e6cc82fd063ca5c8e5e1836f44221624ee1ec6f951`.
A copy is retained as `QuickSave-distinct.Civ5Save` in the run directory.
`distinct-quickload-verification.json` and `physical-quicksave-validation.json`
contain the state comparison and screenshot hashes. The original test quicksave
is also preserved in `050401Z/QuickSave-before-load.Civ5Save`, SHA-256
`960e6a6e278bee3e1c96c6be024baac42ba58b31bfa5a541a361ad4d0584b63d`.
Only that hash-verified test slot was overwritten for the second test.

Physical Return/Escape/Exit to Windows/Yes completed normal exit 0 after 434.0
seconds, with no signals. Settings, graphics, hooks and all original manual
saves were preserved, with no Lua or synchronization failures. The legacy
`ui-interaction` CLI still returns 1 for `ended-manual-ui-session`; the native
process code and supplemental physical checks establish the result. This is
actual keyboard/mouse coverage, not invocation of the quicksave/load callbacks.

Intervening `051401Z`, `051804Z` and `052310Z` failed during localization startup
before loading the fixture. `051804Z` kept the opening movie enabled and used
a real Escape key; the failure still occurred. Their reports and cache backups
remain separate failed evidence.
