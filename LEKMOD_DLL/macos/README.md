# Lekmod macOS native DLL port

This directory contains the macOS-specific source and build glue for Lekmod's
`CvGameCoreDLL_Expansion2` implementation. It belongs in the Lekmod repository,
not in MPPatch.

The target is the Aspyr 64-bit Intel Civilization V runtime. The resulting
Mach-O library must export `DllGetGameContext` and use the same C++ ABI as the
game's stock `libCvGameCoreDLL_Expansion2_DLL.dylib`. The shipped game executable
provides the engine, database, localization, Lua, heap, file, and timing symbols;
the port links those with `-undefined dynamic_lookup`.

Status: experimental and not installable yet. The platform ABI shim and native
constructor/destructor entry points are present. The legacy Firaxis containers
are being made acceptable to Clang without changing their object layout.

Run `./build-macos.sh` from this directory. Output is written to
`build/macos/libCvGameCoreDLL_Expansion2_DLL.dylib`.

