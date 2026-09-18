# Ottoman single-player validation

Current Mac, standard UI, normal Ancient/Tiny Pangaea single-player with human
and AI Ottomans plus an explicitly selected Roman AI control. The normal no-ruins
and no-barbarians options were enabled. Warriors and experience at promotion
thresholds were supplied. No promotion-readiness, faith or turn value was set.

`20260918T103807Z` let ordinary unit turns establish readiness. The Ottoman AI
promoted normally, emitted UnitPromoted at level 2/ExperienceNeeded 30 and gained
exactly 10 faith. The Roman AI promoted at the same threshold and gained 0 faith.
AI faith was observed from its real PlayerDoTurn boundary through the end of the
AI round; the observed deltas matched its actual promotion events.

The human used normal legal promotion actions twice. The first event's next-XP
threshold was 30 and awarded 10 faith; after supplied XP to the next threshold and
another ordinary refresh, the second event's threshold was 60 and awarded 20.
The final human level was 3, stored XP 30 and faith 30; the AI Ottoman had faith 10
and Rome 0. This tests the handler's event-time `ceil(ExperienceNeeded/3)` rule,
not faith earned from combat XP or mouse interaction.

Save SHA-256: `1553df5f0383eb9bd0adcfcc278b962fa9f661c085b9ab48ac09c46735627db3`.
`104058Z` matched all three owners' civilization, faith and unit type/level/XP/
promotion lists exactly. Reload-save SHA-256:
`200bcd4fe0159197fe17bb46b41250649609673a4690cb6fcd8ec82acba9ae8a`.
Both saved/exited normally (0), restored hooks/settings and preserved manual
saves, with no Lua or synchronization errors. No product correction was needed.
Promotion-faith coverage does not establish the other Ottoman uniques.


## Minority-religion happiness correction

`20260918T233007Z` loaded the prior three-owner promotion save. Population 20, a
pantheon, three world religions with non-happiness beliefs and pressure
transfers were supplied inputs. No happiness or turn value was assigned. A
minority gained four followers while the majority stayed at twelve. City
happiness rose 1→2 but empire happiness stayed −13 instead of becoming −12.
This retained failure ended with supervisor SIGTERM/SIGKILL (return −9); it
establishes no normal exit or save result. Hooks/settings and manual saves
were restored, with no Lua runtime or synchronization error.

`RecomputeFollowers` only refreshed city religion caches when the majority or
its follower count changed. It now also refreshes when the count of world
religions with followers changes. `CvCity::UpdateReligion` refreshes religion
yields and owner happiness without emitting a majority-conversion event or
repeating adoption rewards/notifications. No save field or layout changed.
Nine actual-method sanitizer cases pass; four fail against the old method.
The isolated cache/event sinks are stand-ins, distinct from native evidence.

`20260918T233755Z` replayed the same source save and passed all six native
checks. Minority-only addition gave city happiness 2 and empire −12 with no
conversion event. A third religion added one point; removing two minorities
removed two points. Pantheon and Roman three-religion controls gained no trait
bonus. The single-religion bonus also worked for the AI Ottoman. No ordinary
turn advanced. Save SHA-256:
`63bc14231fe90d191a7ee1fb398273111e264376e046284e23015bc0d3a27eba`.

`20260918T233947Z` exactly reloaded all three owners' follower counts, majority,
local/empire happiness, faith, population and turn. This final snapshot has one
world religion in each Ottoman capital and three in Rome; it is not a saved
three-religion Ottoman-city test. Reload-save SHA-256:
`f419fc5532ec5b3a876b2c4c907920e0d6232c4af9847a1f187cefd127c12c56`.
Both successful runs exited 0, restored hooks/settings and preserved manual
saves, with no Lua errors, synchronization failures or new diagnostics. These
are supplied-input/native-query outcomes, not mouse interaction or an earned
religious campaign. Belief-specific minority thresholds, ordinary spread and
remaining Ottoman unique-unit behavior remain separate.

Intermediate package: `build/macos/Lekmod-religion-diversity-tonga-20260918.zip`.
Archive SHA-256: `72f057c764c44200994ff8b289516d86b0921ee429c22a29825e0ef7647907f5`.
Signed installed GameCore: `54b4b9564b2a801e4203542e30cb6e993c248621126295e7cfc632f10a0bc7c5`.
It contains the committed Tonga fix and then-uncommitted diversity fix, so it
is not the final clean release artifact. The central installer preserved the
stock backup. Only one C++ source changed since the previous full build; the
incremental build and ABI validation passed.
