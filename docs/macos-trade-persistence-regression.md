# Trade building bonuses after save/reload

The native trade scenario `20260914T012819Z` purchased a caravan through the
standard production popup, created a real route from Rome to Vaduz, checked its
8.10 gold contribution in city yields, and verified ordinary treasury settlement.
It saved and exited normally. Its save is preserved at
`build/macos/playtests/20260914T012819Z/Lekmod-Functional-20260914T012819Z.Civ5Save`
(SHA-256 `34934e1c9714573ce3d576b7f09d8a56bce3bffb1d242721127a7493d144ddb3`).

Reloads `20260914T013359Z` and `20260914T013919Z` failed the state comparison.
The latter records exact expected/actual JSON: computed route income fell from
810 to 560 hundredths while the serialized city trade subtotal remained 810.
Gold, route identity, remaining duration and other recorded values matched.
The reports remain failed; no synchronization checks were bypassed.

`TRADE_REFACTOR` keeps six city arrays of origin, destination and incoming
building trade bonuses, split between land and sea. They are populated by
`processBuilding` but neither serialized nor reconstructed after load. The
Caravansary's 200-hundredths bonus therefore disappeared; with the 25% river
modifier this explains the missing 250 hundredths exactly.

The correction shares the existing building-bonus calculation between normal
building changes and an idempotent reconstruction. `DoGameStarted` reconstructs
all living players' city caches first, then refreshes route values for all living
players, so destination bonuses are available before either endpoint is evaluated.
It uses active building counts, including free buildings and excluding obsolete
ones. It does not add fields to the save stream or require recreating saves.

`test-trade-building-cache.py` executes the actual helpers under ASan/UBSan. It
reproduces the 560-versus-810 arithmetic and checks 128 six-array cases including
stale-cache clearing, repeated initialization, counts and removal. Native retest
of the reconstructed caches remains required before this fix is release-validated.

## Native retest

`20260914T021912Z` loaded the exact previously failing save on the repaired
signed GameCore `18e9a9c18326440a019f54099593230274288ab9397b80d97a4211d1ecdc3086`.
The complete recorded trade snapshot matched, including computed route gold 810,
city trade subtotal 810, treasury 138, route identity and remaining duration.
Normal save/exit passed, all prior manual saves and settings/hooks were preserved,
and no Lua runtime errors, synchronization failures or new diagnostics appeared.
The newly saved copy has SHA-256
`44d728f4cbe3a587602a4e925970233def3613f90eacb88aa982655837c4c2a6`.
This verifies reconstruction without a save-format migration; the earlier failing
reports remain unchanged.
