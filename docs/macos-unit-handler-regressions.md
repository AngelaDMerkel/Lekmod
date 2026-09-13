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
