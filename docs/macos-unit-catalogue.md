# Unique-unit catalogue and texture regression

The native catalogue enumerates every non-default unique unit override belonging
to the 114 playable civilizations: **125 unit types**. It explicitly supplies
those units to one human Oman owner, verifies their actual UnitCreated events,
identity/domain/health and persistence. This is broad foreign-owner instantiation
coverage, not each civilization's trait, earned production, unit mission or complete
visual-art certification. Supplied script-data tags identify only the test units.

The later [own-civilization production catalogue](macos-unit-production-validation.md)
adds normal acquisition for all 115 production-capable definitions and ten exact
replays. Its ten special-acquisition exclusions remain explicit. This later
coverage does not change the scope or retained results of the creation/disband
runs below.

The [special-acquisition follow-up](macos-special-unit-acquisition.md) closes one
own-civilization acquisition path for the other ten definitions. Acquisition and
resulting-state replay therefore cover all 125 types across those suites, while
ability, mission and owner/state boundaries remain separate.

## Retained commissioning failures

- `20260922T210439Z`: 20 types created before the test's missing hover-domain
  staging branch rejected Cardoen. Failed checks, 99.6 seconds, normal exit 0.
- `20260922T210841Z`: Cardoen was created, but the test incorrectly compared its
  resolved native domain with the XML HOVER domain. CvUnit::getDomainType returns
  LAND or SEA according to its tile. Failed checks, 99.7 seconds, normal exit 0.
- `20260922T211144Z`: reached Tunisian Privateer at position 115, then stopped;
  status `failed-stall`, 302.4 seconds, native -9. The supervisor also lacked
  intermediate completed-check progress for long zero-turn stages.
- `20260922T212042Z`: with per-unit passed checks tracked as progress, reached
  the same unit and stopped. A screenshot and read-only process sample revealed
  a native Texture Load Error dialog naming `tunis_xebec_flag_32.dds`. The owner
  runner was interrupted for cleanup; status `interrupted`, 468.1 seconds,
  native -9. This confirms an asset defect. The preceding stop must not be
  attributed solely to the timer correction.

The missing-texture screenshot is
`build/macos/playtests/20260922T212042Z/catalogue-pause.png`; the sample is beside
it. All four runs restored hooks/settings and preserved prior manual saves;
none had a Lua runtime error, synchronization failure or new crash diagnostic.
They remain failed/incomplete, not passes.

## Confirmed content correction

The Tunisian Privateer referenced a custom 32-pixel flag atlas whose only texture
is absent from both the checkout and the release archive. Its unit model already
uses the stock Privateer. The correction uses that model's shipped
`EXPANSION_UNIT_FLAG_ATLAS`, offset 21, and removes the unused missing-texture
atlas row. Combat, production and other gameplay data are unchanged.

A regression checks every unit flag's 32-pixel atlas definition and slot bounds,
and requires custom texture filenames to exist in the mod payload. Named stock
atlases are supplied by Aspyr's base/DLC asset packs. Filename comparison follows
the observed case-insensitive lookup (e.g. the already tested Gallowglass flag).
The test fails on the missing Tunisian flag before the fix; all five gameplay-data
checks pass afterward. It is included in CI.

Candidate `build/macos/Lekmod-tunisian-flag-20260922.zip` has SHA-256
`f1a5cac14ccc465f06f5062832f57f8b5292d7d82bd683579cf1d0ef44acad15`.
Its manifest records dirty source at `2b1687d1`; this is an intermediate candidate.
The core remains byte-identical:
`4e1a94b9ea8c61c16e18e2bc32a6f46a54941c056bb804b14cfd4c8066bc764b`.
The payload digest is
`094d1dcf9635d2d8392fd49bbe7c9a88dadf1767813f5383f0ddf6b708e19a3e`.

The revised catalogue tests the Tunisian unit first. `20260922T213414Z`
passed **all 125 per-unit checks, three aggregate checks and exact reload** in
335.8 seconds with zero ordinary turns. All tagged units' identity, owner,
resolved domain, positions, movement, health, combat strength, promotions and
script data matched after reload. Normal exit 0, settings/hooks restoration,
manual-save preservation and no Lua/synchronization errors or new diagnostics
were verified. The managed wrapper restored stock.

Verified creation checkpoint SHA-256:
`3821b06e81f901faf9fb2b7adf2649023ca0ea70a0490079a9ab8cbe9a3eeced`.
Reload checkpoint:
`902e1f4690cb53ba7d1394650808acbd5ed467365e8c40af285622a0146d02bd`.
Both are under `build/macos/playtests/20260922T213414Z/checkpoints/`.
The normal completion beyond 240 seconds also commissions progress tracking for
this long zero-turn stage; no wait or synchronization flag was changed.

## Normal disband, refund and final persistence

`20260922T214053Z` loaded the complete saved catalogue and passed all **125
per-unit removal checks, three aggregate checks and exact reload** in 530.1
seconds with zero ordinary turns. Each unit was selected and removed using the
actual Delete/Yes confirmation callback. Native UnitPrekill was observed for
every unit; no direct Kill call or outcome field was assigned.

Alternating units were explicitly staged in the human capital. Each owned-tile
removal increased treasury by its native GetScrapGold quote; neutral-tile removals
gave zero. Total refunds were 1,373 gold, with the final treasury 2,429. Final
remaining units and treasury matched exactly after reload. Normal exit 0,
settings/hooks restoration, prior-manual-save preservation, and no Lua/runtime
synchronization errors or new diagnostics were verified. The wrapper restored
stock. These are scripted callbacks/native outcomes, not physical mouse actions.

Verified final checkpoint SHA-256:
`bb7706d267014c3c59a1459d9f0ccc6fe5884075d38bcbc644a628a16f50187f`.
Reload checkpoint:
`655094a2ae145d59c5266f9acf8bf9c448eb9d2788781369e543ac775f4fa5b8`.
Reproduction plans are `batch-plans/unique-units.json` and
`batch-plans/unique-unit-disband.json` under `LEKMOD_DLL/macos`. The latter pins
the complete catalogue save and its hash. This broadens foreign-owner unit
creation/removal coverage while civilization-specific abilities, production and
mission combinations remain separate.
