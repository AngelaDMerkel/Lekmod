#!/bin/bash
set -euo pipefail
compat_dir="$(cd "$(dirname "$0")" && pwd)"
if pgrep -x steam_osx >/dev/null; then
  echo "Steam is already running; leaving that instance untouched."
  exit 0
fi
python3 "$compat_dir/patch-steam.py" install
# This launch intentionally loads our verified local libraries. Do not alter
# Steam's package manifests or disable its update channel. A subsequent Steam
# update may require reviewing and regenerating the compatibility patch.
open -g -a /Applications/Steam.app --args -noverifyfiles
