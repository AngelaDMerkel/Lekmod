# Unique-building production and effects

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
