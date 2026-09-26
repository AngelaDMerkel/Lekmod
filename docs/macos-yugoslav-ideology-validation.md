# Yugoslav ideology reward: native reproduction and fix

The tooltip promises a free tenet when adopting **or switching** ideologies.
The original handler rejected any event during anarchy. Both normal human
`ResponseChangeIdeology` and AI revolution code set anarchy before
`DoSwitchIdeologies` emits `PlayerPolicyBranchUnlocked`, so a normal revolution
loses the promised bonus. The focused Lua fix removes that rejection while
retaining living-owner/civilization/ideology checks. It does not modify anarchy,
standard early-adopter tenets, policy costs or synchronization state.

## Native baseline

The short human Yugoslavia / AI Spain fixture was normally initialized in
`20260926T170320Z`,73.2 seconds, normal exit0. Fixture SHA-256
`c5e4d974273b9306c9330398a81757e0ec3b64ffa21cedcbe1aee7dac53b44e5`,
report SHA-256 `4e11776ec610dad9fd602ff345c06265f97331a5600b7f230e1b506dc39a4eba`.
Matrix: `build/macos/civilization-matrices/20260926T170315Z`.
Earlier `20260926T170206Z` failed before gameplay with startup255 in20.4 seconds;
its nonempty25,509,888-byte merged localization cache passes SQLite quick_check
and is preserved (SHA-256
`818f6955bead48adab19a9be1311a8dc52b1b4336b7e4a2d55d82a3eb9111241`).
Stock/settings/UI were restored. The independent traced start is not a startup fix.

## Reproducing sequence

`20260926T170551Z` used the unchanged Swiss package
`6786af0ce4f8fac3aa01fbebcd547ef4b88d84792077549a55ecbf028c05dc5e`.
It supplied Radio and prerequisites, population25,1000 culture, contact,
Spain's opposing Order ideology, and positioned Spanish musicians. Original UI
callbacks cancelled then confirmed human Freedom adoption and later revolution.
Actual AI-owner-turn concerts and ordinary turns generated public pressure;
influence remained below the victory threshold. No ideology event, anarchy,
public-opinion result, turn number or winner was assigned to obtain a pass.
Spain's explicitly supplied native branch unlock is a control, not an earned
adoption. These are scripted UI callbacks and native outcomes, not mouse clicks.

Ten checks passed: adoption/cancel, standard-only Spanish allowance, both sets
of rival-ideology effect buildings, real concert pressure, revolution cancel,
content-revolution rejection, required anarchy and natural expiry. The advertised
switch bonus failed: standard calculation plus Yugoslav bonus expected11 free
tenets; actual10. The complete round remains `failed-functional-checks`,173.1
seconds, four ordinary turns, normal exit0, no Lua/synchronization errors/new
crash diagnostic and full runner restoration. Its baseline fixture replay passed;
the failed functional stage is not counted as a passed scenario/replay.

Report: `build/macos/playtests/20260926T170551Z/report.json`, SHA-256
`14877661b00a8802cef2d2d1428d784197c2189afb10c851433c0e44d33e8ad3`.
Checkpoint: `build/macos/playtests/20260926T170551Z/checkpoints/Lekmod-Batch-20260926T170551Z-yugoslavia-ideology-run.Civ5Save`,
SHA-256 `2f3c890af0c798310d58f4d6392c7abdacfa6b5f0d0c33dcf48ccd1093393394`.

## Regression scope

The callback suite now checks revolution events for all three ideologies while
preserving anarchy and unrelated owners' tenets. All three cases fail with the
original guard; all31 city/policy cases pass after the fix. These are offline
callback checks. The previous offline expectation that anarchy must reject the
reward contradicted the advertised switching behavior and has been replaced.
The same native scenario and exact reload must pass on the new clean package
before native closure is claimed. No retrospective tenet grant is inferred from
older saves: their missing rewards cannot be reconstructed reliably from current
state alone.

Rival-effect building presence passed natively for the human owner. A scratch
plain-table `ipairs(Players)` mock incorrectly excluded that owner; its failures
are not product defects. That experimental file/log remain ignored in
`build/macos`; no shared global-effect handler was changed on that basis.
