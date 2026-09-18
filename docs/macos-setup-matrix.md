# Current-Mac single-player setup matrix

This finite matrix covers every shipped speed, difficulty, starting era and
world-size value, plus six standard map scripts and selected option boundaries.
It does not cover every combination. Every case uses two ordinary human turns
with AI opponents; no multiplayer or long stability campaign was run.
Normal setup supplies the map, era, speed, difficulty and options; cities, units,
yields and elapsed turns are not assigned by the scenario. Human difficulty is
selected through the normal player-zero setting, leaving AI slot defaults intact.

| Speed / human difficulty | Map | Starting era | World | Majors / minors | Gameplay run | Exact reload |
| --- | --- | --- | --- | --- | --- | --- |
| Standard / Settler | Pangaea | Ancient | Tiny | 3 / 0 | `20260918T024517Z` | `20260918T025120Z` |
| Epic / Deity | Archipelago | Medieval | Small | 4 / 4 | `20260918T025217Z` | `20260918T025338Z` |
| Marathon / Prince | Lakes | Renaissance | Tiny | 2 / 4 | `20260918T030144Z` | `20260918T030300Z` |
| Quick / Immortal | Fractal | Industrial | Standard | 6 / 8 | `20260918T032102Z` | `20260918T032239Z` |
| Standard / King | Small Continents | Atomic | Tiny | 3 / 6 | `20260918T040228Z` | `20260918T040718Z` |
| Quick / Emperor | Continents | Ancient | Huge | 12 / 41 | `20260918T042603Z` | `20260918T042735Z` |
| Epic / Chieftain | Continents | Classical | Large | 8 / 12 | `20260918T042843Z` | `20260918T043010Z` |
| Marathon / Warlord | Pangaea | Information | Small | 4 / 4 | `20260918T043116Z` | `20260918T043254Z` |
| Quick / Prince | Fractal | Modern | Duel | 2 / 4 | `20260918T043354Z` | `20260918T043528Z` |

The Atomic row resumes the preserved initial save generated in `033425Z`,
including exactly the same starting units and coordinates. It exposed and
retested the MovementCost binding crash described in the expanded ledger.
All positive rows saved/exited normally, restored settings/hooks, preserved
original manual saves and reported no Lua or synchronization errors.

The engine's internal era identifiers are `ERA_POSTMODERN` for Atomic and
`ERA_FUTURE` for Information. The tool accepts those identifiers and the
corresponding readable aliases. Native localized labels were recorded in later
cases. Map-generation logs identify the actual map scripts.

## Options and observed outcomes

The cases verify the requested option flags and their persistence. Applicable
negative checks establish no barbarian units with barbarians disabled, no spy
awards with espionage disabled, zero ordinary culture rate with policies disabled,
and unchanged technology ownership/counts/progress/overflow across two turns with
science disabled. The one-city case rejects every second-city founding query for
the human while a Rome AI still has an eligible control location. Raging-barbarian,
no-religion and no-city-razing flags are configuration/persistence evidence here;
this matrix does not add combat/spread/capture outcomes for those options.

Snapshot comparison includes map dimensions/land/roster, era/speed/difficulty,
option flags, human cities/units, treasury/culture/faith/research and spy count.
Science-disabled snapshots also retain every technology's status, count and
research progress plus overflow. These are scripted setup/commands and native
outcomes, not physical selection of every setup control.

## Retained failures and corrections

- `025437Z` requested four city-states on Duel Lakes; the map generator explicitly
  discarded one because no eligible sites remained. That exact requested roster
  did not pass. The later Tiny Lakes case retained the four-city-state assertion.
- `030358Z` incorrectly expected CanResearch to reject prerequisite eligibility
  under No Science. The native option instead gates ordinary research processing.
  The test now checks actual technology/progress/overflow invariance.
- `030901Z` passed those gameplay assertions and wrote its save but stalled in
  Aspyr/SDL shutdown. It remains failed. `031725Z` reloaded its saved state and
  exited normally, followed by the fresh positive row and reload above.
- `032341Z` exposed the driver's adjacent-only stack handling. `033425Z` then
  crashed in the real MovementCost object binding. `035222Z` and `035746Z`
  retained non-crashing driver failures. The final driver resolves overstacking
  before Skip, uses legal movement queries/orders, can move a matching adjacent
  blocker outward, and verifies arrival. Eleven offline movement cases pass.
- `040816Z` and `041455Z` failed in localization before gameplay; the latter's
  loader trace contains no GameCore image. The stock comparison and package
  restoration are documented separately. They do not erase the startup failures.

## Reproduction

`LEKMOD_DLL/macos/setup-matrix.json` records the finite input combinations.
For each row, use the setup scenario and its recorded fields:

```sh
python3 LEKMOD_DLL/macos/automated-playtest.py --mode single-player-smoke \
  --turns 3 --scenario setup --scenario-turns 2 --timeout 1200 \
  --map-script Pangaea.lua --game-speed GAMESPEED_STANDARD \
  --handicap HANDICAP_SETTLER --start-era ERA_ANCIENT \
  --world-size WORLDSIZE_TINY --majors 3 --minors 0 \
  --opponent-civilization CIVILIZATION_ROME \
  --game-option GAMEOPTION_NO_BARBARIANS=1 \
  --game-option GAMEOPTION_NO_ESPIONAGE=1 --save-and-exit
```

Reload the resulting save with `--scenario setup --expected-state REPORT_JSON
--load-save SAVE --save-and-exit`, omitting the turn request. Full commands and
results are retained in the ignored `build/macos/setup-matrix-results-20260918.json`.

Successful gameplay-save SHA-256 values:

- `20260918T024517Z`: `e4f53d2fee02be36465eeac80a807765ba5bca9b5e5c31932d9d829faa414c2a`
- `20260918T025217Z`: `a39cc0b212a12308db2c20319b2385332dfd5ee88ed61f9d8c21a14c037767a1`
- `20260918T030144Z`: `5a0ba0be01d03261e04e58c1d01040b6d2ee25e0f8044b5763d90e51c7d1e4e2`
- `20260918T032102Z`: `50d54b14bff4cede9c32b168c223bea5289442aa5473ab4e515a7cb11ac0bcae`
- `20260918T040228Z`: `bf1423a006e7d841d7e5f9a6a27e7a10e0b08a461de5557fa680a450914c9bae`
- `20260918T042603Z`: `463c6c37493faa10c69bf8770e0832684ae5aebb78e2c9911da7e275112a2346`
- `20260918T042843Z`: `4005dc22b5ee9213b84032678e3403b6c29738cf5b46fdcca2b2d1b1f477abbf`
- `20260918T043116Z`: `925057c10e3a65420389e09c6fcee44980e93fef8c6028f57caeb3ff91c4a579`
- `20260918T043354Z`: `bf11c55475c8087cc0d07e39f418333d04883baebc842b9df4f497c7b495ecb0`
