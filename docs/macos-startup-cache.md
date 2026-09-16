# Startup exit 255: localization-cache evidence

The failures in `20260914T024711Z`, `20260914T043639Z`,
`20260916T001510Z` and `20260916T001834Z` occurred before the menu, around
20 seconds after launch, without an OS crash report. Each retained Database log
contains a failure opening/loading the merged localization database. The last
run also reports missing Languages and LocalizedText tables.

The test-only process observer captured `_exit(-1)` in the last run. Offline
inspection of the Aspyr executable identifies its ordinary termination path;
this is not evidence of a GameCore crash. The immediate error is in the retained
database/localization logs. The runner's original `exit()` observer alone could
not capture this path; the extended observer preserves both exit functions'
statuses, verified with six real x86-64 subprocess cases.

The current merged cache was zero bytes, with no SQLite tables. The source
localization databases passed quick checks. Disk space and the file-descriptor
limit were sufficient. Before intervention, the entire cache and its file hashes
were preserved locally at:

`build/macos/cache-investigation/20260916T002558Z/`

Only the empty `Localization-Merged.db` was removed. The unchanged installed
archive `Lekmod-league-choices-20260916.zip` (SHA-256
`d46d4784a9d4fbbf47d532e5302f3259e9e74aadd56b862d1097aee6cbf78b25`)
then started successfully in `20260916T002602Z` and generated a
27,500,544-byte merged cache with the expected tables. The subsequent
`20260916T003735Z` also started successfully without another repair.

This identifies the immediate failure and verifies recovery from the empty
cache. The original failed cache creation/open remains under investigation.
Do not treat successful retries as proof that the original trigger is fixed.
The earlier failures remain failed evidence.

## Bounded recovery tool

From the Lekmod checkout, read-only inspection is:

```sh
python3 LEKMOD_DLL/macos/repair-localization-cache.py
```

With Civ V closed, explicitly preserving/removing a confirmed zero-byte merged
cache is:

```sh
python3 LEKMOD_DLL/macos/repair-localization-cache.py --repair-empty
```

The tool saves the empty file and a manifest under `build/macos/cache-repairs/`.
It refuses nonempty files, symlinks, SQLite sidecars and a running game. It does
not launch/retry Civ V, change source databases, alter saves, touch Aspyr backups
or modify any gameplay/synchronization flag. Six offline tests cover inspection,
preservation and refusal boundaries. A nonempty malformed cache needs inspection;
this tool deliberately does not delete it.


## Nonempty-cache failure and scoped diagnostics

`20260916T062914Z` reproduced exit 255 at 20.4 seconds after an English
localization text update. The write observer captured the failure on the
localization worker thread. Offline disassembly places the return address
`0x10048b4c7` immediately after `Database::Results::Execute()` for
`ATTACH ? AS Localization`. The merged database was 25,509,888 bytes and passed
SQLite quick_check with its expected tables present. This was not another
confirmed empty-cache case. All twenty cache files and hashes were preserved in
`build/macos/cache-investigation/20260916T062914Z/`; no cache file was deleted.

The process observer now reports the actual RLIMIT_NOFILE and open-descriptor
count at startup/database failure, and observes limit changes without changing
their requested values or results. `20260916T065002Z` observed an inherited soft
limit of 1,048,575, then the executable successfully set 10,240. That separately
recorded attempt reached gameplay with unchanged product bytes and the healthy
cache intact. This does not resolve the original startup cause.

The test helper previously called `fflush(NULL)` once per second, which affected
unrelated buffered streams. A real x86-64 probe under its dispatch timer reproduced
that side effect with the committed old helper; its output is retained beside
the cache snapshot. Flushing now covers stdout/stderr and identified files under
Logs only. The same probe preserves unrelated buffered database bytes, while the
existing exit/status and database-write tracing cases still pass. Narrowing the
instrumentation is not proof that global flushing caused the startup failures.

## Recurrence after scoped logging

`20260916T081444Z` reproduced the same attach failure and exit 255 at 20.4
seconds while loading the Palmyra regression fixture. The observer recorded a
10,240 descriptor limit and only 122 open descriptors at the failure, excluding
ordinary descriptor exhaustion in this occurrence. The scoped logger was active,
so removing global fflush did not resolve the startup defect. The 25,509,888-byte
merged database again passed quick_check and retained its localization tables.
All twenty cache files and hashes were preserved in
`build/macos/cache-investigation/20260916T081444Z/`; no cache was deleted.

A test-process-only open/openat/fopen observer now records localization paths and
OS errors, preserving the original results, flags and errno without retrying an
operation. Real x86-64 probes cover successful create/read and missing-file
results for all three calls, in addition to the six exit paths and buffered-file
preservation checks. This instrumentation seeks the underlying open failure;
it is not a product fix or evidence that startup is reliable.

The unchanged retry `20260916T081937Z` also failed, this time with a zero-byte
merged database and missing tables. POSIX tracing recorded ENOENT on its first
open and a successful subsequent open; that does not establish which higher-level
operation failed. Aspyr imports CF file-stream APIs. The observer now correlates
localization stream creation/open calls and records their actual CF errors;
real x86-64 read/write/error probes preserve both data and return values.

Only that confirmed empty generated cache was preserved and removed using the
bounded repair tool. Its backup is
`build/macos/cache-repairs/20260916T081937Z/Localization-Merged.db`, SHA-256
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
Healthy source databases, manual saves and Aspyr backups were left intact.

`20260916T082254Z` then rebuilt the merged cache and reached the same Palmyra
fixture successfully. POSIX tracing observed successful merged-database/journal
opens; this attempt produced no correlated localization CF-stream records.
The gameplay run saved/exited normally with cleanup. Successful regeneration
again establishes recovery, not the original failure's root cause.
