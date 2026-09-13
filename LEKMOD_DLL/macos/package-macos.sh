#!/usr/bin/env bash
set -euo pipefail
port_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$port_dir/../.." && pwd)"
compat="$(python3 "$port_dir/bootstrap-compat.py" "$port_dir/compat.lock.json")"
version="$(tr -d '\r\n' < "$repo_dir/LEKMOD/VERSION")"
output="${1:-$repo_dir/build/macos/Lekmod-native.zip}"
"$port_dir/build-macos.sh" --incremental
stage="$(mktemp -d "${TMPDIR:-/tmp}/lekmod-release.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/LEKMOD"
rsync -a --exclude 'CvGameCore_Expansion2.dll' --exclude '*.pdb' \
  --exclude 'zlib1.dll' --exclude 'ui_check.bat' "$repo_dir/LEKMOD/" "$stage/LEKMOD/"
python3 "$port_dir/configure-ui.py" --lekmod-dir "$stage/LEKMOD" --mode standard
python3 "$compat/tools/package.py" --product lekmod --version "$version" \
  --source-repo "$repo_dir" --binary "$repo_dir/build/macos/libCvGameCoreDLL_Expansion2_DLL.dylib" \
  --payload "LEKMOD=$stage/LEKMOD" --license "$repo_dir/LICENSE" --output "$output"
