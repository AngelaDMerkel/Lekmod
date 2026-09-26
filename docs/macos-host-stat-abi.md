# Host SQLite stat ABI correction (experimental)

The pinned Aspyr x86-64 host dynamically resolves unversioned `lstat`, but its
SQLite path resolver consumes the current Darwin `struct stat`:144 bytes with
mode at offset4. Legacy `lstat` instead writes inode bits at offset4 and mode at
offset8. Some regular files therefore appear to be symbolic links. The host then
calls readlink on a regular file, receives EINVAL, and cannot attach the database.
This path executes before the modded GameCore is loaded.

Host SHA-256: `d56d6bfbc0ef517fcb7cbaff46c42d1bdfab809c084684045761bd9d85807ee9`.
Mach-O UUID: `0C91A3DE-65CB-3122-89F3-D0AE896C8395`.
The native stack contains wrapper return0x1001b9e60 followed by SQLite return
0x1001e1000. At0x1001e1020 the consumer reads buffer offset4 and compares the
masked type with0xa000. The disassembly and passive traces are retained under
`build/macos/startup-descriptor-20260926/`.

## Native controlled reproduction

`build/macos/startup-stat-fix-20260926/process-20260926T221523Z` reached the ordinary
menu, then used the game's own SQLite3.25.0 database interface to attach the exact
preserved healthy database with inode32743892. Its legacy bytes appeared as
mode0120724; readlink failed with errno22 and the schema was not attached. Native
exit0/restoration passed. The database SHA-256 remained
`7e74326a3b020ea97422eda3ce95c0f3f1a2b02216ed2589d23aefaf4b003efe`; no sidecars appeared.
No SQL data-write statement was issued. The known-good database's byte contents
were not a cause of that attachment failure.

Earlier `process-20260926T221310Z` tried a read-only URI filename. This host treats
that URI as an ordinary relative path; its failure was ENOENT, not the ABI
reproduction. It is retained but not counted as such.

## Scoped prototype

`LEKMOD_DLL/macos/host-stat-compat.c` is an experimental process-local interposer.
It validates the main image's x86-64 identity, UUID, executable text bounds and
verified instruction bytes. It requires both known host/SQLite frames in order.
Only that call path receives the current SDK lstat ABI. Unknown images, changed
instructions and other legacy callers retain the original ABI. Genuine symlinks
and native errors are preserved. There is no file retry, native result override,
code patch, access-flag change, synchronization bypass or GameCore wait-flag change.
The correction changes which ABI supplies the requested metadata, not whether a
native operation is permitted.

`test-host-stat-compat.py` exercises image/call-site rejection, legacy byte/errno
pass-through, current-layout regular files, genuine symlinks and missing paths.
It also injects the compiled library into an unrelated x86 process and verifies
that legacy behavior is unchanged. These checks pass; the same native attachment
probe with correction enabled also passed as recorded below. No permanent host executable,
Steam launch setting or installed launcher has been changed.

The diagnostic controller is
`build/macos/startup-stat-fix-20260926/run-file-probe.py` (`--correct` enables the
prototype). It checks the full host/package/database hashes, refuses locked or
already-running sessions, records source hashes, restores UI/settings/stock, and
verifies the database and executable afterward. It is a menu/database probe,
not gameplay or physical mouse coverage. A validated deployment path remains separate from the experimental correction.

## Corrected native comparison and functional validation

`process-20260926T221641Z` used the same host, product package, preserved file/inode
and plain-filename query as the native failing control. Only the scoped correction
was enabled. The game attached the database, quick_check returned ok, the schema
was detached, and native menu/exit callbacks returned0. The correction was observed
on the verified call path. Database bytes, absence of sidecars, host executable,
UI/settings/manual saves and stock restoration were verified. The native before/after
comparison is `build/macos/startup-stat-fix-20260926/native-comparison.json`.

The test runner and batch wrapper now accept explicit `--host-stat-compat`. They
verify the full host hash before native work, record source/library hashes, exclude
the passive observer's competing legacy interposition, and require observed
correction calls before accepting a passing corrected run. The option is off by
default and cannot be combined with uninjected or activation-only controls.
Runner33/batch26 regression tests pass. Comprehensive native run
`20260926T222217Z` passed all81 functional assertions and16 exact state replays in
875seconds, observing32 corrected calls. It used23 aggregate turns across
independent fixtures; the accepted long campaign remains closed. Independent
verification confirms all32 original/copied checkpoint pairs,639 prior manual
saves, the original quicksave, settings,32 stock UI files, unchanged executable
and both stock GameCore backups. The game exited normally with no recorded Lua
errors, synchronization failures or new crash diagnostics. This is scripted
functional/native outcome coverage, with no added physical mouse coverage.
Evidence: `build/macos/host-stat-fix-validation-20260926.json`.

