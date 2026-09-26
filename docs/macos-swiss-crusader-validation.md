# Swiss Guard and Crusader utility checks

The user resumed on September 25. The two previously unfinished Swiss workflows
now pass with exact reloads; their original failed reports below are retained.
Further city-plunder and hostile-healing cases also passed. No product code was
changed for this continuation; a confirmed asynchronous test-checkpoint copying
race was fixed separately.

## September 26 completion and additional boundaries

- `20260926T000754Z`: all six healing/pillage/mounted-calculation checks and two
  exact reloads passed in 115.8 seconds, two ordinary turns, normal exit 0. The
  fixture now reserves center/adjacent/control/exit together. After the Guard's
  ordinary move, both healing probes recover 10 HP, proving removal of the +10
  aura. Mounted targets exclude every other unit within two tiles: both mounted
  classes now show exactly +50 and 3750 strength against the 2500 melee control.
- `20260926T002908Z`: all nine city-plunder checks and three exact reloads passed
  in 149.5 seconds, zero turns, normal exit 0. Each ordinary attack inflicted
  32 damage on a surviving city. With the default promotion, the attacker gained
  32 gold; the defender lost 32 from a supplied 500 treasury or zero from an empty
  treasury. A diagnostic promotion-disabled control dealt the same damage and
  transferred no gold. Supplied defenses, attacker health, staging and budgets
  are inputs; damage and treasury changes are outcomes. The gold rule is based
  on city-attack damage, not a captured-city reward.
- `20260926T005339Z`: both hostile-healing assertions and exact reload passed
  in 83.7 seconds, one turn, normal exit 0. On explicitly supplied hostile plots,
  the Guard healed 15 HP and the ordinary-unit control 10: the expected +5 enemy
  self-heal. Plot ownership, staging and wounds are inputs, not earned territory.

These runs add 17 assertions/six exact reloads across three native processes.
All checkpoint hashes, complete manual-original equality and reload snapshots
were independently verified. The clean package remains `9005a104…09b01`, core
`2dcc9094…8abc1`. Stock/backups, 541 prior manual saves, original quicksave,
32 stock UI files and settings were independently verified after restoration.
Evidence: `build/macos/swiss-completion-validation-20260926.json`.

The initial city-plunder run `20260926T001629Z` retains its abort (-6): the harness
copied a still-writing save at 532,480 bytes, while the untouched original later
completed at 728,776 bytes. The former is an exact prefix of the latter. The
host subsequently threw while reading that partial copy. Original, truncated
copy, completed-copy preservation and delayed crash report are all retained.
`d7dd1237` now waits for the game to close writable handles and for stable file
metadata, then requires equal source/candidate bytes before publishing a loadable
checkpoint. Seven delayed-write/race/native-descriptor tests and 24 dispatcher
checks pass. Native retest verified every new checkpoint against its complete
source before loading. A read-only audit of 214 prior batch copies found only
this one mismatch; all manual originals remain preserved.

Startup-255 failures `20260926T000157Z` and `20260926T003550Z` remain failures;
no Swiss actions ran in either. The second preserved a healthy nonempty cache
before stock restoration using the new failure-snapshot code. A debugger attach
probe was unsuccessful and required scoped cleanup of its owned stopped process;
it is neither a functional run nor a successful startup control. See
[the startup investigation](macos-startup-cache.md). Successful traced retries do
not resolve that intermittent issue. No new physical mouse coverage or full
single-player certification is claimed.

## Crusader: passed with exact reload

Run `20260924T231805Z` verified the actually produced Crusader's native combat
calculation: attack strength 1700 on the friendly control versus 2040 outside
friendly land, with exactly +20 percentage points in the native modifier list.
This is calculation coverage, not an independently measured damage comparison.

With peace and staging explicitly supplied, the Crusader could enter a Roman
border tile while an ordinary Longswordsman control could not. Its normal AI
owner-turn move then actually entered the peaceful rival territory; the control
remained outside. All three assertions and exact state reload passed. The
containing 95.5-second batch failed its separate Swiss fixture because the chosen
healing pair had no matching control site in the selected distance band.

## Historical Swiss commissioning failures

Run `20260924T232415Z` (81.4 seconds) reused the actual gold-purchased Swiss Guard.
Its normal Pillage action pillaged a supplied abandoned farm without spending
movement, with normal loot/healing bounds. A normal healing turn then restored:

- 20 HP to the adjacent supplied wounded Warrior;
- 10 HP to the matched neutral-territory control;
- 15 HP to the Swiss Guard itself.

This verifies +10 adjacent healing and +5 neutral self-healing. Wounds and
positions were explicit fixture inputs; restoration of HP was an ordinary
healing outcome. The next range-removal step failed because the selected group
had no legal adjacent escape tile satisfying the test's constraints. It did not
execute that comparison, and this Swiss stage did not perform its exact reload.

A separate zero-turn native-calculation stage compared the Swiss Guard against
supplied ordinary melee, mounted melee and mounted ranged defenders. The mounted
melee case passed: +50 percentage points, attack strength 2500→3750. The mounted
ranged case's native list contained the expected +50 contribution **and an
additional +20 flanking contribution**; strength was 4250. The test incorrectly
required the total modifier difference to be only 50 despite that different
flanking context. Its FAIL remains unchanged, and no exact reload was performed
for that stage. This observation is not a confirmed product defect.

The subsequent successful retest above addressed the earlier next steps: choose a complete healing group including a legal exit before
issuing actions, and give the mounted comparisons matched flanking geometry (or
independently account for the observed flanking contribution). Retest those
cases and their exact reloads. Do not rerun or relabel the passed Crusader case
without a relevant change. The current tools preserve both commissioning plans:
`swiss-crusader-utility.json` and `swiss-healing-mounted.json`.

All tests use clean archive `9005a104…09b01`, core `2dcc9094…8abc1`, and the
pinned acquired-unit save SHA-256
`cd2445e36ecab1163b3695a810c03198363b3cb9a875651391817b14faab0117`.
Actions here are scripted commands/native outcomes; no physical mouse coverage
was added. No product code was changed in this round.

## Stop and preservation verification

Every checkpoint hash and the passing Crusader snapshot pair were independently
verified. Stock and both canonical/Aspyr backups have SHA-256
`0da6a5ffc283c3f147b20a7ec426e4ed85a6838ab891faf61b50af4e25c4a09c`.
526 prior manual saves, the original quicksave, settings and
32 stock UI files were preserved. Lekmod/private EUI are inactive and no
native game or test process remains. Full paths, hashes, outcomes and restoration
evidence: `build/macos/swiss-crusader-stop-verification-20260924.json`.
This was the prior pause checkpoint; the user has since explicitly resumed.
The locked-desktop launch guard remains in force. No push occurred.
