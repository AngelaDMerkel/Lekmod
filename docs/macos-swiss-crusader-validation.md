# Swiss Guard and Crusader utility checks

Testing stopped at the user's request after the current round completed.
No new round was started. Both runs below exited normally (0), restored hooks
and settings, preserved manual saves, and recorded no Lua/synchronization errors
or new diagnostics. Both retain overall **failed-functional-checks** verdicts;
partial assertions are not full workflow or persistence passes.

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

## Swiss Guard: partial outcomes; follow-up required

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

On resumption, choose a complete healing group including a legal exit before
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
The original locked-desktop guard and pause/resume preferences remain in force;
wait for the user's explicit resumption before further tests. No push occurred.
