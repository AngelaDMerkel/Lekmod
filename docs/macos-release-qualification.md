# Current-Mac release qualification

## Latest fixed-content candidate (2026-09-22 UTC)

The later 125-unit catalogue exposed a missing Tunisian Privateer flag that
blocked the native renderer with a texture-load dialog. It is fixed in
`0049e794`; all 125 unique-unit creation and normal removal/refund cases, plus
their exact reloads, passed on the corrected contents. See
[the full evidence and limitations](macos-unit-catalogue.md).

Clean-source archive:
`build/macos/Lekmod-release-candidate-tunisian-fixed-20260922.zip`.
SHA-256: `f1a88db4b2f33def33ba263be95915eae401da3af2239a31fceb2cfacffcc64c`.
Source: `e1d859c82372ab8e73c3b35e87f0d3757a17d749`, `dirty: false`.
Core: `4e1a94b9ea8c61c16e18e2bc32a6f46a54941c056bb804b14cfd4c8066bc764b`.
Payload: `094d1dcf9635d2d8392fd49bbe7c9a88dadf1767813f5383f0ddf6b708e19a3e`.
The core and payload hashes match the native-tested intermediate archive. The
clean archive was subsequently installed and exercised in replay pilot
`20260922T233116Z`: both pinned state comparisons passed in one process, with
normal exit/cleanup and stock restoration. See the [matrix report](macos-civilization-start-matrix.md).

Stock/backups, 422 prior manual saves, quicksave, settings and 33 stock UI files
were verified after restoration. No game/test is running. The remaining normal
civilization-start/replay matrix is [prepared but not commissioned](macos-civilization-start-matrix.md).
Broader unique abilities and the intermittent startup/shutdown investigation
remain open. The earlier batch qualification below is retained as historical
scoped evidence; it does not erase the subsequently discovered texture defect.

## Clean artifact and complete batch

The full comprehensive batch passed on a package built from clean source commit
`f40fd2b25e016bde2b468e34ba0a45b34bb6e1e6`. The package manifest records
`source.dirty: false`. The full (non-incremental) build log is
`build/macos/release-clean-build-f40fd2b2.log`.

| Artifact | SHA-256 |
| --- | --- |
| `build/macos/Lekmod-release-candidate-f40fd2b2.zip` | `e6904b434b3a3a7bebea4c2a83d1709c3aaf73d55a096237b6ed87f07fefcffc` |
| Signed GameCore | `4e1a94b9ea8c61c16e18e2bc32a6f46a54941c056bb804b14cfd4c8066bc764b` |
| Payload manifest digest | `cd1d6b65bbbaaec3dddc61d7970c1e25faa81984456337d640e80ebcbe76f818` |

Shared compatibility is pinned to `1663b23bdfa0b79f431c7ff437c6851581efa219`.
The core and payload match the earlier optional-control package; this archive
also has clean-source provenance. Its original manifest remains unchanged
(`runtime_validated: false` is a packaging-time field, not this later test verdict).

Managed invocation:

```sh
python3 LEKMOD_DLL/macos/batch-playtest.py --plan comprehensive --minutes 60 \
  --package build/macos/Lekmod-release-candidate-f40fd2b2.zip \
  --sha256 e6904b434b3a3a7bebea4c2a83d1709c3aaf73d55a096237b6ed87f07fefcffc
```

Run `build/macos/playtests/20260921T002839Z` (native PID 51676) completed all
**16 scenarios, 81 declared functional checks and 16 exact checkpoint reloads**
in one process. Native-run duration was **813.7 seconds**, with **23 ordinary
functional turns** across independent fixtures. Its final status is
`passed-scenario-checks-only`; native exit was 0 and normal exit was verified.
All 32 checkpoint files were independently rehashed against their recorded hashes.
There were no Lua runtime errors, RNG mismatch, forced resync, protocol errors or
new crash/hang diagnostics. Settings, temporary hooks and prior manual saves were
preserved. The wrapper restored stock.

Evidence:

- `build/macos/batch-release-candidate-f40fd2b2.log`
- `build/macos/playtests/20260921T002839Z/report.json`
- `build/macos/playtests/20260921T002839Z/batch-report.json`
- `build/macos/release-qualification-20260921.json` (manifest metadata and all
  checkpoint paths/hashes)
- `build/macos/release-stock-verification-20260921.json`

