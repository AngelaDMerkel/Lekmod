# Great Admiral repair validation

`20260919T035252Z` loaded the recorded Industrial Archipelago fixture. The
Admiral, ships, Worker and land-control unit were supplied at natural coastal
plots. Damage 50 and the Worker's embarked flag were explicit inputs; this
does not establish combat-earned damage or normal embarkation. No ordinary
turn advanced.

The native query accepted the Admiral and rejected a Trireme for Repair Fleet.
The actual Repair Fleet action healed an owned ship on the same plot, an owned
adjacent ship and the adjacent embarked Worker from damage 50 to 0. A healthy
owned ship stayed at 0. An adjacent foreign ship, adjacent unembarked land unit
and owned ship at distance two all stayed at damage 50. The Admiral was
consumed, with delayed death accepted only where the engine had not yet removed
the object; it could not repair again.

Save SHA-256: `e86cbad59af049d055bbdcc9b520e0783532d6a7e791c684b9a05a1d0bae8980`.
`20260919T035455Z` exactly reloaded the surviving units' types, positions, health,
movement and embark state for both owners and the turn. The consumed Admiral
remained absent from the live-unit snapshot. Reload-save SHA-256:
`f43aa077eac03adeeeb008a5d9563262109333f92fc1ea2c3efa98324e361b77`.
Both runs exited normally (0), restored settings/hooks and preserved manual
saves, with no Lua errors, synchronization failures or new diagnostics.

No product change was needed. These are scripted action/native outcome checks,
not mouse interaction, natural healing or every Admiral ability. The tested
standard package was `Lekmod-moors-founding-20260919.zip`, archive SHA-256
`13304c6e11215040b644e05ebbdb6347e294afe2bd782a0fa2088d8ac2e0493d`,
with signed core `80a9ec3f54b96485606228c067f3656e727c2bf6b16c2c977cbf6c19bb85b8c1`.
