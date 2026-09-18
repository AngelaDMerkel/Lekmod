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

## Native status

**Pending.** The desktop was locked during this correction, so no game launch
or installer change was attempted. The installed Philippines-quota package
still contains the prior Tonga script. These offline tests do not establish
native area-object identity, engine grid conversion, generated-map starting
vision, saved visibility persistence, or mouse interaction. Resume with a
normal Archipelago Tonga setup, retain a pre-fix fixture, test the packaged
correction and exact reload, then update the completion ledger. Other Tonga
uniques and city-state resting influence remain separate coverage.
