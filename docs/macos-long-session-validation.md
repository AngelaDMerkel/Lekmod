# Longer acceptance session, October2

`20261002T213706Z` passed all52 declared checks and15 exact checkpoint replays
in one788.3-second native process (13minutes8seconds). It used12 ordinary turns
across independent fixtures, below the26-turn aggregate cap. There was one
installation and one stock restoration, with no restart/reinstallation between
stages. The45-minute limit is a ceiling; the run exits when its checks finish.

| Group | Checks | Exact replays | Proven scope |
| --- | ---: | ---: | --- |
| Defender |4|1|Authentic affected-save repair on the next owner turn; actual active/inactive ZOC movement and Ironclad control.|
| Nuclear |11|3|Manhattan/missile production and gates; retained blast fallout cleanup/farm repair; capital/small-city/large-city/shelter population outcomes and diplomacy.|
| Polynesia |11|3|Human/AI paid upgrades, foreign gift boundaries, actual ocean movement and authentic old-save repair.|
| Venice |4|2|Independent owner/team Compass awards, repeat rejection and affected-save recovery.|
| Tonga |4|1|Generated singleton-island/coast visibility, owner controls and area identity.|
| Switzerland |8|2|Normal human Armory/unit production, mountain promotion/full birth allowance and authentic old-save repair without movement refund.|
| Moors |6|2|Actual stale capture/gift saves repair at load, preserve production and remain correct on the next recipient turn.|
| Mughals |4|1|Actual affected garrison save repairs the derived free-unit count while preserving unrelated state and subsequent-turn behavior.|

The eight ready register cases are now passed. The final three stages supplement
existing Moorish/Mughal cases; they do not claim their other acquisition branches
were rerun. Historical reports keep their original verdicts. No scenario or
product source was changed during this run, and no product fix was required.

## Inputs, outcomes and limits

These are scripted commands/callback-driven native gameplay outcomes, not physical
mouse tests or autonomous AI strategy tests. Scenarios identify supplied research,
resources, units, positions and near-complete production separately from earned
native outcomes. The old-save repair stages retain their authentic failure inputs.
No synchronization checks were bypassed and no wait flags were cleared.

This does not close all unique abilities or all nuclear behavior. Source review
specifically found that Bomb Shelter also affects stationed-unit damage, which
the city population/HP assertions do not establish. That branch remains in the
next-batch backlog. Tonga's exact radius12/mainland/lake controls remain isolated
Lua evidence. G0 is still incomplete; this run is not final GateF or R1–R5.
The accepted long campaign remains closed and multiplayer stays deferred.

## Reproduction and preservation

Use the pinned WSDLC Python environment:

```sh
build/macos/test-deps/wsdlc-runtime/bin/python LEKMOD_DLL/macos/batch-playtest.py \
  --plan LEKMOD_DLL/macos/batch-plans/acceptance-lifetime-long.json --minutes 45 \
  --package build/macos/Lekmod-config-edge-20260927.zip \
  --sha256 0726506aaaffde2f2ef9cc32b86f036a4bc6d611bf420910a946174e3c549339
```

The retained archive, manifest and native report agree on GameCore SHA-256
`6c7aafb11d9e5aea80d1e7b95c6b8f3498820385f6e132abea81bad0b3b8cf6f`.
WSDLC remains `950a329`/v1.0.10. Raw reports, copied plan, source identities and
checkpoints are under `build/macos/playtests/20261002T213706Z/`.

All30 checkpoint files have closed-writer/source-copy verification; all15 scenario
fingerprints match their replay. Native exit was0, with no recorded Lua errors,
synchronization failures or new crash diagnostics. Settings and hooks were restored.
Independent audit `build/macos/acceptance-long-preservation-20261002.json` verifies
all874 pre-test manifest files,32 stock UI originals captured by this run, original
host/core/backups, removal of the installed payload and no remaining game/launcher.
Stock is active. No push was made.
