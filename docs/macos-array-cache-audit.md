# Compiled relation-cache diagnostic (native execution pending)

The prepared diagnostic covers132 one-dimensional cache arrays in16 owner tables:
1,075,256 value comparisons against the pinned resolved database. Its purpose is
configuration-loading parity. It cannot establish the gameplay effects, AI choices
or UI presentation of those parameters.

## Source and safety contract

`audit-native-array-bindings.py` reads Clang ASTs from the existing exact-build
mapping and verifies current source hashes. It recognizes direct const indexed
getters, optional matching-pointer guards and constant fallbacks. Only assertions
and the return are permitted in the getter body. Generic loaders must be in
unconditional statements/bare scopes, filter on the current entry's `GetType()`,
and have known schema/default arguments. Later writes or pointer escapes reject
a mapping. Member declaration identity distinguishes the owner's yield array
from a similarly named resource subobject's array.

Getter-specific bounds are retained. For nullable getters without assertions,
the proven loader allocation supplies the bound; an unrecognized asserted bound
is never discarded. `PopulateArrayByExistence(bool*&)` is an ID-indexed membership
mask, while its `int*&` overload stores compact IDs with−1 padding. Value arrays
use their declared default and assign by ID. Compact lists compare as multisets;
this does not prove UI ordering semantics.

`Game.ReadInfoArrayForTest` is macOS-only and requires process opt-in
`LEKMOD_CONFIG_AUDIT=1`. It validates finite integer owner indices, expected owner
and dimension counts, getter bounds, key and non-null entry before reading actual
cached getters. It does not query expected SQL values or set gameplay state.
Normal Steam launches leave the diagnostic disabled.

The Lua case compares every value with resolved GameInfo and checks unchanged
observed turn, treasury, faith, city counts and units. The snapshot repeats the
comparisons, and raw native arrays carry run identities. The separate
`verify-array-cache-log.py` compares those rows against an immutable database,
requiring complete typed data and consistent repetitions.

## Verification completed offline

- Nine source-mapper tests reject ambiguous guards, side effects, unknown bounds
  and conditional loads while distinguishing compact lists from membership masks.
- The actual C++ reader body passes all132 dispatches and environment/index/null/
  dimension/getter-bound controls under ASan/UBSan.
- Ten independent-verifier tests reject missing/corrupt rows, wrong boolean types,
  changed compact multiplicities, conflicting repeated values, wrong runs,
  conflicting SQL duplicates and changed database identity.
- The actual Lua scenario body passes tiny independent fixtures, including default
  values, booleans, compact-list order, repeated snapshots and corruption rejection.
- Native compilation and ABI/export validation pass. These are not native-game
  parameter results.

The initial132-array package was built from clean source `967335c5`:
`build/macos/Lekmod-array-audit-v2-20261002.zip`, SHA-256
`e86ea1f5e2faeb00c9c8bcabbac773e5f78284f3fc269b29282140087bab71bf`.
Its manifest and actual GameCore member agree on
`c8f1723c7588fdf54465781ebbca9d8de009e3e11c76ba6375b5200fd9687aa2`.
Its gameplay payload hash matches the previous `0726506a…` candidate exactly.
The earlier116-array package remains retained separately; neither was installed
or launched during this locked-desktop interval.

## Explicit unresolved input/review findings

Five AI-flavor arrays have conflicting duplicate rows and are excluded pending
source/query-order review: Buildings, Units, Policies, Technologies and Leaders.
Examples include Forbidden Palace250/10, Workboat9/20, People's Army25/8,
Calendar4/2 and Harun3/5. These are source/data findings, not confirmed native
defects. The diagnostic does not select whichever result happens to pass.

Legacy/orphan relation rows are recorded explicitly. The expected native inner
join cannot load rows without a matching owner/index entry; matching that behavior
does not validate the intended gameplay of an orphan reference. Unsupported
conditional/two-dimensional/custom cache paths remain separate review work.
The AST/preparation reports and their earlier versions are under
`build/macos/config-array-audit-20261002/`; original inputs were preserved.

## Next native round

The reviewed `cache-and-reward-regression.json` plan contains68 assertions and
six exact replays, with a four-turn aggregate cap and40-minute ceiling. It combines
the array diagnostic, existing scalar-cache checks and Merchant/Engineer/shelter/
spaceship outcome regressions in one installation and process. Final F/R acceptance
remains after G0/gameplay closure; this will be an interim candidate qualification.

Use the pinned WSDLC Python with process-only `LEKMOD_CONFIG_AUDIT=1`, the plan and
archive/hash above. Run normal readiness/preflight and unlocked-desktop guards.
The desktop was locked at both prelaunch checks, so no game/settings change was
started. Recheck on resume; preserve current data and restore stock after the round.
Do not mark the configuration case passed until both native run/replay and the
independent immutable-database verifier succeed.
