# Optional options control during single-player reload

The single-player batch `20260920T230531Z` reached a native Lua runtime error while
loading its nuclear checkpoint: `MPGameOptions.lua:1343` attempted to register a
callback on absent `Controls.AICannotHaveWealsWithHumansCheck`. The batch stopped
with `failed-lua-runtime-error`; its process was terminated by cleanup (-9).
Settings/hooks/manual saves were restored/preserved and the managed wrapper
restored stock. The failure remains recorded; no synchronization flag was cleared.

This shared frontend script is loaded during single-player UI initialization.
No multiplayer, hotseat or PBEM session was created or tested. The control's
unusual spelling matches both shipped XML layouts. Both layouts contain the ID;
the underlying reason it was absent from this particular live context has not
been isolated. This correction addresses the unsafe nil access and does not
claim to resolve every possible frontend construction issue.

The AI-deals checkbox and its box are now treated as optional when binding,
setting checked/disabled state and showing the option group. If the checkbox is
absent, no value is invented, the corresponding box stays hidden where available,
and neither the game option nor its change notification is sent. When present,
the existing callback, option key, checked value and notification are preserved.
The template and checked-in generated Lua copy are kept consistent.

`test-optional-options-control.py` executes the actual related statements,
setter, callback and registration with present/missing box and checkbox inputs.
All 64 cases pass after the correction; the original source fails 32 missing-
control cases. These use UI/PreGame stand-ins, not a multiplayer lobby. The nine
standard/EUI assembly regressions also pass.

Intermediate package `build/macos/Lekmod-optional-control-20260920.zip` has SHA-256
`f054823b392cd282e7635a475e65b91fe3240b35f29cdfa8e0d3adfe224bd21e`.
It contains the previously verified Defender fix and this new UI guard. The full
single-process retest is being recorded separately; this is not a clean release
or a claim of complete platform support.

## Native retest

`20260920T231930Z` (PID 47872) ran the complete 16-stage plan with this package
through 31 saved checkpoints in one process. Fifteen functional stages (77 planned
checks) and their exact reloads passed, including the nuclear checkpoint reload
that previously raised the missing-control error. No Lua runtime errors, protocol
errors, RNG mismatches or new diagnostics were recorded. The process exited
normally (0), preserving settings/hooks/manual saves; the wrapper restored stock.

The overall result remains `failed-functional-checks`: the last Battalion stage
exposed an unrelated test-observer registration-order assumption. Its before/after
observers were registered too late in dynamic batch execution, and the bounded
test correctly failed without extending its turn allowance. This does not negate
the recorded UI reload regression evidence, and it is not relabeled as a full
batch pass. The observer correction and targeted retest are documented in the
batch guide. The precise cause of the original control omission remains unknown.
