# Independent Merchant and Engineer reward checks

Run `20261002T212408Z` passed12 declared assertions and two exact checkpoint
replays in one127.1-second process, with zero ordinary turns. No product change
was required. This is scripted command/native outcome evidence, not physical
mouse interaction or autonomous AI decision-making.

## Merchant missions

Eight ordinary Trade missions covered Merchant and Merchant of Venice, Commerce
finisher absent/present, and Industrial/Atomic eras. Unit creation, contact,
policy and research prerequisites were explicit inputs. Gold/friendship outcomes
were never assigned. Expected amounts were calculated independently of native
quotes; the quotes and actual treasury/friendship deltas both matched.

| Era | Merchant | Venetian merchant | Merchant + policy | Venetian + policy |
| --- | ---: | ---: | ---: | ---: |
| Industrial gold |469|938|938|1407|
| Atomic gold |603|1206|1206|1809|
| Influence, either era |30|60|30|60|

At Quick speed, base gold is `floor((300+100*era)*67/100)`. The promotion and
policy each add100% to the same modifier; together they give3× base, not4×.
All eight actions consumed their unit. Own-major-city and unowned-location
eligibility queries rejected. Those are query controls, not rejected mouse
commands. City-state purchase and other speed/AI branches remain separate.

## Engineer hurry

The source formula is `floor((75+36*population)*67/100)`, capped by remaining
production. A legal837-production Great Firewall order was obtained by supplying
Computers prerequisites in a preserved Ancient-start Roman fixture. Population,
initial production and Engineers were explicit inputs.

Actual hurry actions added74,170 and339 production at populations1,5 and12.
A fourth action with85 remaining added exactly85, reaching837 without excess.
All four Engineers were consumed. A one-turn target rejected mission eligibility
and normal action availability while preserving its unit/progress; a non-city
plot returned0 and was ineligible. No ordinary construction-completion,
spaceship-part doubling or other-speed gameplay pass is claimed.

## Retained commissioning failure

`20261002T211912Z` exited normally0 but retains its failed-functional verdict.
The merchant scenario used nonexistent `ERA_ATOMIC`; the actual resolved type
is `ERA_POSTMODERN`. The Engineer scenario completed its first74-production
action, then correctly rejected its own fixture precondition: the Industrial-start
construction cost was too low for later uncapped cases. The revised Ancient-start
fixture retains all originally planned population values and cap controls.
No wait, synchronization, promotion, reward or movement flags were bypassed.

## Artifact and preservation

Both runs used `build/macos/Lekmod-config-edge-20260927.zip`, SHA-256
`0726506aaaffde2f2ef9cc32b86f036a4bc6d611bf420910a946174e3c549339`.
The actual archive member, manifest and installed/native GameCore hash agree:
`6c7aafb11d9e5aea80d1e7b95c6b8f3498820385f6e132abea81bad0b3b8cf6f`.
WSDLC remains clean `950a329`/v1.0.10 with its pinned Python dependency environment.

Reproduce with `batch-playtest.py --plan LEKMOD_DLL/macos/batch-plans/great-person-rewards.json`
and the archive/hash above. Raw reports/checkpoints are under
`build/macos/playtests/20261002T212408Z/`; full contracts/hashes are in the acceptance
register. Both replay states match, with closed-writer/source-copy hash checks.
No Lua/synchronization errors or new crash diagnostics were recorded.

The native process exited0 and restored settings/hooks. Independent audit
`build/macos/great-person-rewards-preservation-20261002.json` verifies all868 files
in the fresh pre-test manifest, including prior non-autosave single-player files,
current settings, original UI, stock host/core and backups. Stock is active and
no game/launcher remains. Full acceptance still requires G0, remaining gameplay,
final-candidate applicability/regression and R1–R5.
