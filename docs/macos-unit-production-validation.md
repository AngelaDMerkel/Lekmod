# Own-civilization unique-unit production

This catalogue addresses a different question from the [125-type creation and
disband catalogue](macos-unit-catalogue.md): can each civilization acquire its
ordinary unique units through normal production? It uses the ten existing
normal-start fixtures covering 114 civilizations on this Mac. Multiplayer and
the already accepted long campaign remain outside this work.

The inventory contains **115 production definitions and 10 special definitions**.
The three zero-base-cost settlers remain production targets: their actual costs
come from `GetUnitProductionNeeded`. The special definitions are explicitly
listed, never counted as production passes.

## Test contract

- Enumerate non-default civilization unit overrides from the live database.
- Supply researched prerequisites, strategic resources, necessary population,
  legal coastal cities/trade destinations and capacity, upkeep gold, Cuba's required ideology, and cost-minus-one
  production. These are fixture inputs, not earned gameplay outcomes.
- Submit the human order through `Game.CityPushOrder`. Submit AI orders only in
  the actual owner's `PlayerDoTurn`, after its normal economic actions. Continue
  an existing eligible target order when present; never force an ineligible one.
- Observe `CityTrained` for the matching owner, city and unit, with both purchase
  flags false. Verify identity, domain and base strength, including Colorado's
  existing happiness rule. No target is supplied with `InitUnit`.
- Compare the resulting cities, surviving units/promotions, treasury, faith and
  technologies exactly after reload. AI use or conversion of a produced unit
  before saving is distinct from its verified acquisition at birth.

Targets for each owner are ordered by prerequisite technology cost. Target
prerequisites are supplied when its round is prepared; the trade fixture also
provides reviewed capacity technologies that do not obsolete its later Nau.
The test does not remove technology to make an obsolete unit eligible. No synchronization guard or GameCore
wait flag is changed. These are scripted commands and native outcomes; this work
adds no physical mouse coverage.

## Commissioning history

`20260926T013503Z` stopped at the Ayyubid Knight eligibility assertion. The initial
fixture supplied its one horse before the AI's ordinary economic actions; the
saved state then contained another Knight and a lower treasury before the test
order could be submitted. Moving prerequisite setup into the owner's actual
callback avoids that intervening consumption. The run remains failed, 79.5 seconds,
normal exit 0 and full cleanup; it is not evidence of a new gameplay defect.

`20260926T013752Z` exited 255 before testing, at 20.4 seconds. Failure-cache
preservation retained a 25,509,888-byte merged localization database with
`quick_check=ok`, SHA-256
`83d88d45501606828911d889de8fca780421491c982c965cf93937ea136672a7`.
The [startup failure](macos-startup-cache.md) remains unresolved.

`20260926T013858Z` ran five independent groups in one process. Groups 1, 3, 4 and
5 passed all 49 production targets and four exact replays. Group 2 failed because
the test expected Colorado's static database strength; the real unit correctly
had its happiness-dependent strength. The corrected expectation checks that
existing rule, including its zero floor. This containing run remains
`failed-functional-checks`: 508.3 seconds, normal exit 0, all settings/hooks/manual
saves preserved, no Lua runtime or synchronization errors and no new diagnostic.

`20260926T014759Z` recovered group 2 and passed groups 6, 7, 9 and 10, adding
50 production definitions and five exact replays. Group 8 correctly rejected
Portugal's caravan because there was no available land route. This second
containing run also remains failed: 470.1 seconds, normal exit 0 and full cleanup,
with no Lua runtime/synchronization errors or new diagnostic.

The final group recovery supplies a connected coastal trade cluster, origin
buildings, revealed range and normal technology-based slot capacity. It keeps
native route/production eligibility checks. Group 8 has three Portuguese targets,
so its corrected cap is seven turns. The new snapshot also includes active trade
routes and available/used slots. A source audit covered player/city train gates,
extra unit technology requirements and the installed UnitCreated handlers before
this recovery; no additional extra-tech or project gate applies to the catalogue.

