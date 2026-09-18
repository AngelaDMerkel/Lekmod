# Religion-diversity building yields

Current Mac, standard UI, test package/core recorded in the
[Ottoman report](macos-ottoman-validation.md). The source save was the corrected
Ottoman fixture `20260918T233755Z`: three founded religions, human capital
population 20 with one world religion, and a Roman three-religion control.

`20260918T234916Z` supplied one Candi, then removed it and supplied one Gurdwara.
Pressure transfers replaced four atheists with minority followers while keeping
the majority religion and its twelve followers unchanged. No turn, yield,
movement, faith balance or synchronization flag was assigned. The active data
contains three per-religion rows: Candi faith +2; Gurdwara faith/science +2 each.

Observed native values:

| State | Candi total faith | Religion-derived faith | Religion-derived science |
| --- | --- | --- | --- |
| Candi, one world religion | 4 | 2 | 0 |
| Candi, minority added | 6 | 4 | 0 |
| Candi, minority removed | 4 | 2 | 0 |
| Gurdwara, one world religion | — | 2 | 2 |
| Gurdwara, minority added | — | 4 | 4 |

Gurdwara total faith also rose 2→4. The Roman control's yields and building
counts stayed unchanged. Human banked faith stayed at 15: these are rate/cache
observations, not faith or research earned over a turn.

Save SHA-256: `d7e8341151ee174b745f16617b422cbb23e5cfc7c070ff0fc4a4087c36be618e`.
`20260918T235038Z` exactly reloaded the two-religion Gurdwara state, including
followers, majority, building counts, native faith/science rates, banked faith,
Roman control and turn. Reload-save SHA-256:
`5287af73f89d412aa8953b60bda7ca8c908760523607b38a6f3b3aef45a81bb9`.
Both runs exited normally (0), restored settings/hooks and preserved manual
saves, with no Lua errors, synchronization failures or new diagnostics.

This verifies native building-yield behavior after the diversity cache fix.
Buildings and pressure are labeled fixture inputs. It does not establish
Indonesian Candi construction, Gurdwara belief acquisition/purchase, mouse
interaction, natural spread, modifiers to total science or ordinary settlement.
