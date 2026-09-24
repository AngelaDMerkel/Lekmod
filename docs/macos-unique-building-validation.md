# Unique-building production and effects

## Production catalogue

All **87 regular-production unique building definitions** now have native
CityConstructed/count=1 checks, duplicate-construction rejection and exact
save/reload evidence. Ten independent saved games cover the corresponding
civilization owners; they use 22 ordinary turns in total. This is combined
passing evidence from four runs, not one uninterrupted full-plan pass.

| Group | Passing native run | Buildings | Ordinary turns |
| --- | --- | ---: | ---: |
| building-group-01 | `20260923T003021Z` | 11 | 2 |
| building-group-02 | `20260923T003325Z` | 9 | 2 |
| building-group-03 | `20260923T005133Z` | 9 | 2 |
| building-group-04 | `20260923T004241Z` | 10 | 2 |
| building-group-05 | `20260923T004241Z` | 8 | 2 |
| building-group-06 | `20260923T003325Z` | 9 | 2 |
| building-group-07 | `20260923T003325Z` | 8 | 2 |
| building-group-08 | `20260923T003325Z` | 8 | 2 |
| building-group-09 | `20260923T003325Z` | 11 | 4 |
| building-group-10 | `20260923T003325Z` | 4 | 2 |

The human uses the normal city-order message. AI orders are issued only on the
actual owner's PlayerDoTurn while that owner is active, through the unforced
city queue. Existing target orders are continued without replacing them; the
Stele continuation was observed explicitly. Supplied inputs include research,
prerequisite buildings, legal extra city sites, local/strategic resources and
production one hammer below completion. Target buildings are never assigned.
Local resources are supplied before legal founding so the native founding path
establishes city linkage. No synchronization checks or wait flags are changed.

Snapshots preserve building counts, component/current yields, populations,
policies, gold and faith. Later groups also record total/free building counts.
Exact reload verifies persistence; it does **not** independently validate every
building's advertised yield, ability or event handler. There is no physical
mouse coverage in this catalogue.

Three definitions remain outside this production phase: Israel's purchase-only
National College, Vatican's holy-city St Peter's, and Jerusalem's occupied-city
Outremer. Their acquisition gates, selected effects and exact reload now pass the
[dedicated special-building cases](macos-special-building-validation.md). That
work also found and fixed a missed College great-person reward after city loss.
Together, the catalogues cover acquisition/persistence for all 90 definitions;
individual effects remain separately scoped.

### Retained commissioning failures

- `20260923T002217Z` and `20260923T002543Z`: Argentina Stable input lacked a
  native local resource connection. Adding a resource to an already owned plot
  was insufficient. Supplying it before legal city founding fixed the fixture;
  group 1 then passed in `20260923T003021Z` (105.6 seconds).
- `20260923T003325Z` (483.8 seconds) remains an overall failed batch. Six groups
  passed with reloads; group 3 lacked Chile's required Coal, group 4 mistook
  Gaul's free capital walls for absence, and group 5 incorrectly included an
  occupied-city building in an ordinary-city fixture.
- `20260923T004241Z` (205.1 seconds) remains an overall failed batch. Groups 4
  and 5 passed after explicit prerequisite/free-building/scope corrections.
  Group 3 rejected the already queued Ethiopian Stele. The native rule rejects
  adding a duplicate order but permits continuing it.
- `20260923T005133Z` passed all nine group-3 production checks and exact reload
  in 134.2 seconds after respecting inherited orders. The observer confirmed
  the Stele was inherited. No product change was needed for these failures.

All four evidence runs exited normally (0), restored settings/hooks and
preserved prior manual saves, with no Lua/synchronization errors or new
diagnostics. Managed wrappers restored stock. Every checkpoint hash and each
passing run/reload snapshot pair was independently reverified. Full per-building
lists and source/reload SHA-256 values are in the ignored local artifact
`build/macos/unique-building-catalogue-validation-20260923.json`.
Final verification preserved 473 prior manual saves, the original quicksave,
32 stock UI files, settings and both canonical/Aspyr backups; stock is active.

Reproduce all ten groups with
`LEKMOD_DLL/macos/batch-plans/unique-building-catalogue.json` and the clean
`f1a88db4b2f33def33ba263be95915eae401da3af2239a31fceb2cfacffcc64c` package.
The combined plan is preflighted (ten reloads, 23-turn maximum); its complete
uninterrupted execution is not claimed. Focused commissioning/recovery plans
are retained. All 23 dispatcher and 33 runner checks pass, with Lua syntax checked.

## Akkad and Aksum pilot

Run `20260923T000456Z` passed six assertions and exact reload in 109.7 seconds,
using two ordinary turns (2–4). It loaded the normal-start group 1 save: human
Akkad and AI Aksum. Both targets completed via native CityConstructed events,
with gold/faith purchase flags false. The human used its normal city-order
message; the AI used its eligible city queue on its actual owner turn, with
force disabled. Target buildings were never assigned directly.

Inputs were supplied Drama prerequisites, a legal second Aksum city, prerequisite
Monuments and production one hammer below completion. They are not earned
research/founding/production claims. The final hammer and building effects came
from ordinary production and owner turns. The test verified:

- Writing eligibility, owner-specific unique replacements, standard-building
  alternatives and rejection of foreign replacements.
- Akkad library production, +1 flat building science and +50/100 science per
  population, including natural city growth from population 1 to 2.
- Aksum national epic production and +1 Monument food, production, gold and faith
  in both Aksum cities, plus +4 culture/faith from the epic at the capital.
- No Aksum Monument bonus in the Akkad control city.
- Exact persistence of building counts, component yields, policy contributions,
  owner bonuses, populations and policies after reload.

Initial run `20260923T000008Z` remains failed: it expected capital building culture
to increase by 4, but observed 7. The corrected test's before/after policy snapshots
show that the AI acquired Tradition during ordinary play. The native policy
building-class query accounts for the additional 3 Palace culture. Comparing
component yields after separately accounting for actual policy contributions
passes. No game outcome or policy was assigned, and no product correction was
needed. The first report exited normally and restored files, but is not a pass.

The final run exited normally (0), restored settings/hooks and preserved manual
saves, with no Lua/synchronization errors or new diagnostics. Its managed wrapper
restored stock. Checkpoint SHA-256:
`ee091625fcfd4533827f52a22aaa2883c409a00d7a30a11b0e89df2df043a843`.
Reload checkpoint:
`5bda27db9d71842dad1637116b2c8bd03f52704e057ffb5bce41706c5827beed`.
Both hashes were independently reverified. Reproduce with
`LEKMOD_DLL/macos/batch-plans/unique-building-pilot.json` and clean archive
`f1a88db4b2f33def33ba263be95915eae401da3af2239a31fceb2cfacffcc64c`.

The shipped data contains 90 non-default unique building definitions. This pilot
covers these two buildings' listed production/effect paths and persistence;
it does not establish every building, purchase, terrain, capture or unique ability
combination. All actions here are scripted commands/native outcomes, not mouse input.