`20260926T015851Z` passed all 16 group-8 production checks, three aggregate
checks and exact reload: 167.2 seconds, six ordinary turns, normal exit 0 and
full cleanup. No new Lua runtime/synchronization error or diagnostic occurred.

**All 115 production definitions now have passing owner-production evidence,
145 functional assertions and ten exact replays across the ten groups.** The
115 acquisitions used nine human and 106 AI owner paths. At the checkpoints,
114 produced unit instances remained present with their original types. Portugal's
cargo ship had been produced, and the final state contained a sea food route
instead of that idle unit; its route state/slot count also matched after reload.
Route activation was observed state, not a separately asserted route command.

| Group | Definitions | Ordinary turns | Passing evidence run |
| --- | ---: | ---: | --- |
| 1 | 12 | 4 | `20260926T013858Z` |
| 2 | 11 | 2 | `20260926T014759Z` |
| 3 | 13 | 4 | `20260926T013858Z` |
| 4 | 12 | 2 | `20260926T013858Z` |
| 5 | 12 | 4 | `20260926T013858Z` |
| 6 | 10 | 2 | `20260926T014759Z` |
| 7 | 14 | 4 | `20260926T014759Z` |
| 8 | 16 | 6 | `20260926T015851Z` |
| 9 | 9 | 2 | `20260926T014759Z` |
| 10 | 6 | 2 | `20260926T014759Z` |

The two mixed batches remain failed reports; their completed stage/reload pairs
are identified individually. An uninterrupted all-groups pass using the final
harness revision is not claimed. No product code changed for this work.

Independent evidence is `build/macos/unit-production-validation-20260926.json`,
SHA-256 `7333336d0789c98c062e84a32768a59106091e8f73a68c45f0c04d49ab60a0d3`. It records every native birth, group outcome, checkpoint
hash, exact replay and deferred definition. All 20 accepted checkpoint copies
were independently compared with the completed original manual saves. The audit
matched the production/deferred union to all 125 playable unique definitions.

Final preservation verification confirmed stock active, no Civ V process,
569 prior manual saves unchanged, the original quicksave unchanged, settings
restored, all 32 stock UI hashes intact, and canonical/Aspyr backups matching
`0da6a5ffc283c3f147b20a7ec426e4ed85a6838ab891faf61b50af4e25c4a09c`.
The offline dispatcher tests (24), save-copy tests (7), scenario-core checks and
Lua/plan preflight passed. Game outcomes above are native evidence, not inferred
from those offline checks.

## Reproduction and limits

The tested product is the clean `f33cfd33` College iterator package:
`build/macos/Lekmod-college-city-iteration-20260924.zip`, SHA-256
`9005a104f665ea4c5336c9ed8a85f31abdad782e33b277864a923ece3de09b01`.
All plans are under `LEKMOD_DLL/macos/batch-plans/`:

- `unique-unit-production-pilot.json`: group 1, five-turn cap.
- `unique-unit-production-a.json`: groups 1–5, 21-turn aggregate cap.
- `unique-unit-production-b.json`: groups 6–10, 21-turn aggregate cap.
- `unique-unit-production-recovery-b.json`: group 2 and groups 6–10, 24-turn cap.
- `unique-unit-production-trade-recovery.json`: group 8, seven-turn cap.

Each group starts from its own pinned turn-two save. These caps do not authorize
a new long campaign. Run through `batch-playtest.py` with the verified package;
the managed wrapper requires stock initially and restores stock afterward.

Separate acquisition paths are needed for Czech Foreign Legion, Vatican Swiss
Guard, Bolivia's Comparsa, Italy's artist, Macedonia's Hetairoi, Mongol Khan,
Madagascar's Mpiambina, Maurya's missionary, Tibet's Dalai Lama and Venice's
merchant. Some already have dedicated evidence elsewhere; their creation or
purchase is not this catalogue's production evidence. This catalogue does not
establish every unique ability, combat interaction, upgrade, AI decision or
human-owner variant, and does not resolve startup/shutdown reliability.
