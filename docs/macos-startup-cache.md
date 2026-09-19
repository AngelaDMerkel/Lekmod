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

`20260916T103743Z` reproduced the nonempty merged-cache attach failure with the
new friendship diagnostics. The merged file was again 25,509,888 bytes and passed
quick_check; twenty cache files/hashes are preserved under
`build/macos/cache-investigation/20260916T103743Z/`. POSIX opens of the merged file
and its journal succeeded before the attach error, without a further recorded
POSIX open at the failure. There were 122 descriptors under the 10,240 limit.
The unchanged retry `104454Z` reached gameplay and exited normally with the cache
left intact. This narrows the evidence but does not identify or fix the underlying
startup failure.

## September 18 diagnostic control

`20260918T013230Z` failed before the menu with the same `ATTACH ? AS
Localization` error: 122 open descriptors under a 10,240 limit, successful
merged/journal POSIX opens, and a nonempty 25,509,888-byte merged database that
passed quick_check. Twenty-one cache files and hashes were preserved under
`build/macos/cache-investigation/20260918T013230Z/`; no healthy file was deleted.
Unchanged retry `013348Z` left a zero-byte merged database, with missing
Languages/LocalizedText. Its fifteen cache files were preserved separately.
The guarded empty-cache repair retained that zero-byte file before removal.
`013510Z` still failed regeneration; its empty merged file was likewise preserved
under `build/macos/cache-repairs/20260918T013510Z/`. Both empty backups have
SHA-256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.

The runner now offers an explicit `--activation-only` diagnostic control. It
retains the existing background activation guard while compiling out syscall/CF
stream interposition and the stdout/stderr flush timer. The default diagnostic
mode is unchanged, and the selected mode is recorded in each report. A real
x86-64 subprocess confirms no `__interpose` section, unchanged exit 42, and
unflushed buffered bytes after a running dispatch loop; all existing observer
return-value/errno/exit/CF-stream tests continue to pass.

After guarded empty-cache recovery, activation-only run `013746Z` reached the
Venice game. Its final scenario assertion remained buffered, so the supervisor
reported a stall; this is not a functional pass. `014048Z` used explicit failed
verdict retention plus normal diagnostic save/exit to flush its evidence. It
confirmed the duplicate-Venice gameplay defect, exited 0 with the real exit
confirmation and no signals, and restored settings/hooks/manual saves. Both
controls passed startup, but two successes do not establish that the observer
caused the intermittent failure or resolve its root cause.

## Controls without observers, and ordinary startup settings

`20260918T020756Z` again failed the merged-cache attach before loading a saved
game. The 25,509,888-byte cache passed quick_check; its SHA-256 is
`44283d3d3fa2cb5ce96b696fde3e1771e4b62b78bcf89e8c3d90a16ff0eb0332`,
and all cache files/hashes are preserved under
`build/macos/cache-investigation/20260918T020756Z/`. The activation-only retry
`021045Z` failed and left an empty merged cache. Following guarded preservation
and removal of that empty file, activation-only `021357Z` failed again.
Explicitly authorized foreground control `021800Z`, with no injected test
library at all, also failed before the menu. This establishes that neither the
file/stream observers nor the background activation guard is required for the
failure. It does not identify the underlying host/cache trigger.

`native-startup-control.py` provides an ordinary foreground comparison with no
temporary UI hooks, no configuration changes before launch, and no injected
library. It requires an explicit authorization flag, an unlocked desktop, a
running signed-in Steam session, no existing Civ V process and a bounded timeout.
It preserves settings and verifies original manual-save hashes afterward.
In `native-startup-controls/20260918T022247Z`, the normal opening movie appeared.
An actual Escape key dismissed it; the main menu appeared, and actual Exit/Yes
clicks closed the game with return code 0 and no signals. No settings changed.
The regenerated merged cache was 27,500,544 bytes. See the separate physical
report; surviving startup alone is not a gameplay pass.

The scripted runner had forced QuickStart=1 and SkipIntroVideo=1. Those settings
are now independently selectable and reported. `022855Z` used QuickStart=0,
SkipIntroVideo=1, foreground mode and no injected test library: the pending
great-person save matched exactly and saved/exited normally. Two background
controls `023119Z` and `023231Z` repeated that exact reload with the full normal
observers enabled, QuickStart=0, and the healthy cache left intact. Both passed.
`023447Z` then passed a fresh Industrial/Duel Venice game under the same startup
configuration, including normal exit and preservation checks.