The user selected WSDLC integration for ordinary Steam Play. The installer must
own the startup correction, verify its supported host, preserve the original
executable and restore it when returning to stock. This integration and a real
Steam Play launch remain to be validated.

This establishes a native correction for the reproduced database attachment fault.
It does not establish production launcher integration, all startup/shutdown causes,
or complete single-player support. Nothing has been pushed or permanently injected
into Steam or the game executable.

## WSDLC installation and restore validation

Local WSDLC commit `562e490` installs a fixed dependency on
`@executable_path/libWirCiv5HostStat.dylib` into verified unused header space,
ad-hoc signs the prepared executable, and includes both executable and library
in its existing transaction. All161 WSDLC tests pass, including interrupted
installation/restoration, updates, Steam restoration, tampering, backup and
symlink rejection. A real disposable executable copy passed signature verification
with its entire text/code region unchanged. The original is retained as
`stock-executable` in WSDLC's application-specific state directory.

Lekmod packaging commit `5b1ed586` produces the local corrected archive
`build/macos/Lekmod-steam-startup-20260926.zip`, SHA-256
`edd00aa4d8eca910ee90777465e6db7eeae92b02aa2bff709f44fdb06b529002`.
Its GameCore/DLC are byte-identical to the earlier Romanian package. The signed
startup library SHA-256 is
`26ea4333dc03556123db796217745d129fe4b8a7c2c11f9cedb27db47bb5f080`;
the installed executable SHA-256 is
`d1fef99d7de4e896ec1ebf9707d636628d9b82af539b32209bc268c9af708e86`.
Steam launch settings were not changed, and no separate shortcut is needed by this
integration.

`build/macos/startup-stat-fix-20260926/installed-20260926T225114Z` used WSDLC to
install this archive and repeated the preserved bad-inode database probe. The
correction loaded through the executable dependency; no correction library was
supplied in DYLD_INSERT_LIBRARIES. The passive background observer was still
injected and the menu/exit/database callbacks were scripted. The native probe
attached the unchanged database, returned quick_check=ok, detached, exited0 and
restored all temporary hooks/settings, prior manual saves and stock. WSDLC restored
the original executable's exact SHA-256. No new crash diagnostic appeared.

## Actual Steam Play verification

After the user brought the Steam Library forward, actual clicks on Steam Play
and the ordinary Aspyr launcher Play opened native PID91329. The game reached
its main menu and loaded the existing
`Lekmod-Batch-20260926T222217Z-battalion-reload.Civ5Save` through Single Player →
Load Game → Continue Your Journey. Its SHA-256 is
`2752c7ac7ba57c9feeea6e0467a571fbe95a4415306e6a4c534ed918b9cbfc6a`.
The visible world showed turn3/3820BC,500 gold, and a Maori Battalion with70
strength and2/2 movement. This confirms normal launch, native save loading and
rendered Lekmod state; it adds no turn/combat or exact-state comparison claim.

No Steam launch options, test UI hooks or injected process libraries were used.
Read-only vmmap output confirms the installed correction and native GameCore were
loaded. Actual Menu → Exit to Windows → Yes ended the process normally; a
read-only kernel process-exit watch recorded wait status0, exit code0 and signal0.

The initial black Steam capture and later fullscreen CUA click errors are retained
as control failures, not game failures. Following explicit user approval for an
alternative native input method, a small guarded macOS mouse helper was built in
the evidence directory. It requires the expected game PID/bundle/executable to
be frontmost, an unlocked console session and existing event permission. It
changes no game APIs, synchronization checks or wait flags. Screenshots guided
every successful mouse action. The earlier recorded native interface was CUA;
this standalone fallback was newly prepared for the authorized test.

WSDLC restored the original executable and GameCore exactly and removed its owned
startup library. All672 prior non-autosave files, settings,32 stock UI files and
both GameCore backups remain unchanged. No new crash report appeared. Civ V is
closed and stock is active. Steam was not restarted or reconfigured.
Evidence: `build/macos/steam-play-20260926/report.json` and
`build/macos/wsdlc-startup-validation-20260926.json`; the loaded-world screenshot
is `build/macos/steam-play-20260926/loaded-game-menu.png`.

This validates normal Steam launch on the current Mac for this exact local
package/host. It does not establish other platforms, every startup/shutdown case,
or complete single-player support. Nothing was pushed or released publicly.
