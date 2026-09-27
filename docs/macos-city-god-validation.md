# City of God free-prophet validation

On September 27, 2026, the current Mac passed **36 native assertions and eight
exact state replays**, closing `REL-CITY-OF-GOD-GRANT` in the acceptance register.
No product code changed. The broader G0 review and final acceptance remain open.

## Candidate and inputs

Package `build/macos/Lekmod-steam-startup-20260926.zip`, SHA-256
`edd00aa4d8eca910ee90777465e6db7eeae92b02aa2bff709f44fdb06b529002`, used unchanged
GameCore `2dcc90942588da45f5c8c04d38aec131a33e3a07333075fdb03df63054c8abc1` and
payload `636ad673ef9b1662f71a617c2d4be5598695538972cffe314a9da0dee7bb82b4`.
WSDLC source revision `950a329` installed/restored the package. Its 168 tests
passed with the pinned certifi 2026.7.22 dependency in the isolated test runtime.
The system runtime's dependency failure remains recorded separately.

The initial fixture is the normal group-09 save from `20260922T234627Z`, SHA-256
`81fb0432eeb5737ed7446a89500e097422b565eab4e87273ff6e104d9b6c6d5c`.
Religion and policy prerequisites are supplied setup. The tested grant is produced
by `Network.SendFoundPantheon`, never by assigning units or the one-shot flag.
Human Spain exercises the default Prophet; an explicit command for AI Tibet
exercises the Dalai Lama replacement. This does not establish autonomous AI belief
selection or physical popup interaction.

## Native results

| Run | Assertions / replays | Ordinary turns | Scope |
| --- | --- | --- | --- |
| `20260927T172330Z` | 21 / 3 | 3 total | No-religion rejection; default and Tibetan grants; no-grant belief control; count, owner, religion, four/five spreads, faith and next-price accounting; repeated-request rejection; actual owner turn |
| `20260927T173606Z` | 15 / 5 | 0 | Fresh-process exact checkpoint loads; repeat rejection for all three variants; human/control religion-one-shot reentry after enhancement; exact resulting replays |

Both batches completed with normal exit 0, restored settings/UI, unchanged manual
saves, and no reported Lua, synchronization, startup or new crash diagnostic.
Every run/reload save has verified closed writer, stable source/copy bytes and
matching SHA-256. Raw reports/checkpoints are under `build/macos/playtests/<run>/`;
the register pins both reports and requires every stage to pass independently.

The Tibetan AI naturally enhanced its religion and consumed the free Dalai Lama
during its owner turn. The saved result correctly contains no surviving Prophet;
the creation observer verifies exactly one original grant and no repeated grant.
For the human/control follow-up, supplied legal `Game.EnhanceReligion` calls
re-enter native `DoReligionOneShots` after loading. They verify the persisted
one-shot flag without claiming an earned-prophet enhancement mission.

## Retained failed oracle

`20260927T165715Z` failed all three stages because the harness expected rejection
without POLICY_REFORMATION. The stronger AUI predicate is inside a block comment
in `_Defines.h` and is not compiled. The active non-AUI command requires a founded
religion and rejects an already-reformed religion. The corrected negative test
therefore sends the request before founding. Positive tests still provide the
policy. No native eligibility or synchronization check was weakened.

`build/macos/data-recovery-20260927/enabled-religion-defines.json` records actual
preprocessor output. A text match on a commented `#define` is not evidence that a
branch is active. This was a harness expectation error, not a confirmed gameplay
failure; the failed native run remains failed.

## Recovery and preservation

Before these tests, the user authorized recovery of the unintentionally deleted
Civ V Application Support data. All 672 prior single-player save files, including
the original quicksave, were recovered from verified local copies to their
original paths. The 95 newer save files and three current settings files were
preserved byte-for-byte; old settings were retained separately. No multiplayer
testing occurred.

After both batches, `build/macos/city-god-preservation-20260927.json` independently
verifies those 770 files, 32 original stock UI files, original host/GameCore and
canonical/Aspyr backups. Civ V is closed, stock is active and installed Lekmod is
removed. Recovery sources and detailed hashes remain in
`build/macos/data-recovery-20260927/report.json`.
