# Native compiled configuration parity

`20260927T220858Z` passed23 configuration assertions and exact replay on the
[identified current candidate](macos-unit-missions-validation.md). A separate
immutable-database comparison verified **103,221 values across1,657 rows**:
724 mapped scalar fields in21 globally cached info tables.

This proves configuration loading/value parity for those fields. It does **not**
prove every gameplay consumer, branch, parameter interaction or AI strategy.
The corresponding surface rows carry supporting evidence while their unfinished
consumer/effect review stays untriaged. G0 remains open.

`audit-native-info-bindings.py` uses Clang ASTs with the actual native build flags,
so commented/disabled code is not treated as active. It conservatively recognizes
direct loader assignments and direct member getters. The audit found743 matches
among893 fields in the examined classes. The runtime probe covers724; World info
has no equivalent global cached accessor and is excluded rather than synthesized.
Other unmapped/reference/nontrivial fields remain review work.

`Game.ReadInfoCacheForTest` is a macOS-only read-only diagnostic, disabled unless
that process explicitly sets `LEKMOD_CONFIG_AUDIT=1`. It checks table/index/entry
bounds and returns existing cached getters; it does not query or echo expected
SQL values, set gameplay state or change object layouts. The ordinary Steam path
leaves it disabled. Actual source-body sanitizer tests verify the opt-in, negative
and out-of-range indices, missing entry, unknown table and all724 field dispatches.
The native build retains its validated ABI/export contract.

The Lua case compares each native value with resolved GameInfo, logs each native
row, verifies unchanged turn/treasury/faith/city counts/unit identities and state,
and repeats all comparisons on reload. The deterministic cache/world fingerprint
also matches. `verify-info-cache-log.py` independently compares logged rows against
the pinned read-only/immutable database SHA-256
`8c0f687004e87d239e2bfae9c84c7cb485c48d892a97e66a983230927428427c`.
Textual SQL true/false values are explicitly normalized; float comparisons use
relative tolerance1e-6. Native logs, compiler maps and the verifier report are in
`build/macos/config-audit-20260927/` and `build/macos/playtests/20260927T220858Z/`.

The combined run exited normally0 with no Lua/synchronization/crash errors and
full restoration. Its tutorial/exotic stages and independent preservation checks
are recorded in the linked mission report. Full acceptance is still pending.

The subsequent interim comprehensive run `20260927T223201Z` passed81 gameplay
assertions/16 exact replays on these same candidate bytes without enabling the
cache-audit environment flag. It exited0, restored all temporary state and had no
Lua/synchronization/crash errors. This is a current-candidate regression, not a
substitute for the still-open G0 consumer review or final F/R acceptance gates.
