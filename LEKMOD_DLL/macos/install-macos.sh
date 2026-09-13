#!/usr/bin/env bash
set -euo pipefail
cat >&2 <<'MESSAGE'
Wir Schaffen DLC now owns all native GameCore installation state.
Build an artifact with LEKMOD_DLL/macos/package-macos.sh, then use:
  wir-schaffen-dlc --gamecore lekmod --gamecore-package /path/to/release.zip --gamecore-sha256 SHA256
  wir-schaffen-dlc --gamecore status
  wir-schaffen-dlc --gamecore stock
The independent Lekmod installer is retired so a custom GameCore can never
be backed up as stock. No application files were changed by this script.
MESSAGE
exit 2
