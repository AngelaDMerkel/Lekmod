# Lekmod macOS native port

This directory builds and installs Lekmod for Aspyr's 64-bit Steam release of
Civilization V. The game itself is Intel-only, so the library intentionally
targets `x86_64`; Apple silicon runs both through Rosetta 2.

The port matches the stock `libCvGameCoreDLL_Expansion2_DLL.dylib` ABI:

- deployment target macOS 10.11.6;
- install name and dylib version 1.0.0;
- `DllGetGameContext` as the only exported symbol;
- Aspyr's legacy TR1 container sizes and macOS-only `ICvPreGame1` slot;
- the complete GameCore and Lua source list used by the Windows project.

## Build and validate

```sh
./build-macos.sh
./validate-macos.sh --app "/path/to/Civilization V.app"
```

Output is written to
`build/macos/libCvGameCoreDLL_Expansion2_DLL.dylib`. To create a redistributable
directory under `build/macos/package`, run `./package-macos.sh`.

## Install

Quit Civilization V, then run:

```sh
./install-macos.sh
```

The installer finds the default Steam app, configures standard UI or detects
EUI, installs the Lekmod DLC data, backs up Aspyr's original GameCore library,
and ad-hoc signs the replacement. Use `--app` for a non-default location,
`--standard` or `--eui` to force a UI mode, and `--uninstall` to restore the
original library.

Steam's “Verify integrity” operation restores Aspyr's library, so rerun the
installer afterward.
