# Unit-handler regressions found during single-player validation

The earlier performance experiments excluded minors from both New Zealand unit
handlers, and minors/barbarians from the hover-unit embark fix. The rendering
stall was subsequently traced to RNG width, so these gameplay exclusions were
reviewed independently.

The Defender handler also passed a player object to `IsPlayerCityRadius`, a team
ID to `IsDoF`, and compared a player object against an integer when skipping
self. Both Lua bindings require a player ID. A Defender in a friend's city
radius could therefore retain the wrong promotion. The corrected handler uses
player IDs, restores city-state Defenders' own-city behavior, and reverts the
active promotion when the unit leaves that radius. City-states do not enter the
major-only declaration-of-friendship path. Barbarians remain excluded from this
unique-unit handler as in the pre-experiment code.

The embark correction again applies to all living players' hover units, including
minor and barbarian owners. Ordinary units retain their embark promotion. The
Māori Battalion's minor guard is retained: `FriendshipWithMajor` is a major-player
API and is not a valid city-state-to-city-state influence operation.

`test-unit-handlers.py` runs the actual two product Lua files in Lua 5.1.4 with
minimal player/unit/plot objects. Fifteen cases cover own/friendly/unfriendly
city radii, player IDs differing from team IDs, self exclusion, leaving radius,
minor ownership, major/minor/barbarian hover units, ordinary units, dead players,
and the Battalion's influence boundary. Before the correction, seven cases
failed; afterward all fifteen passed. Outputs are preserved locally at
`build/macos/unit-handlers-before.txt` and `unit-handlers-after.txt`.

The interpreter source is the official [Lua 5.1.4 release](https://www.lua.org/ftp/),
verified by its published SHA-256 through `bootstrap-test-lua.py`. Tests do not
launch Civ V or change installed files. These are isolated behavior regressions,
not a claim that every gifted/captured unique-unit situation has been exercised
in the native game. Native verification of the final packaged payload remains
part of the release validation work.

## New Zealand science reward with no selected technology

A separate regression used the current research-overflow **amount** as the
technology ID passed to `ChangeResearchProgress` when no technology was selected.
The intended 12 science was not added to overflow and could target an unrelated
or invalid technology. An actual-Lua test with overflow 80 reproduced the loss;
the selected-research branch passed its existing behavior check.

The correction adds the small `Player:ChangeOverflowResearch` Lua binding to the
existing engine operation and calls it from that branch. The engine retains its
hundredths-based storage and adds the award without losing a fractional remainder.
Both reward cases now pass, bringing the Lua suite to 17 cases. A full native
GameCore rebuild and ABI validation passed. Native runtime verification of the
new binding and a matched binary/payload package are required before release.

## Unit:SetXY boolean flags

Native candidate run `20260913T232746Z` successfully reloaded the old Modern
fixture and passed the new science-overflow check. A same-position call to
`unit:SetXY(x, y, false, true, false, false)` then failed with `number expected,
got boolean`. This is a product binding defect: all four documented boolean
flags were read using `luaL_optint`.

The binding now accepts Lua booleans while retaining the historical numeric
0/1 convention and default/nil values. The isolated regression compiles the
actual binding and helper against Lua 5.1.4 with a recording unit. It reproduces
the old rejection and passes 34 default/boolean/numeric cases plus invalid-type
rejection after correction. Local outputs: `build/macos/setxy-binding-before.txt`
and `setxy-binding-after.txt`. The native failing report remains a failure;
verification of the corrected installed artifact follows separately.

## Team:SetHasTech argument routing

The technology setter read `bFirst` from the player-ID argument and `bAnnounce`
from the first-discovery argument, ignoring the final flag. The actual binding
was compiled against Lua 5.1.4 with a recording team; it failed the mixed-flag
case before correction. Reading the two flags from arguments 5 and 6 passes
all 16 combinations of player ID, new value, first-discovery and announcement.
Local evidence: `build/macos/team-tech-before.txt`, `team-tech-after.txt` and
`team-tech-build.log`. The incremental rebuild and ABI validation passed.
