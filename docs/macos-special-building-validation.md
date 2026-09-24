# Special unique-building acquisition and rewards

The three definitions outside the 87-building regular-production catalogue now
have native acquisition and exact reload evidence on their real civilization
owners. These are scripted popup/mission/queue checks with native outcomes,
not physical mouse input or earned full campaigns.

The reusable four-civilization fixture `20260924T214605Z` has human Israel and
AI Vatican, Jerusalem and Rome. Normal setup, first owner turns, native capital
founding and a later exact replay passed. It uses Standard Pangaea, Ancient,
Quick, Prince, no minors/barbarians/ruins, and two ordinary turns. Fixture hash:
`cee385a99258c682176b8396600f3a27eafc0b98d81bb49e3e36ea95451bcd1a`.

| Case | Proven result | Passing run |
| --- | --- | --- |
| Israel gold College | Actual ProductionPopup callback; 199 rejected, 200 accepted and spent exactly; native gold purchase event; +3 science/+3 faith/+1 culture/+50 science modifier; duplicate gold/faith purchases rejected in both cities; exact reload | `20260924T215211Z` |
| Israel faith College | Same checks through faith purchase: 259 rejected, 260 accepted and spent exactly; native faith event; same yields and exact reload | `20260924T215211Z` |
| Vatican St Peter's | Nonholy capital rejected; engine religion founding enables holy-city production; nonholy second city rejected; actual AI owner-turn production; one free Cathedral in target city, one native Prophet creation, +8 building faith plus Cathedral faith, exact reload | `20260924T215211Z` |
| Jerusalem Outremer | Unoccupied home rejects it; real AI move/attack captures human original capital; human survives in a supplied second city; normal annex task, ordinary resistance expiry, eligible production, native occupation-unhappiness exemption, +2 culture/+2 faith and exact reload | `20260924T215818Z` |

Inputs are explicitly supplied research, prerequisite Libraries/Temples, legal
extra cities, gold/faith budgets, religion founding, a staged AI attacker and
near-complete production. The target buildings, captured ownership, occupation,
resistance expiry, free rewards, yield changes and purchase debits are outcomes.
The foreign purchase-reference city lacks some prerequisites, so that particular
rejection is not an isolated owner-only gate test. Its unchanged state is checked.

The first five-stage batch remains **failed**: its final capture assertion
incorrectly required a puppet to report IsOccupied. The native getter explicitly
returns false for puppets; the corrected test verifies puppet/capture first,
then occupation after normal annexation. No product change was made for that
fixture correction. The recovery batch also remains **failed**, because it
subsequently reproduced the College reward defect below. All runs exited normally,
restored settings/hooks and preserved prior manual saves, with no Lua/sync errors
or new diagnostics. Every checkpoint hash was independently verified; detailed
per-stage outcomes/hashes are in the ignored local artifact
`build/macos/special-building-before-fix-validation-20260924.json`.

## Confirmed College reward defect after city loss

Run `20260924T215818Z` exercised the same normal Manufactory build with a supplied
Great Engineer in two independent saves. With city slots 0 and 1 occupied, a
previously purchased College in city 8192 granted the expected Quick-speed
50 science and 50 faith, and exact reload passed. After the real capture, Israel
had only city 16385 in slot 1; slot 0 was empty. A normal College purchase there
followed by the same completed build consumed the Engineer and granted **zero**
science and faith. No reward balance, improvement or city ownership was assigned.

`CvPlayer::DoGreatPersonExpended` loops from zero to the current city count and
uses each number as a city slot. City loss can leave gaps, so a surviving city
outside that range is skipped. The source regression executes the actual
building-reward block with controlled city collections under ASan/UBSan: 64 of
128 dense/empty/sparse collection, speed and research/overflow cases fail before
the correction. This is a confirmed gameplay defect in shared source; native
fix verification is still pending.

Reproduction plans are `unique-building-special.json` and
`unique-building-special-recovery.json` under `LEKMOD_DLL/macos/batch-plans`.
They pin the exact local fixtures. Both used clean archive
`f1a88db4b2f33def33ba263be95915eae401da3af2239a31fceb2cfacffcc64c`.
Acquisition coverage does not establish every building effect: St Peter's
religious-pressure/delegate effects and broader trait/mission boundaries remain
separate. No full single-player certification is claimed.