The runner therefore defaults to QuickStart=0, using its existing normal
main-menu Start/Load callbacks. QuickStart=1 remains available explicitly for
diagnostics. No gameplay, RNG, synchronization or wait flag is changed. These
controls remove an unnecessary test setting and establish several successful
ordinary-menu paths; cache state/timing also differed between attempts, so they
do not prove QuickStart is the sole cause or that the intermittent failure is
fully fixed. All failed runs remain in the evidence. Twenty-seven offline runner
guard/classification cases pass.

## Recurrence with QuickStart disabled; loader and stock controls

`20260918T040816Z` reproduced the localization attach failure with QuickStart=0,
so changing that test default did not eliminate the issue. Its nonempty cache
was preserved under `build/macos/cache-investigation/20260918T040816Z/`.
`041455Z` repeated the failure with dyld image tracing enabled and left an empty
merged cache. The trace contained 899 image-load records and no GameCore image
before exit 255. This places that occurrence before the modded GameCore loaded;
it does not separate mod localization data from an Aspyr host/cache defect.
The empty cache was preserved using the guarded recovery tool.

The central installer temporarily restored stock (canonical hash unchanged).
`native-startup-controls/20260918T042052Z` then used original configuration, no
UI hooks and no injected library. Actual Escape, copyright-notice Continue,
Exit and Yes actions reached the stock menu and closed normally: return 0,
229.0 seconds, no settings changed and all original manual saves preserved.
The exact movement-cost test package was reinstalled through the central
installer; its signed GameCore again matched
`cf5273574eb622c53b700d6a0dbfa1e2ff882f5475d4c9a486aa4cdac740e798`.
This was a menu-only comparison and loaded no modded save under stock.

The subsequent traced Lekmod run `042603Z` started a Huge/12-major/41-minor
world and completed its two-turn functional case, save and normal exit. Its
trace does contain the expected GameCore image, confirming that the failed
trace would have recorded it. Exact reload `042735Z` also exited normally.
The stock comparison and successful restoration are controls, not proof of a
root-cause fix; cache content and timing changed during the comparison.

## Separate shutdown stall

`20260918T030901Z` passed its two-turn science-disabled assertions and wrote
its save, then stalled after the real exit confirmation. The retained sample
shows the Aspyr main thread in `pthread_join`, while SDLTimer waits in
`std::future<void>::get`. The supervisor ultimately used SIGTERM. This run
remains failed; no wait flag or synchronization check was altered. Its saved
state reloaded exactly with normal exit in `031725Z`; an unchanged fresh-case
retest `032102Z` and exact reload `032239Z` also exited normally. The single
shutdown stall remains an unresolved intermittent host-path observation.

## Read-only host error observation

The process-local observer now resolves Aspyr's exported `GetLastError` and
records its current thread-local value when a database failure is logged. It
does not clear the value, retry the failed operation or alter exit status. Two
offline subprocess tests pass, including a known exported error value of 1234
and the existing exit, stream and activation-only preservation checks. Native
quicksave run `20260918T053742Z` used this observer successfully but encountered
no startup failure, so it supplies no host-error value for the unresolved defect.

`20260918T062317Z` failed before its EUI Great Work save loaded: native exit
255 after 20.4 seconds. Both database-failure records reported host error value
0, with 122 open descriptors and a 12,544 soft limit. This does not identify a
host error or explain the localization failure. The temporary EUI wrapper
restored standard payload/text/options; settings and manual saves were preserved.
A post-cleanup read-only inspection found the merged cache absent. No manual
cache deletion or empty-cache repair was performed for this attempt.

`20260918T070926Z` repeated the shutdown-stall pattern after a passing exact
Mexico visibility reload and normal Exit confirmation at 52.7 seconds. The
supervisor's `stall.sample.txt` shows the Aspyr main thread in `pthread_join`
and SDLTimer in `std::future<void>::get`, matching the earlier `030901Z` pattern.
No active GameCore frame appears in those blocked paths; this does not establish
the original cause. At 153.7 seconds the supervisor sent SIGTERM (return -15),
restored settings/hooks and preserved manual saves. A later manual sample request
found the owned process already closed and collected no additional sample.
Separate retry `071357Z` passed exact reload and normal exit 0; the stalled run
remains failed evidence. No wait flag was changed or successful exit fabricated.

