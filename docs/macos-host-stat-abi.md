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
