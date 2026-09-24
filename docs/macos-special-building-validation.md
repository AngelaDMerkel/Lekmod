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
the correction. This is a confirmed gameplay defect in shared source. Commit `f33cfd33`
replaces the count-based loop with the existing firstCity/nextCity iterator. It
changes no object layout or save format. All 128 source-block cases now pass
under ASan/UBSan, including selected research and no-research overflow.

Reproduction plans are `unique-building-special.json` and
`unique-building-special-recovery.json` under `LEKMOD_DLL/macos/batch-plans`.
They pin the exact local fixtures. Both used clean archive
`f1a88db4b2f33def33ba263be95915eae401da3af2239a31fceb2cfacffcc64c`.
Acquisition coverage does not establish every building effect. The later
[Vatican ability continuation](macos-vatican-validation.md) verifies St Peter's
pressure/delegates/settlement; other trait/mission boundaries remain separate. No full single-player certification is claimed.

## Fixed-package native regression

Clean-source `f33cfd33dfcb38ee7ab0d981b437067f07ad15c3` produced:

- Archive `build/macos/Lekmod-college-city-iteration-20260924.zip`:
  `9005a104f665ea4c5336c9ed8a85f31abdad782e33b277864a923ece3de09b01`.
- Signed core: `2dcc90942588da45f5c8c04d38aec131a33e3a07333075fdb03df63054c8abc1`.
- Payload: `094d1dcf9635d2d8392fd49bbe7c9a88dadf1767813f5383f0ddf6b708e19a3e`
  (unchanged from the prior fixed-content candidate).

The exact packaged signed core passed ABI validation against this Mac's Civ V
host. Run `20260924T220405Z` then passed the complete seven-stage regression in
**264.1 seconds**, one native process, **33 functional checks and seven exact
replays**, with five ordinary turns across independent fixtures. This includes
all four acquisition cases again, baseline replay, normal College rewards and
the identical preserved city-loss fixture. Both reward cases now grant exactly
50 science and 50 faith through native Great Engineer expenditure and reload
exactly; no expected reward or outcome was assigned. Native exit was normal (0).

All 13 checkpoint hashes and every archive manifest entry were independently
verified. There were no Lua/synchronization errors or new diagnostics. Stock,
both canonical/Aspyr backups, 489 prior manual saves, the original quicksave,
32 stock UI files and settings were verified after restoration. Lekmod/private
EUI are inactive and no game/test process remains. Full per-stage hashes and
restoration evidence: `build/macos/special-building-fixed-validation-20260924.json`.

Reproduce this final batch with:

```sh
python3 LEKMOD_DLL/macos/batch-playtest.py \
  --plan LEKMOD_DLL/macos/batch-plans/unique-building-fixed-regression.json \
  --minutes 20 --package build/macos/Lekmod-college-city-iteration-20260924.zip \
  --sha256 9005a104f665ea4c5336c9ed8a85f31abdad782e33b277864a923ece3de09b01
```

The retained original/recovery failures are not relabeled. The source-block
regression covers 128 cases; dispatcher and runner checks pass 23 and 33 cases.
All 90 unique building definitions now have at least one tested acquisition
path and exact persistence evidence across the regular/special catalogues.
This does not establish every building effect or owner/state combination.
