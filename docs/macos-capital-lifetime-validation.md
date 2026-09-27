# Capital and owner lifetime tests

Run `20260927T183038Z` passed24 native assertions, four functional exact replays
and one baseline replay in one302-second process, with11 total ordinary turns.
This closes the specified Palmyra elimination and Cuban capital-transition cases.
G0 reconciliation and final acceptance remain open.

## Inputs and results

Normal four-player startup `20260927T182422Z` selected human Cuba, two AI Palmyran
players and AI Rome, with no city/unit/yield setup. Five startup assertions passed,
including distinct resolved colors, real founding and owner turns. The native
fixture has SHA-256 `4156736307140be31b859a6db9febd9bc814143088abf7b62500a31f49c06d6e`.
Its recorded state matched exactly before any batch mutation.

The unchanged Steam-startup package from September26 was used throughout:
archive `edd00aa4d8eca910ee90777465e6db7eeae92b02aa2bff709f44fdb06b529002`,
core `2dcc90942588da45f5c8c04d38aec131a33e3a07333075fdb03df63054c8abc1`.
WSDLC `950a329`/v1.0.10 used the isolated pinned dependency runtime.

| Stage | Verified outcome |
| --- | --- |
| Palmyra duplicate | AI Palmyra captures the other Palmyran player's last original capital. The old owner is already dead at the capture callback. Current-owner freshwater remains on eligible adjacent land, controls remain correct, and a distinct subsequent owner turn/replay preserves it. Other majors keep the game active. |
| Cuban capital loss | A real AI capture relocates Cuba's capital to its supplied survival city. The actual Cuban owner callback applies the exact rounded foreign-capital quote there. The former capital and every other noncapital/foreign city have no Cuban culture marker. |
| Foreign capital loss | Rome survives a real capital capture in its supplied second city. Its lower capital-culture contribution is observed, and Cuba's next owner callback recomputes the exact sum without using the former Roman capital. |
| Foreign elimination | Rome loses its last city and is eliminated. Its missing capital contributes nothing; Cuba's next owner callback and an additional ordinary owner turn keep the exact current quote. |

Contact, source culture buildings, war, legal survival cities where required,
one adjacent GDR, uranium and upkeep are explicitly supplied inputs. The attacks,
elimination/relocation, Lua owner callbacks and culture/freshwater outcomes are
native. No city damage, owner, alive state, capital, reward marker or processing
flag is assigned. AI attack orders run only on their actual active owner turn.
These are scripted commands/native outcomes, not physical mouse or autonomous
strategic-choice evidence. The older Cuban unmet/contact tests remain separately
recorded in [the original report](macos-cuba-capital-validation.md).

Palmyra's aggregate register contract also requires the two earlier
[foreign-owner elimination stages](macos-palmyra-elimination-validation.md).
Those earlier failures retain their original verdicts. No product code changed
for this round.

## Reproduction and preservation

`civilization-startup-matrix.py --roster CIVILIZATION_CUBA,CIVILIZATION_PALMYRA,CIVILIZATION_PALMYRA,CIVILIZATION_ROME --allow-duplicate-civilizations`
prepares the normal fixture through the existing guarded package workflow.
Duplicates require this explicit custom-roster option; the114-civilization
catalogue remains unique and unchanged. All seven matrix checks pass.

`batch-plans/capital-lifetime.json` pins the exact fixture, baseline report and
independent stages. It preflights24 assertions/five replay checks and a23-turn
maximum; actual use was11 turns. Raw reports, source/copy save hashes and UI
originals are under `build/macos/playtests/20260927T183038Z/`.

The native process exited normally with code0, restored hooks/settings and
preserved manual saves. There were no Lua/runtime synchronization errors or new
crash diagnostics. `build/macos/capital-lifetime-preservation-20260927.json`
independently checks recovered saves/current settings, every single-player file
present before this run, original stock UI and canonical/Aspyr backups. Stock is
active and Civ V is closed. Nothing was pushed.
