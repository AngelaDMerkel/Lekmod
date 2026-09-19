# Foreign Great Work exchange, 2026-09-19

## Fixture and confirmed UI defect

`greatwork-exchange-prep` loads the preserved two-artwork save `20260916T050343Z`.
Run `20260919T052713Z` supplied Belgium's capital with Museum/Amphitheater slots
where absent and one Artist/Writer. Both used normal Create Great Work missions
on Belgium's actual owner turn. One ordinary turn advanced 179→180. The resulting
artwork (ID 2) and writing (3) retain Belgian creator/controller 1. Human artwork
IDs 0/1 remain Roman. Normal set-swappable commands supplied the two foreign
offers explicitly; this is not autonomous AI negotiation. Save SHA-256:
`0e9a69ad49d225c9fd36902a77251d18a919dfcd2c4bb318f4e418818dd54cac`.
Exact prepared-state reload `20260919T052854Z` passed, save SHA-256:
`e97ba5b664a868aaa9a6501adaff7293ff2bb72fa6c91b44d10d1c4b00254d46`.
Both exited normally and restored settings/hooks/manual saves.

Native class IDs are art 0, artifact 1, literature 2 and music 3. The shared
CultureOverview swap functions assumed 1/2/3/4. Physical standard baseline
`20260919T053030Z` confirmed the result: the Art dropdown offered only Empty This
Spot despite two owned artworks, and selecting Belgium's artwork left its
selected icon blank. No exchange, offer change or save occurred. Physical normal
exit returned 0 after 184.9 seconds; cleanup passed without Lua/sync errors.

The correction uses `GameInfoTypes.GREAT_WORK_*` in class matching, selected-work
icons and the three enabled offer dropdowns. The icon guard now tests the actual
`strTexture` variable instead of undefined `strImg`. Music's commented-out UI
remains disabled. The common standard template is also assembled into EUI.

`test-great-work-swap-ui.py` executes the actual selection and dropdown functions
under Lua 5.1 with minimal UI/engine stand-ins. Its 27 cases cover stock,
zero-based and permuted class IDs, matched offers, icon textures, clear entries
normal offer-command arguments, missing matching offers and both empty-texture
guards. Before: 17 failures. After: all 27 pass.
UI assembly tests also passed all nine cases. These isolated checks do not
establish native exchange of every work class.

Baseline physical evidence under `20260919T053030Z`:

- `swap-art-dropdown-empty-baseline.png`: `63a5864c544860f72e3d4693e51329bb38213bdc7eb1b6a658010124933120d4`
- `swap-foreign-art-baseline.png`: `25f5adbd2a8bb572be37ade8d764326f83611cb042273069c375e073a56a63ef`

## Physical standard retest and saved outcome

Run `20260919T053552Z` loaded the same prepared fixture at requested 1440×900.
Actual mouse actions opened tourism counter → Swap Great Works → Art dropdown.
It now listed Self portrait and The Child's Bath with correct creator/era labels.
Self portrait was offered. Selecting Belgium's Kokin wakashu writing kept Yours
empty and Swap unavailable; clicking Swap changed no holdings. Clear reset the
pending selection and retained the art offer. Selecting the Belgian artwork then
showed both matching art icons and enabled Swap.

An actual Swap click exchanged Self portrait (1) for Dutch men-o'-war (2), cleared
both art offers, and left the unrelated writing offer visible. Your Culture
showed two works in Rome, with Museum theme 2→1 and tourism 6→5 for the mixed
creator pair. The read-only observer independently recorded Roman slot 0 changing
1→2, slot 1 retaining 0, turn 180 and gold 2,046 unchanged.

The initial F5 key opened Social Policies; it was closed without a choice.
The actual save used F11 and showed Quicksaving. Its retained copy is
`20260919T053552Z/Standard-Foreign-Exchange-QuickSave.Civ5Save`, SHA-256
`a6dd0b8debe5c2c1f631a9f9db9db297e763037ea981f1b899bc202d0468871b`.
Actual Escape → Exit to Windows → Yes exited normally (0) after 302.4 seconds.
Settings/resolution/hooks and manual saves were preserved, with no Lua/sync
errors or new diagnostics. The original quicksave was separately backed up
before F11, then restored byte for byte after the owned game exited, SHA-256
`92c6f2301ced5ef6a4355f07f3186a307febc225b9389d73b35e817568ccd5f6`.
The preservation manifest is `build/macos/greatwork-exchange-quicksave-preservation-20260919.json`.

| Retest screenshot | SHA-256 |
| --- | --- |
| `swap-art-dropdown-fixed.png` | `98d67d2936a3615e801833a513fbd8e0df8c564009f902fb3b641be64ba1cc63` |
| `swap-writing-rejected.png` | `4094799331edaf8086892baff3ff92232d9545fe64cd6d0f6286fe7842eb9480` |
| `swap-art-ready.png` | `0444a9a7121e306777e6366a845430452ecdcf81378bc63d966045f9221f34fd` |
| `swap-completed-holdings.png` | `b33f8f38b9c0bd3b002148e5bfa19b98f84583aeb8895ad2dfd1bd19afae0e0c` |

