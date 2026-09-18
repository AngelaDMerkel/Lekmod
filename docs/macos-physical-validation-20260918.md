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
