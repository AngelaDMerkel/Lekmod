# Ottoman promotion-faith validation

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
Religious-diversity happiness and the other Ottoman uniques remain separate.
