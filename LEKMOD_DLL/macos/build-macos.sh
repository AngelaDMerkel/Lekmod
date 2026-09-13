#!/usr/bin/env bash
set -euo pipefail
port_dir="$(cd "$(dirname "$0")" && pwd)"
compat="$(python3 "$port_dir/bootstrap-compat.py" "$port_dir/compat.lock.json")"
exec python3 "$compat/tools/build.py" --config "$port_dir/build.json" "$@"
