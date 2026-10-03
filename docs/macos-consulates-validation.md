# Consulates ownership and saved-state correction

The unchanged product failed both native adoption orderings in
`20261003T003911Z`: at Industrial, the first owner received the expected two
policy delegates and the second received only one. Reversing human/AI order
reversed which owner lost the era award. Native research to Modern added one
to each, preserving the incorrect3/2 totals. No test assigned delegate counters.

The original Lua removed its shared adoption listener after the first owner.
Its `TeamSetEra` callback also indexed Players with the supplied team ID. Actual
Lua tests reproduce missed or misdirected awards for nonmatching/shared teams;
those cases remain isolated callback evidence, not native team-game coverage.

The focused correction keeps the adoption listener, finds owners by team, and
reconciles the saved policy-vote counter from active policy base delegates plus
Consulates era entitlement. The counter's native writer is policy processing;
Consulates is its only shipped Lua writer. A load callback repairs old missing
or excess era awards. Trait/building/Congress delegates use separate counters.
No retrospective Congress decision or previously spent vote is changed.

Twenty-eight actual-Lua checks pass after the change; nine failed before it.
They include both orders, all eight eras, mismatched/shared teams, skipped eras,
repeat notifications, missing/excess saved awards, unrelated active/blocked
policy base values, nonowners and dead owners. Native fixed qualification is
still pending. The ordinary matching-team era increment had already worked.

## Retained native baseline

Package `build/macos/Lekmod-array-audit-v2-20261002.zip`, SHA-256
`e86ea1f5e2faeb00c9c8bcabbac773e5f78284f3fc269b29282140087bab71bf`;
GameCore `c8f1723c7588fdf54465781ebbca9d8de009e3e11c76ba6375b5200fd9687aa2`.
The82-assertion batch completed in671.9seconds with five aggregate ordinary turns.
Its verdict remains failed:80 assertions passed and the two second-owner awards
failed. Seven successful earlier stages replayed exactly; failing stages saved
their actual state without a passing replay. Native exit0, no Lua/synchronization
or new crash diagnostic, settings/UI restoration and909baseline files were verified.

Artifacts live under `build/macos/playtests/20261003T003911Z/`. The failure saves:

- Human-first: `consulates-human-first-run.Civ5Save`, SHA-256
  `7039a7701c853905ecbdfb560ea33fa3fe4fed1381e73e9a8dcf48b3f67c5d19`.
- AI-first: `consulates-ai-first-run.Civ5Save`, SHA-256
  `7fa289925137f0a8676e06fe6191adac1003270e97fd37fe767f66af045218e0`.

Use the exact full saved-copy paths pinned by
`batch-plans/cache-and-reward-regression.json`; the names above identify stages.
The unchanged source is retained at
`build/macos/consulates-policy-before-20261003.lua`. Original and expanded failing
source logs, the fixed source log and independent file-preservation report remain
in `build/macos/`. No physical mouse coverage follows from these scripted commands.

## Required fixed retest

The combined plan now has88 assertions/11exact replays and a16-turn aggregate
cap within40minutes. It reruns the original stages and adds both authentic failed
saves. Before scenario mutation, loaded owner/team/era/policy/free-choice/turn
fields must match the saved snapshot with only the missing counter corrected
to3. A further ordinary round and exact replay must remain stable. Final G0,
candidate applicability and F/R acceptance remain open.
