# Single-player system validation continuation

Scope: standard UI and modern macOS on this machine. The long stability phase
remains accepted; multiplayer is deferred. Foreground testing is authorized in
the current task, with the existing 180-second cap. EUI and older macOS are not
part of the proposed standard-UI support claim.

## Read-only mid-game fixture inventory

`build/macos/playtests/20260913T225017Z` loaded the preserved turn-110 autosave,
finished its stored handoff to turn 111 and recorded the world state without
gameplay commands. Religion is enabled, ten religions exist and two slots remain.
Rome has one unassigned spy and known foreign cities, but zero gold and faith.
There is no active Congress. This is inventory evidence, not functional coverage.

The normal save/exit callbacks created a separate manual fixture:
`build/macos/playtests/20260913T225017Z/Lekmod-Functional-20260913T225017Z.Civ5Save`,
SHA-256 `cd6a85b2d129bced7744541bd1b4b2f3d126cfffe9b47800cc8fd524a948a5e6`.
The process exited normally (0); settings/hooks restored, no Lua runtime errors,
sync failures or new Civ V diagnostics.

## Espionage assignment and persistence

`20260913T225632Z` used that manual fixture. The scenario submitted ordinary
`Network.SendMoveSpy` commands using the game's legal relocation list, then
verified agent coordinates, travelling state and role: home city → HQ → foreign
capital as spy → HQ → foreign capital as diplomat. No spies, resources, cities
or intelligence were granted. All four checks passed; saving and normal exit
also passed. These are scripted command/state checks, not mouse or spy-arrival,
technology-theft or election outcomes.

The resulting save is
`build/macos/playtests/20260913T225632Z/Lekmod-Functional-20260913T225632Z.Civ5Save`,
SHA-256 `7cf5308305808721a488aafe8e88e7f261546b400e675ad7cd96b286d2513a80`.
`20260913T225909Z` reloaded it and matched turn, player, gold/faith and complete
spy records before any action, followed by another normal save/exit. Both runs
restored settings/hooks and recorded no Lua runtime errors, synchronization
failures or new diagnostics. The original reports retain their recorded scope;
the current harness now reports reload-only checks separately from action checks.

Reproduction:

```sh
python3 LEKMOD_DLL/macos/automated-playtest.py --mode single-player-smoke --turns 3 --timeout 180 --stall-seconds 150 --load-save /absolute/path/to/inventory-fixture.Civ5Save --scenario espionage --save-and-exit
python3 LEKMOD_DLL/macos/automated-playtest.py --mode single-player-smoke --turns 3 --timeout 180 --stall-seconds 150 --load-save /absolute/path/to/result.Civ5Save --scenario espionage --expected-state /absolute/path/to/prior/report.json --save-and-exit
```

These runs used the legacy installed GameCore hash `ada65581…fa40a`. The new
product Lua fixes and science-overflow binding require matched-package native
validation. See [the unit-handler regressions](macos-unit-handler-regressions.md).

## Work still in progress

- Religion founding/enhancement, faith purchase and spread; use clearly labeled
  scenario setup if resources/units must be supplied to make a bounded fixture.
- Spy arrival/intelligence, trade route outcomes, diplomacy/deals and Congress.
- Remaining city mouse paths, resolution coverage, wonder/process outcomes.
- Exact current-source package installation, native regression and stock restore.
- Diagnose/document unused adjacency scaffolding and absent extra main-menu UI.

No full-support or release-completion claim is made by this progress document.
