# Civilization startup matrix

Ten groups cover all 114 playable civilization choices exactly once (nine groups
of 12 and one of six). The inventory is pinned to the shipped gameplay XML hash;
a change requires review/regeneration. These are normal single-player starts on
Huge Pangaea, Ancient/Quick/Prince, with no city-states, barbarians or ruins.

Each case requests two ordinary human turns, allowing a third for normal AI
founding. It verifies the requested civilization/leader and human/AI slots,
distinct valid player colors, generated starting units, real owner-turn callbacks,
and native capital founding for every major. The saved snapshot includes every
major's identity, leader, color, treasury/culture/faith/happiness, cities and
buildings/yields, units and promotions. No city, unit, yield, research, policy or
turn outcome is supplied by the scenario. It tests initialization/founding and
persistence, not every civilization's unique ability.

The guarded launcher installs one verified package, retains it between groups,
stops at the first failure, and restores stock. It checks the unlocked desktop
and existing Steam session before each launch, enforces individual and matrix
wall-clock limits, and never runs multiplayer or autoplay. `--from-group` resumes
at a specifically chosen unfinished group without rewriting earlier reports.

Passing saves produce one pinned replay plan, allowing all exact reload checks
in a single process. Each replay stage pins both its save and the original
passing report, verifies their hashes/scenario association, and compares the
original snapshot without executing setup or gameplay actions. Ordinary batch
stages keep their existing run-plus-reload behavior. Replay-only stages require
zero turns and cannot be completed merely by report existence.

## Offline verification

```sh
python3 LEKMOD_DLL/macos/civilization-startup-matrix.py --all --preflight-only
python3 LEKMOD_DLL/macos/test-civilization-startup-matrix.py
python3 LEKMOD_DLL/macos/test-playtest-batch.py
```

Four matrix inventory/refusal/package-data tests, 23 batch supervisor cases and 33 runner
cases pass. Four new supervisor cases cover replay-only startup/advance,
report/save/hash mismatch, failed reports, partial settings and non-object
snapshots. Replay-only native commissioning passed as recorded below. Normal-start group commissioning is in progress; unrecorded groups remain untested.

## Next unlocked-session commands

First commission replay-only mode with the two already verified inventory saves:

```sh
python3 LEKMOD_DLL/macos/batch-playtest.py \
  --plan LEKMOD_DLL/macos/batch-plans/replay-pilot.json --minutes 10 \
  --package build/macos/Lekmod-release-candidate-tunisian-fixed-20260922.zip \
  --sha256 f1a88db4b2f33def33ba263be95915eae401da3af2239a31fceb2cfacffcc64c
```

Then commission the first normal-start group:

```sh
python3 LEKMOD_DLL/macos/civilization-startup-matrix.py --group 1 --minutes 15 \
  --package build/macos/Lekmod-release-candidate-tunisian-fixed-20260922.zip \
  --sha256 f1a88db4b2f33def33ba263be95915eae401da3af2239a31fceb2cfacffcc64c
```

After a passing first group and exact replay, run the remaining groups with
`--all --from-group 2 --minutes 60` and the same package/hash. Each invocation
writes reports, group logs and `replay-plan.json` under
`build/macos/civilization-matrices/TIMESTAMP/`. Run that emitted plan through
`batch-playtest.py` with the same verified package. Preserve failures and keep
native setup, scripted callbacks and actual mouse interaction separate.


## Native replay pilot: passed

`20260922T233116Z` loaded both pinned inventory saves and exactly matched their
original report snapshots in one native process, with zero ordinary turns.
Duration was 71.1 seconds. Both output checkpoint hashes were independently
verified. Native exit was normal (0); settings/hooks and manual saves were
preserved, with no Lua/synchronization errors or new diagnostics. The wrapper
restored stock. Evidence: `build/macos/playtests/20260922T233116Z/` and
`build/macos/replay-pilot-clean-fixed-20260922.log`.

This run installed and exercised the exact clean-source archive
`f1a88db4…cc64c`, closing its pending transport/install step. It commissions
replay-only batching, not the 114-civilization matrix or broader unique abilities.
