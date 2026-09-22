# Counterspy interception validation

`20260922T204542Z` passed five checks and exact in-process reload on the clean
`f40fd2b2` package (archive `e6904b434b3a3a7bebea4c2a83d1709c3aaf73d55a096237b6ed87f07fefcffc`).
The native run lasted 392.1 seconds and used 16 ordinary turns, 166–182. Normal
exit 0, settings/hooks restoration, manual-save preservation and no Lua/sync
errors or new diagnostics were verified. The managed wrapper restored stock.

This tests an **AI-owned counterspy against a human intruder**. The AI selected
its own defensive assignment and travelled to its capital. The human recruit
used the normal relocation command, travelled, established surveillance and
completed intelligence gathering. The actual defensive resolution killed and
extracted the intruder, made it ineligible for a coup, produced no claimable
science award, and promoted the defending agent from rank 1 to rank 2. Exact
reload retained both owners' complete spy state and the defending cities' state.

Research prerequisites, target-city population/food, science buildings,
Constabulary, National Intelligence Agency and upkeep gold were explicit fixture
inputs. NIA's normal building effects contributed to the defensive rank setup.
No spy rank/progress/death/award field or RNG/turn/wait state was assigned directly.
This is scripted command and native outcome evidence, not mouse interception UI
or a naturally developed espionage campaign.

The earlier `20260922T204312Z` remains failed (87.4 seconds, normal exit/cleanup).
The test attempted to relocate the AI defender after the AI had already sent
that agent to the correct city; the eligibility guard rejected the duplicate
command. The revised fixture observes that real AI assignment instead.

Verified checkpoint SHA-256:
`08dddf7c2620afb4ece319cd56473e9f612f2303987b461d9e703dc2b91b7fa6`.
Reload checkpoint:
`671fd957787fa2db5ac6b2a78b220a21125451996490c1e59625a2836ad70225`.
Evidence lives in `build/macos/playtests/20260922T204542Z/`.
Reproduce with `batch-playtest.py --plan LEKMOD_DLL/macos/batch-plans/counterspy.json`
and the verified release package. The turn cap is 19.

`test-counterspy-outcomes.py` extracts and compiles the actual product decision
block under ASan/UBSan. All 324 cases pass across attacker/defender ranks,
no defender versus a defender, standard/Australian Constabulary alternatives,
NIA and religion pressure. It verifies detected/identified/spotted/killed outcomes
and which agent earns a promotion. These isolated decision cases supplement,
rather than replace, the native mission. No product correction was needed.


## Physical acceptance on the same release artifact

Unmodified foreground control `20260922T205259Z` (PID 59617) started with the
original settings, no injected observer and no temporary UI hooks. Actual CUA
mouse/keyboard actions loaded the verified counterspy checkpoint, dismissed the
Continue screen, displayed the spy-loss notification and opened Espionage Overview.
Makhzum appeared as KILLED IN ACTION without a Move control. The surviving
Al-Khalil was moved through Move → Muscat and appeared as Traveling, 1 Turn.

The native Save Game menu created the previously absent default file
`Saif bin Sultan_0182 AD-1785.Civ5Save`. An attempted custom filename through CUA
text/selection shortcuts had no visible effect; custom-name entry is not claimed.
The new default name was verified unused before saving, and no original save or
quicksave was overwritten. The native Load Game menu reloaded this new save;
Continue and reopening Espionage Overview showed the same dead/traveling states.
Escape → Exit to Windows → Yes exited normally (0), without supervisor signals.

Duration was 452.7 seconds. Settings were unchanged by the game and restored;
all 417 prior manual saves and the original quicksave were preserved. Stock and
both backups were independently rehashed after managed restoration. Original
LoggingEnabled was 0, so this control makes no current Lua-log cleanliness claim.
It compares visible spy state, not a separately injected logical-state fingerprint.

Physical save SHA-256:
`71a5a0a587df3673d3846b4a7c3d46271262d464a8970031c54d3aeae3876e42`.
Screenshots, the copied save, observations and normal-exit report are under
`build/macos/native-startup-controls/20260922T205259Z/`. Restoration evidence:
`build/macos/critical-gaps-stock-verification-20260922.json`.
