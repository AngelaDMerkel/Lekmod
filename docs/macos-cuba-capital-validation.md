# Cuba capital-culture validation

`20260919T032904Z` used normal Ancient/Small Pangaea setup with human Cuba,
Roman AI and a second Cuban AI. Monument/Amphitheater inputs in the human and
Roman capitals supplied culture quotes; contact was also supplied and labeled.
No marker, culture yield, culture bank or turn value was assigned.

Real PlayerDoTurn observations captured each Cuban owner's met-capital quotes.
The actual marker matched the sum of each met foreign capital's whole five-
culture groups. Both owners excluded the initially unmet Roman source. After
contact, their marker counts increased; lowering Rome's culture by removing the
provided buildings reduced both counts on ordinary owner turns. Rome never
received the Cuban marker.

| State | Human marker / capital culture | AI Cuba marker / capital culture | Roman culture |
| --- | --- | --- | --- |
| After contact, turn 3 | 1 / 6 | 2 / 3 | 6 |
| After source reduction, turn 4 | 0 / 5 | 1 / 2 | 2 |

The retained `capital-rate-delta-check.json` verifies that each Cuban capital's
observed base culture fell by one, matching its marker decrease. These are
native rate observations, not earned culture-bank settlement claims.

Save SHA-256: `c2218b614cc281d1cb1c4eb4c91705cbba38460651e3727fd043945fbda575ff`.
`20260919T033057Z` exactly reloaded all three civilizations, contacts, source
quotes, city IDs, building/marker counts, culture rates and turn. Reload-save
SHA-256: `71eeddd9d83edda8398d7606c2d5044ebb7bbac66da52f17e4468ba757fe36a5`.
Both exited normally (0), restored settings/hooks and preserved manual saves,
with no Lua errors, synchronization failures or new diagnostics. No product
change was needed. The 16 isolated callback cases cover additional rounding,
missing-capital, owner and update boundaries separately.

This does not cover capital capture/relocation, every source of modified culture,
all feedback configurations between Cuban capitals or mouse interaction. The
other Cuban ideology and Dance Hall evidence remains separately documented.
