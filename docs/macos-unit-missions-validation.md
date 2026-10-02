# Airlift, paradrop and exotic-goods validation

The specified mission cases pass on this Mac with scripted native commands and
exact state replays. No physical mouse or autonomous AI mission-choice coverage
is added. Failed commissioning reports retain their original verdicts.

| Case | Accepted stages | Scope |
| --- | --- | --- |
| Airlift | Four pairs in `20260927T214144Z` |24 assertions/four replays. Default Airport human and Golden Horde/Omani/Timurid AI owners; actual city/adjacent transfers, source/destination capability, domain/trade/occupancy/foreign/enemy controls, immediate zero movement and repeat rejection. AI missions run on actual owner turns. Only the human case submits the invalid blocked-target command; AI negatives query native eligibility. |
| Paradrop | Two pairs in `20260927T213252Z` |12 assertions/two replays. Visible exact9/40-range drops spend30 movement and one attack; native event confirms coordinates/accounting. No-promotion, neutral launch, genuinely embarked full-movement control, unseen/occupied/same/out-of-range targets and repeat refusal pass. |
| Exotic goods | Three pairs in `20260927T220858Z` |18 assertions/three replays. All three configured units give exact near and capped gold/XP, exhaust one-use availability and reject repeat. No-neighbor/war-only negatives and mixed peaceful/war borders pass. Actual registered tutorial edge callbacks also pass. |

Airlift/paradrop contracts retain only completed passing pairs from normally exited,
fully restored batches with explicitly reviewed unrelated harness failures. The
whole batches remain failed. The successful combined `220858Z` run also passed
[configuration parity](macos-config-cache-validation.md) and the Inland Sea baseline
replay:41 total assertions/five replays, zero turns, normal exit0, no Lua/sync/crash
errors and full restoration.

## Inputs and corrections

Building capability, legal cities, units, ownership, visibility spotters,
prerequisites and removable blockers are supplied inputs. Actual missions perform
transfers, drops and sales; resulting movement/attack/stock/rewards are not assigned.
Exotic cap testing supplies a legal secondary city and native Palace placement as
capital-location input, not as proof of ordinary capital-transfer gameplay.

`213252Z` retained airlift fixture errors (wrong unique owner, a nonexistent
city-level Lua method, and a hostile blocker expelled by declaration of war) and
an exotic CanStartMission visibility argument error. Corrected airlift uses the
actual civilization's replacement building, a blocker placed after war, and
UnitSetXY to observe zero movement before AI end-turn refresh. CanStartMission
requires numeric0 for that optional Lua binding argument.

`214144Z` passed all airlift pairs and the ordinary exotic sales, but the wrapping
Continents map had no legal strict-cap pair. Normal nonwrapping Inland Sea fixture
`214903Z` passed startup/founding/owner/color checks; save SHA-256
`f48fc0acb9e1799cfb8086573bc803dc6309d3cac42019b1d4ac30ed02a306fa`.
Its exact baseline replay passes.

`215129Z` observed capped400 gold/30 XP but then failed with stock tutorial
nil-neighbor errors at a legal edge city. The supervisor aborted process-9 and
restored settings/UI/manual files. Nothing from that runtime-error run is accepted.
The minimal `b4d0cd58` Tutorial.lua overlay preserves stock tutorial routing and
replaces only the registered siege check/plot callbacks with nil-safe versions.
Both stock functions fail the isolated edge reproducer; six corrected edge,
enemy/water/no-player, registry and routing checks pass. The same native fixture
passes in `220858Z` with current tutorial preferences preserved.

The optional NQM no-instaheal-after-paradrop define is absent from actual
preprocessor output. No pass is claimed for that inactive rule.

## Current candidate and preservation

Clean source `175d8c65fe66da3a50c7d6bba1e69cdde3d58f5c`:
`build/macos/Lekmod-config-edge-20260927.zip`, SHA-256
`0726506aaaffde2f2ef9cc32b86f036a4bc6d611bf420910a946174e3c549339`;
core `6c7aafb11d9e5aea80d1e7b95c6b8f3498820385f6e132abea81bad0b3b8cf6f`.
Earlier accepted stages retain their original candidate identities; final F/R
applicability and qualification are still required.

`build/macos/config-edge-preservation-20260927.json` independently verifies783
pre-existing single-player files, all672 recovered files and95 newer saves/three
settings (overlapping counts),32 stock UI files, original host/core and backups.
Stock is restored and Civ V closed. No push. Final single-player acceptance remains
open because the broader consumer/effect inventory is not yet reconciled.
