#!/usr/bin/env bash
set -euo pipefail

port_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$port_dir/../.." && pwd)"
package_dir="$repo_dir/build/macos/package"
dylib_name="libCvGameCoreDLL_Expansion2_DLL.dylib"

"$port_dir/build-macos.sh"
"$port_dir/validate-macos.sh" --binary "$repo_dir/build/macos/$dylib_name"

if [[ -d "$package_dir" ]]; then
  rm -rf "$package_dir"
fi
mkdir -p "$package_dir/LEKMOD"
rsync -a \
  --exclude 'CvGameCore_Expansion2.dll' \
  --exclude 'CvGameCore_Expansion2.pdb' \
  --exclude 'zlib1.dll' \
  --exclude 'ui_check.bat' \
  "$repo_dir/LEKMOD/" "$package_dir/LEKMOD/"
python3 "$port_dir/configure-ui.py" --lekmod-dir "$package_dir/LEKMOD" --mode standard
cp -p "$repo_dir/build/macos/$dylib_name" "$package_dir/$dylib_name"
cp -p "$port_dir/install-macos.sh" "$port_dir/configure-ui.py" \
  "$port_dir/validate-macos.sh" "$port_dir/README.md" "$package_dir/"
"$package_dir/install-macos.sh" --verify-payload

echo "$package_dir"
