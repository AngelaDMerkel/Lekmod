# Mughal free-garrison upkeep

Native run `20260927T184447Z` confirms a product defect in the unchanged September26
candidate. A normally produced Mughal Caravansary adds its promised500 hundredths
of city defense, but grants zero maintenance-free units instead of one.

The matched native observations were: with building, free count0/cost7/strength6396;
without building, free count0/cost7/strength5896. The default Caravansary control,
real CityConstructed event and duplicate-construction rejection passed. The run
remains failed; it exited normally and restored settings/UI/manual saves.

The source reads `GarrisonMaintenanceFree`, while the shipped Buildings schema
and Mughal row use `GarrisonMaintenceFree`. Commit `3ea165d6` reads that existing
legacy column. It also recomputes the derived city maintenance-free count from
loaded effective real/free building counts, retaining the serialized field and
save layout. No old treasury costs are refunded and no other cache is rewritten.

The source-block regression executes the actual loader assignment and rebuild
block.195 of218 checks failed before the fix; all218 pass after it under address
and undefined-behavior sanitizers. They cover shipped/default data, stale counts,
real/free-building overlap, both effective-count modes, missing entries,
idempotence and removal. This is offline evidence; **native fix acceptance is
pending rebuild and retest**.

## Native regression design

`batch-plans/mughal-garrison-regression.json` declares12 assertions/two exact
replays and a six-turn maximum. The original human-Mughal fixture is
`20260915T234025Z`, SHA-256
`f213d9b48b0c0cb759d3ea85fe9ffcbc7ff6ed6372772e58b2865fd202812054`.
Currency prerequisites, funds, one GDR/uranium,12 legal upkeep Warriors and
near-complete production hammers are supplied inputs. Building construction,
out/back movement and treasury settlement use the normal native paths.
Matched building removal/restore and ordinary-building counts are labeled API
controls. Positive upkeep and exact free-unit count are required; gold-cost
integer rounding remains intact.

The retained failed checkpoint has SHA-256
`3d8de2804282b85eb52b52922fcb2f55f822c5184f72c2b3dcf6a7a01ab010d7` and is pinned
under `build/macos/playtests/20260927T184447Z/checkpoints/`. The load regression
requires every saved unit identity/position/move, city building/strength and gold
value to remain exact, while free count changes0→1 and current unit cost7→6.
A subsequent ordinary treasury settlement and exact replay must pass.

The planned sale expectation was corrected during source review before reaching
that step: `CvCityBuildings::IsBuildingSellable` rejects buildings with zero gold
maintenance. The Mughal Caravansary has zero maintenance, so native **sale
rejection** is the required result. No sale callback or eligibility bypass is used.
No shipped NoMaintenance combat unit exists; an intrinsically free combat
garrison is not claimed as a reachable configured case.

Raw failure evidence and source-test logs are under
`build/macos/playtests/20260927T184447Z/` and
`build/macos/mughal-garrison-20260927/`. The case remains product-failed until the
rebuilt native candidate completes these tests. No push is authorized.