This is an actual all-green full-plan run, separate from the earlier failed
commissioning attempts and targeted retests. Those original failure verdicts
remain unchanged. The run uses scripted setup/commands, scoped callback checks
and native gameplay outcomes as documented by each scenario. It adds no physical
mouse coverage and is not a naturally progressed long campaign.

## Controlled startup and shutdown reliability

The first attempt was refused before launch because the desktop was locked;
its log remains `build/macos/lifecycle-release-candidate-f40fd2b2.log`. A subsequent
mistyped fixture hash was also rejected before installation/launch. Neither is a
native test result.

After unlock, **all five cycles passed** in
`build/macos/lifecycle-tests/20260921T011003Z/report.json`. Native runs were
`20260921T011008Z`, `20260921T011107Z`, `20260921T011203Z`, `20260921T011259Z`, `20260921T011354Z`. Durations were 57.0,
54.9, 54.9, 54.9 and 54.9 seconds. The first cycle ran inventory checks; the
remaining four exactly compared the same fixture state with that first result.
All five saved and exited normally, restored settings/hooks, preserved prior
manual saves, and had no Lua/synchronization errors or new diagnostics. Stock
restoration returned 0. The wrapper log is
`build/macos/lifecycle-release-candidate-f40fd2b2-resumed-2.log`.

The first managed launch began without a merged cache and created a
27,500,544-byte file. Its SHA-256 was
`79a26afd7d720159152247b84959e5fcedb6c8e7342dd87656b3d9a7f5c35d3f`
after every cycle and before cycles 2–5. Preserved copies were independently
rehashed. No cache repair occurred. This adds bounded positive reliability
evidence; it does not isolate or fix the earlier intermittent failures.

After verifying an unlocked desktop and closed game, run:

```sh
python3 LEKMOD_DLL/macos/lifecycle-playtest.py --cycles 5 \
  --fixture build/macos/playtests/20260919T112431Z/Lekmod-Functional-20260919T112431Z.Civ5Save \
  --fixture-sha256 f5090460073a7801399f6c6ed41929d1441da1d111cde4a751083a31717c5f42 \
  --package build/macos/Lekmod-release-candidate-f40fd2b2.zip \
  --package-sha256 e6904b434b3a3a7bebea4c2a83d1709c3aaf73d55a096237b6ed87f07fefcffc
```

The harness installs once, retains cache between cycles, captures cache evidence,
and stops on the first failure. See [the operator guide](../LEKMOD_DLL/macos/TESTING.md).
Its four offline safety/evidence tests and 17 batch supervisor tests pass;
the latter include two actual Python subprocess interruption tests. Native
lifecycle commissioning passed the five cycles above. Those passes do not establish
a root cause or erase historical startup-255 failures and shutdown stalls. See [the startup investigation](macos-startup-cache.md).

## Current installation and remaining limits

At 2026-09-21 00:53 UTC, installed stock, canonical stock backup and Aspyr backup
all matched `0da6a5ffc283c3f147b20a7ec426e4ed85a6838ab891faf61b50af4e25c4a09c`.
All **368 prior manual saves**, original quicksave, settings and **35 stock UI
files** matched the pre-run originals. Lekmod and private EUI are inactive.
No game/test process remains running.

The [expanded ledger](macos-expanded-coverage.md) and
[civilization inventory](macos-civilization-coverage.md) still contain untested
mechanics, unique abilities and owner boundaries. The additional Defender old-save/actual-ZOC, nuclear production/cleanup/city,
and counterspy-interception cases now have 20 passing functional assertions and
five exact reloads across separately recorded runs. The new five-stage combined
plan is preflighted, not claimed as one uninterrupted full-plan pass. See
[New Zealand](macos-newzealand-validation.md), [nuclear](macos-nuclear-validation.md)
and [counterspy](macos-counterspy-validation.md) evidence.

Original-settings physical acceptance `20260922T205259Z` also passed startup,
loading, espionage UI/dead-agent presentation, live-agent relocation, a new local
save, physical reload/visible-state comparison and normal exit. No observer or UI
hook was injected; original logging was disabled. Stock restoration and all 417
prior manual saves, quicksave, settings and backups were verified afterward.
This closes those specific qualification steps while broader civilization and
system combinations and the historical intermittent-failure diagnosis remain.
Only this Mac is in scope. Multiplayer/hotseat/PBEM remain deferred. The accepted
long turn campaign remains closed. Nothing was pushed.
