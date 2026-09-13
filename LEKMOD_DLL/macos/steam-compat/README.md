# Local Steam socket-lookup compatibility workaround

This is separate from the Lekmod port. Steam's startup invokes
`/usr/sbin/lsof -F up -i TCP@<endpoint>` synchronously. On this Mac, regular-file
metadata inspection of Docker's VM, with tens of thousands of open network
file handles, stalls that call and blocks Steam's UI.

The helper implements only the loopback TCP ownership query, emitting actual
PID, UID and descriptor values from macOS socket metadata. It examines sockets
in all accessible processes, including Docker. No ownership is fabricated and
no connection is automatically authorized. IPv4 and IPv6 loopback are supported;
other addresses and malformed requests are rejected.

`patch-steam.py install` changes the command literal in the x86_64 and arm64
slices of `steamui.dylib` and `steamclient.dylib`, replacing their Valve code
signatures with ad-hoc signatures. Original signed files, hashes and a manifest
are saved in `~/.steam-socket-compat`. The helper is `~/.steam-ls`. Neither
Apple's lsof nor Docker is changed. The short helper path is necessary to fit
the existing command literal without changing Mach-O offsets.

Launch with `Launch-Steam.command`. It uses Steam's `-noverifyfiles` option
for that launch because normal self-repair overwrites custom libraries. The
Steam update channel remains enabled; updates can remove the workaround. The
installer refuses to overwrite an unrecognized version or an unrelated helper.
The workaround's durability across future Steam releases is not verified.

To undo, close Steam, then run:

```sh
python3 patch-steam.py restore
```

This restores the exact original signed libraries if the current hashes match
the patch manifest. It deliberately preserves backups and the unused helper.
Do not confuse a successful Steam launch with a verified Lekmod gameplay fix.
