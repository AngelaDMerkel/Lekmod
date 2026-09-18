# Tonga starting exploration

## Offline defect and correction, 2026-09-18

The active trait description promises nearby coastal tiles and islands explored
at the start. The actual Tonga handler omitted a one-tile island outside the
six-tile mainland-coast scan but inside its twelve-tile island search. Its first
nested sweep excluded the candidate island tile, leaving no plot in that land
area; its final reveal sweep also excluded its center. Including both centers
reveals the island and its adjacent coast without changing any search radius.

`test-tonga-exploration.lua` loads both the product handler and the shipped
`PlotIterators.lua`. Thirteen cases use a finite axial hex grid, explicit area
identities and per-team visibility stand-ins. Five assertions fail before the
fix; all thirteen pass afterward. Controls cover the twelve-tile boundary,
outside-radius exclusion, two-tile islands, unrelated farther islands, nearby
mainland coast, distant mainland, inland lakes, separate human/AI team IDs,
other/never-alive owners, existing visibility and inactive registration.

```sh
build/macos/test-deps/lua-5.1.4/src/lua \
  LEKMOD_DLL/macos/test-tonga-exploration.lua LEKMOD/Lua
```

An optional second argument selects a preserved old Tonga source. The baseline
is also recoverable from the parent commit; no third-party asset is needed.

Local ignored evidence:

- `build/macos/Lekmod_tonga-before-island-fix-20260918.lua`
- `build/macos/tonga-exploration-baseline-corrected-fixture-20260918.log`
- `build/macos/tonga-exploration-fixed-corrected-fixture-20260918.log`
- `build/macos/tonga-exploration-results-20260918.json`

An initial two-owner fixture placed the target fifteen hexes from one owner,
outside the required twelve-tile range. That failed fixture and its output are
retained separately. The corrected target is seven and twelve hexes from the
respective starting plots; the same corrected fixture runs against both sources.

Product Lua SHA-256 before: `e6c4f4bf1e6d7636fa5a6eb9f5175702a75be57dc9ad7660caa9217357475844`.
After: `89a0ac05e573836d457416a5e7d509f1fdeb35a3d8969821014b6f13a4af75ab`.

## Native confirmation, 2026-09-18

`20260918T233544Z` used normal Ancient/Small Archipelago setup with human/AI
Tonga and Roman AI control, no city-states, and normal no-ruins/no-barbarians
options. The observer assigned no terrain, starting plot, area or visibility.
Six naturally generated singleton islands at distances 7–11 remained hidden
(four near the human and two near the AI). Thirty-two island/adjacent-water
observations were hidden across those six cases. All 90 nearby island-coast
anchors were examined, with exactly six hidden. Native area-object equality
matched numeric area IDs; all 43 distant Roman controls stayed hidden.

The failed state saved and exited normally (0); its scenario verdict remains
FAIL. Save SHA-256:
`392ce7695d8c6c794a5b016a5a181da5800fd3cab086074c3ca1d0b4d22d55cc`.

`20260918T234131Z` loaded that exact map with the packaged correction. Both
Tongan owners' six singleton islands and their adjacent coastal water were
revealed; all 90 island-coast anchors passed. The Roman control stayed hidden.
Comparison with the baseline confirmed identical geography/starts/teams, no
lost visibility and no change to Rome's entire revealed-plot set. The local
`baseline-comparison.json` records the exact per-owner visibility differences.
Save SHA-256:
`7bcab832b7f2a56ea27fcf83b3e8733cc0c0f830d2a94012f0abf396b71ac40d`.

`20260918T234339Z` exactly reloaded all three owners' full revealed-plot lists,
starting plots, island metadata, native area identities and turn. Reload-save
SHA-256: `ca670e4d470bf87e6af03a84c36f48e7639d65879d9e563d1b85c2c68e8a8a42`.
Both fixed runs exited 0, restored hooks/settings and preserved manual saves,
with no Lua errors, synchronization failures or new diagnostics. No ordinary
turn advanced, and no mouse-interaction or earned-exploration claim is made.

The intermediate standard package is
`build/macos/Lekmod-religion-diversity-tonga-20260918.zip`, SHA-256
`72f057c764c44200994ff8b289516d86b0921ee429c22a29825e0ef7647907f5`; signed
GameCore `54b4b9564b2a801e4203542e30cb6e993c248621126295e7cfc632f10a0bc7c5`.
It was installed through the central installer and also includes the religion
diversity correction. It is not the final clean release artifact.

This closes the reproduced starting-island omission on a generated map and its
reload. Exact radius twelve, farther-island, mainland/lake and inactive-owner
controls remain isolated Lua evidence. Other Tonga uniques and city-state
resting influence remain separate coverage.
