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
