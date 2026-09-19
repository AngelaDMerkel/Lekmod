# Moors founding and era-production validation

Current Mac, standard UI. The founding fixture uses normal Medieval/Tiny
Pangaea setup with human/AI Moors and a Roman AI control, no minors, and normal
no-barbarians/no-ruins options.

## Confirmed founding delay

`20260919T033626Z` used the starting Settler's legal Found action. At the first
playable state, before any turn advanced, the new capital had zero trait
markers and 0% Market/Library production modifiers. The advertised Medieval
30% bonus was absent because the handler ran only on era changes/owner turns.
The failed state saved/exited 0 and remains FAIL. Save SHA-256:
`c8efcb297039996320074781e25f0a45d4065a4f410a1d6ef90e72c942097bd1`.
Its initial save SHA-256 is
`a0aa64e144132515a6b8a37e927eb8dbe2e071ff77e47e6084589fa3f45f858c`.

The existing era-based update is now also registered for PlayerCityFounded.
Four new isolated event/owner cases fail without that subscription; all 14
era/founding callback cases pass with it. No marker or production value is
assigned by the native test.

`20260919T034123Z` replayed the same initial map. The new capital had two markers
and +30% Market/Library production modifiers at its first playable state, while
the Great Library modifier stayed 0%. The observer's own founding event logged
0 before the product callback ran; the next UI update, on the same elapsed turn
zero, recorded the corrected state. This establishes same-turn availability,
not an ordering guarantee between independent event subscribers.
Save SHA-256: `d23a7c57adb47fa32e284a61d31370f508f5eb15b6f6dfd60d63890b26b519f0`.

## Era and ownership controls

`20260919T034302Z` loaded that fixture and allowed the other players to found
capitals normally. Both Moorish owners had two markers in the Medieval era;
Rome had none. Supplied Acoustics research caused the real team-era event,
reducing the human marker to one while the other Moorish team stayed at two.

A supplied Settler at a legal site used the normal Found action in the
Renaissance. Its first observed state had one marker, +15% Market/Library
modifiers and 0% for the Great Library. Supplied Scientific Theory then moved
the human to Industrial and cleared all its city markers. The other Moorish
team remained Medieval with two markers. A supplied Roman Renaissance advance
added no Moorish marker. No era, city owner or production modifier was assigned.
Save SHA-256: `8a7f72554aa2988e3054ec1bec924d7c79d3b45ae0c248155a0032c021e66f9c`.
`20260919T034455Z` exactly reloaded the mixed-era state for all three owners,
including city markers and ordinary-building/wonder modifiers. Reload-save
SHA-256: `e72343a1a98f64f8b12d8ff644c863135dab0a2ae5825bc8a8b6d8f1bb22df26`.
`20260919T034729Z` separately reloaded the first-founded Medieval capital state
exactly, preserving its +30% ordinary-building and 0% Great Library modifiers.
Reload-save SHA-256:
`d414a62ce4580195ba0376e179729a696780f1db2c6bf470e0da295089948887`.

All completed successful runs exited normally (0), restored settings/hooks and
preserved manual saves, with no Lua errors, synchronization failures or new
diagnostics. Research and the extra Settler/position were explicit inputs;
this is not earned era progression, building completion or mouse interaction.
Capture/transfer timing, other building classes/modifier combinations and the
other Moorish uniques remain separate coverage.

Intermediate package: `build/macos/Lekmod-moors-founding-20260919.zip`.
Archive SHA-256: `13304c6e11215040b644e05ebbdb6347e294afe2bd782a0fa2088d8ac2e0493d`.
Signed GameCore remains `80a9ec3f54b96485606228c067f3656e727c2bf6b16c2c977cbf6c19bb85b8c1`.
This is a Lua-only change after the prior full build, installed through the
central installer; it is not the final clean release package.
