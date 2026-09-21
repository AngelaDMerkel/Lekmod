# Current-Mac release qualification

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

## Next: controlled startup and shutdown reliability

The next five-cycle test was refused before launch because the desktop was
locked. **Zero lifecycle cycles ran.** No installation or settings change was
made by that attempt. Its blocked log is
`build/macos/lifecycle-release-candidate-f40fd2b2.log`.

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
lifecycle commissioning is still pending. Successful cycles would provide bounded
reliability evidence, not establish a root cause or erase historical startup-255
failures and shutdown stalls. See [the startup investigation](macos-startup-cache.md).

## Current installation and remaining limits

At 2026-09-21 00:53 UTC, installed stock, canonical stock backup and Aspyr backup
all matched `0da6a5ffc283c3f147b20a7ec426e4ed85a6838ab891faf61b50af4e25c4a09c`.
All **368 prior manual saves**, original quicksave, settings and **35 stock UI
files** matched the pre-run originals. Lekmod and private EUI are inactive.
No game/test process remains running.

The [expanded ledger](macos-expanded-coverage.md) and
[civilization inventory](macos-civilization-coverage.md) still contain untested
mechanics, unique abilities and owner boundaries. Specific remaining cases include
counterspy interception, nuclear city effects/production/cleanup and Defender
movement through actual enemy zones of control. This package's broad batch does
not replace those cases or a final original-settings manual acceptance check.
Only this Mac is in scope. Multiplayer/hotseat/PBEM remain deferred. The accepted
long turn campaign remains closed. Nothing was pushed.