Read-only native verifier `20260919T054229Z` loaded that physical quicksave and
passed all four assertions. Work 1 now has controller 1/creator 0, work 2 has
controller 0/creator 1, while works 0 and 3 retain their owners. Both players
still have two works; the exchanged works occupy their counterpart Museum slots.
Rome's theme/tourism are 1/5, Belgium's base tourism is 4. Both art offers are
cleared, and Belgium's writing offer 3 remains. No fixture mutation or ordinary
turn was requested. The normal save/exit returned 0 with cleanup verified; save
SHA-256 is `a58bb112afd21bae7fef1528f84cc11e63df5cc39391762eea3ab2c1f4ecf5f1`.

## Artifacts and open checks

Standard intermediate archive `Lekmod-greatwork-swap-20260919.zip` SHA-256:
`014077403f0f6d991f4ff27a5b42955bb2cf3bdbceda9c4239275780da4add0f`.
Signed core remains
`689df45d69b4b772e408155c4f443d09ad6a936039205cee6e62747fd8cca3d6`;
the product correction is Lua-only. The prepared private EUI variant is
`Lekmod-eui-greatwork-swap-20260919.zip`, SHA-256
`6bf7bcc15946cb3b616af65f9e3a64e9ac7e3ac4de86996bb173fb53ef9f78f4`.
These packages were built before the UI correction's commit and are not the
final clean release. Private EUI assets are not redistributed.

Paired physical EUI exchange is recorded below. This evidence does not
claim native writing/artifact exchanges, autonomous offer decisions or all
same-turn/invalid-command boundaries. Multiplayer remains deferred.

The separate exact-reload attempt `20260919T054410Z` failed during startup
with exit 255 before any save inspection. Its healthy cache was preserved,
not deleted; see [startup evidence](macos-startup-cache.md). A following
intro-enabled comparison is separate evidence, not a relabeling of this failure.

After separately retained default/intro/original-settings startup failures and a
stock-menu comparison, the identical Lekmod package was reinstalled. Exact
post-exchange reload `20260919T060419Z` passed with normal exit and preservation
checks, save SHA-256
`9f90f8777c4b16c8f7a8306da8ff43a9dc12b8471d8da1b27f80d5298d50cfeb`.
Startup reliability remains open; the reload does not erase those failures.


## Paired EUI exchange and cross-UI persistence

EUI session `20260919T060635Z` loaded the same prepared fixture at requested
1440×900. Actual tourism-counter → Swap Great Works → Art-dropdown clicks
listed both Roman artworks. Selecting Self portrait, reopening the dropdown and
choosing Empty This Spot withdrew its offer while leaving Belgium's offers
unchanged. Self portrait was reoffered. Selecting the foreign writing and clicking
the unavailable Swap control caused no exchange. Clear reset that selection;
selecting the foreign artwork then displayed the matching icons and enabled Swap.

An actual Swap click transferred the same works, cleared both art offers and
changed Rome's Museum theme/tourism to 1/5 while retaining two works. Both the
initial and final complete observer signatures match the corresponding standard
session after stripping only timestamps/run IDs. Turn 180 and gold 2,046 remained
unchanged. These are actual mouse outcomes, not scripted swap callbacks.

Physical F11 saved the result. The retained copy
`20260919T060635Z/EUI-Foreign-Exchange-QuickSave.Civ5Save` has SHA-256
`b7a54326cd954e71a054bd874da26cc661e05da1b4f657ffd9b3c47372a9d084`.
Actual Escape → Exit to Windows → Yes exited normally (0) after 353.1 seconds.
Settings, resolution, hooks and manual saves were preserved, with no Lua/sync
errors or new diagnostics. Wrapper `eui-tests/20260919T060626Z` verified exact
standard archive `01407740…add0f`, EUI text and options restoration. The original
quicksave was again restored byte for byte to `92c6f230…ccd5f6` after the owned
game exited and its test result had been copied. The runner/wrapper CLI result 1
reflects `ended-manual-ui-session`, not native failure.

Cross-UI reload `20260919T061330Z` loaded that physical EUI save under restored
standard UI and exactly matched the full two-owner scenario snapshot from
standard verification `054229Z`: creator/controller IDs, classes, names/eras,
slots, total counts, offers, city tourism/themes and turn. This is a logical
snapshot match, not a claim of identical save bytes. Normal save/exit returned 0
with cleanup verified; save SHA-256:
`252a00e101cb2d60c10f32f1632d5b1acc9fb2aa3e03e5d8cd47a36a0f90ca13`.

| EUI screenshot | SHA-256 |
| --- | --- |
| `eui-swap-art-dropdown.png` | `c873b434d0642262d653e709f27d27cfb29e35207957f13a79c7f6f19c882624` |
| `eui-swap-offer-withdrawn.png` | `d754bed07a084c576efef34d9f6b73d939cc0fe1685923ec48d389a4fadcbee4` |
| `eui-swap-ready.png` | `3952106ecd99c014946a7f0e31aa3431f44842e8e76040099154e05c7cb5e10f` |
| `eui-swap-completed.png` | `60df725906c3fe919612ebc316b953352e85255f4917276eda27091e9eb633a7` |

This completes the paired foreign-artwork workflow and its saved ownership
outcome. Native exchanges of writing/artifacts and further invalid-command
boundaries remain separate; full single-player coverage is still open.
