# Oman Minaa periodic-damage validation

Current Mac, standard UI, single-player human Oman / AI Rome, Industrial/Small
Archipelago with no city-states or barbarians. A legal distant coastal city,
Minaa, units, upkeep budgets, one ship's starting damage 80 and one Worker's
embarked state were explicitly supplied. The building was not earned or normally
constructed in this fixture, and the Worker's embark transition is not tested.

`20260918T101341Z` exposed a fixture timing error: units created on Rome's turn
moved and fought despite their normal Skip orders. The observed ship damage 56
therefore mixed combat and the Minaa effect; it remains a failed test and did not
justify changing product damage rules.

The existing native render log showed an empty barbarian-player turn after Rome
and before the next Oman turn. `101851Z` replayed the same initial world and
supplied the Roman probes at that genuine boundary, with Rome no longer active.
No AI action was issued there; no AI, movement budget, turn or wait flag was
changed. The next ordinary Oman turn (165→166) produced these outcomes:

- Adjacent healthy enemy ship: damage 0→30.
- Adjacent supplied-embarked Worker: damage 0→30.
- The ship ahead of that Worker in the same plot started with 20 HP and died;
  deferred death did not prevent the later stacked Worker from being damaged.
- Own adjacent ship, unembarked enemy land unit and enemy ship at distance 2:
  damage stayed 0.

Save SHA-256: `2a0c33f643d2d13ac839392a4cada955eec4caa17ac4dd255ca8dab8d89a0d6d`.
Exact reload `102211Z` matched surviving unit types, owners, coordinates, damage,
maximum HP, domains and embark states, plus city/Minaa and war state. Transient
already-dead units are excluded from the persistent snapshot. Reload-save SHA-256:
`425dfafd8cafe0041637a6379d063fa163feef6c5637e9b47a3b98fe2332323a`.
Both successful runs saved/exited normally (0), restored settings/hooks and
preserved manual saves, with no Lua or synchronization errors.

Nine isolated real-handler Lua cases pass: enemy sea, embarked land, ordinary
land, own sea, peace, absent building, other civilization, dead owner and deferred
lethal stack. Peace and the other filters not exercised by the native fixture
remain offline callback evidence. No Minaa product correction was required.
Normal Minaa construction, other Omani unique mechanics and additional owner
branches remain separate coverage. No mouse or earned-army claim is made.
