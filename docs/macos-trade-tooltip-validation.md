# Trade tooltip precision, 2026-09-19

The shared GameCore trade tooltip truncated hundredths using integer division.
Physical EUI run `20260919T042745Z` showed 1 food and 3 production while the
underlying routes carried 1.75 and 3.5. Both standard and EUI top panels consume
these bindings. The fix passes floating-point yields to localization in all 18
live outgoing-origin, outgoing-destination and incoming-destination cases.
It changes presentation only, not route yields or serialization.

## Reproduction and automated checks

`test-trade-tooltip-precision.py` compiles the actual two C++ bindings with
ASan/UBSan and minimal numeric/localization sinks. It checks six yield types,
three paths and ten fractional/whole/negative inputs, plus owner/zero/internal
route filtering. The preserved old source failed 144 of 183 cases; all 183 pass
after the fix. This harness tests numeric arguments and filtering, not Aspyr's
localization renderer. Baseline source/log are under `build/macos/` as
`CvLuaPlayer-before-trade-tooltip-20260919.cpp` and
`trade-tooltip-precision-baseline-20260919.log`.

Native read-only scenario `trade-tooltip`, run `20260919T044117Z`, loaded the
preserved internal-route fixture `20260916T080553Z`. The real localized string
contains Antium→Rome **1.75 Food** and Antium→Cumae **3.5 Production**. All three
checks passed with route values 175/350 hundredths, turn 180, gold 2,202 and two
used routes unchanged. Save SHA-256:
`96d1be6a9c2a3df0aef8f42f8e0aa4cbc2cb8c745476c876f1289141bb0bc7a6`.
Exact recorded-state reload `20260919T044404Z` passed; its save SHA-256 is
`ef29581098f469714a59a4530a8c6139288c0a6d7807adecc99784c7af712158`.
Both exited normally (0), preserved manual saves/settings/hooks and recorded no
Lua errors, synchronization failures or new diagnostics.

## Physical EUI retest and restoration

Run `20260919T044720Z` loaded the same fixture at requested 1440×900. An actual
CUA click on the trade counter opened the overview. The visible tooltip showed
1.75 food and 3.5 production; the table retained its intended one-decimal
1.8/3.5 display and 19/24 remaining turns. Retained screenshot
`eui-trade-tooltip-fixed.png` has SHA-256
`37c40c95321cc3fdc33b3e3698bd1b8a9f0f0e7a6a184c14dd93f77934463482`.
Actual Close → Escape → Exit to Windows → Yes exited normally (0) after 415.8
seconds. The read-only observer recorded no gameplay change, no turn advanced
and no save was requested. Hooks, settings, resolution and manual saves were
preserved; no Lua/sync errors or new diagnostics were reported.

Wrapper `eui-tests/20260919T044711Z` verified exact standard package, EUI text
and options restoration. Its CLI result 1 reflects the runner's
`ended-manual-ui-session` classification, not a native exit or cleanup failure.
The standard archive `Lekmod-trade-tooltip-20260919.zip` has SHA-256
`16d26d3215bb6d01180c65f0e4fba38e7f5a4e4d9ac9dd091edcaf5219da42b8`;
signed GameCore is
`e931774c13af9edbbdeb3a1b36d97e25aa12c267c0a637954134b8a2855a38bd`.
The private EUI variant `Lekmod-eui-trade-precision-20260919.zip` has SHA-256
`97f38c7d1db0ba3929eb0f8844523139d402e0908293df18f42996cf8c3376e7`.
It reuses that core and is not redistributed. This was an incremental source-only
core rebuild; the packages were built with the precision changes uncommitted,
so neither is claimed as the final clean release artifact.

The populated incoming tooltip still needs native/physical evidence. Other
localized languages, all six yield types in actual gameplay, and standard
physical tooltip rendering are not established by this focused retest.

Subsequent [incoming-route checks](macos-incoming-trade-validation.md) add native
populated incoming 2.5/2 gold and 1 science, plus actual standard/EUI incoming
and outgoing tooltip rendering. The limits above describe this report's first
retest; broader yields and languages still remain outside the combined evidence.
