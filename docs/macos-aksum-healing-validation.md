# Rock-Hewn Church ordinary healing

`20260927T211322Z` passed six native assertions and an exact replay in three
ordinary turns, with normal exit0, restored settings/UI and preserved manual saves.
No Lua/synchronization error or new crash diagnostic was reported. No product
change was needed. The tested archive is the Moorish-fixed candidate
`62d71ca82c8cb21d96198a23df3e3e1e931d2f09976675d3d64117f37421d53e`.

`batch-plans/aksum-ordinary-heal.json` pins the original group-01 fixture. Two
Churches, plot ownership, units,60 damage and upkeep funds are supplied inputs.
Normal Heal missions and owner turns perform every healing operation; no negative
ChangeDamage call or faith assignment is used. A read-only prefix/suffix observer
brackets the actual Aksum handler in its own Lua context, separating each award
from passive faith income. The observers never invoke the product handler.

Native observations verify:

- land healing on or adjacent to the owner's Church restores actual HP and
  awards exactly2 faith per event;
- a land unit next to another owner's Church receives the same award;
- actual sea healing and distance-two land healing award0;
- a healthy nearby unit produces no heal event or award;
- normal movement outside radius1 removes eligibility, and later ordinary
  healing there restores HP while awarding0 faith.

The earlier air-domain exclusion remains separate native event-stimulus evidence;
this run does not claim ordinary aircraft healing. It also does not establish
Church construction, autonomous AI healing choices or physical mouse interaction.

Raw reports, event deltas and verified closed-writer/source-copy checkpoint hashes
are under `build/macos/playtests/20260927T211322Z/`. The register requires the
original native assertions, exact replay, exit and preservation evidence. Final
single-player acceptance and remaining coverage mapping are still open.