The Hacienda attempts `20260918T073937Z`, `074200Z` and `074503Z` each failed
during localization startup before any scenario action. The first retained a
25,509,888-byte merged cache with localization tables and a passing SQLite
quick_check. All 21 cache files were preserved under
`build/macos/cache-investigation/20260918T073937Z`; that healthy cache was not
deleted. The second and third attempts left zero-byte merged files, separately
preserved by the guarded repair tool under their matching `cache-repairs`
directories before retrying. All failures restored hooks/settings and preserved
manual saves. An activation-only background comparison was then initiated.

Activation-only comparison `20260918T074705Z` also failed before gameplay with
exit 255 after 20.4 seconds and an empty merged cache. That file was preserved by
the guarded repair. Original-settings foreground control
`native-startup-controls/20260918T074840Z` then used no injected library or UI
hooks and changed no settings before launch. Actual Escape skipped the movie;
the main menu appeared. Actual Exit/Yes returned 0 after 150.7 seconds, with no
settings changed by the game and all manual saves preserved. Its menu screenshot
SHA-256 is `b231b50cbf8a08dce8a3f24223f8743bc4666c9896552d837ea7bc71feba5e93`.
The merged cache regenerated to 27,500,544 bytes. The next full-observer background
run `075215Z` reached gameplay, where its resource-placement fixture failed.
This does not isolate one cause: original settings, fullscreen, activation and
hooks differed between the controls. Startup reliability remains unresolved.

Philippine movement reloads `20260918T092553Z` and `092829Z` failed with exit 255
before loading their save. The first retained a healthy 25,509,888-byte cache;
its 21 files and passing merged quick_check were preserved under the matching
`cache-investigation` directory. The next failure left an empty merged cache,
preserved by the guarded recovery under `cache-repairs/20260918T092829Z`.

Foreground control `native-startup-controls/20260918T093746Z` changed only
`DEBUG.LoggingEnabled` from 0 to 1. All other settings, fullscreen behavior and
UI files remained original; no library was injected. Actual Escape skipped the
movie, the menu appeared, and actual Exit/Yes returned 0 after 208.9 seconds.
The game changed no settings beyond the explicit input; the original bytes and
all manual saves were restored/preserved. This single successful comparison
does not identify the intermittent trigger. Its menu screenshot hash is
`b231b50cbf8a08dce8a3f24223f8743bc4666c9896552d837ea7bc71feba5e93`.

The first request for this control was rejected by automatic approval review
using the historical one-session limit. No part of that rejected command ran.
After the user's later explicit foreground-restoration and unlimited-duration
messages were quoted, the same action was approved. No permission block remains.

`20260918T100336Z` matched a Gerilya land-state reload but stalled after normal
Exit confirmation. Its retained `stall.sample.txt` again shows main-thread
`pthread_join` and SDLTimer `std::future<void>::get`; the supervisor used SIGTERM
and restored settings/hooks/manual saves. A separate retry passed. This third
matching sample strengthens the recurring shutdown observation but does not
identify its cause or justify bypassing synchronization.


`20260919T025740Z` reproduced startup exit 255 at 20.4 seconds before any Māori
gift action. Database.log again reports failure to attach the merged localization
cache. The host error observer returned 0; descriptor usage was 122 against a
soft limit of 10,240. A 25,509,888-byte cache retained its localization tables and
passed SQLite quick_check. All 21 files and hashes were preserved under
`build/macos/cache-investigation/20260919T025740Z`; no healthy cache was removed.

The same fixture/artifact with only the runner's intro-skip setting changed to
0 reached gameplay in `20260919T030214Z`. No foreground activation or physical
input was used; the owned-window capture shows gameplay at turn seven. Native
gift checks then exposed a separate ownership bug, so the overall scenario is
FAIL despite normal save/exit 0 at 264 seconds. Settings/hooks/manual saves were
restored. The cache became 27,500,544 bytes. This successful startup comparison
does not isolate the intermittent cause: the first attempt had already processed
cache state, and one successful retry is insufficient. Startup reliability
remains open.
