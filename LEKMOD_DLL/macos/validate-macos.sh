#!/usr/bin/env bash
set -euo pipefail

port_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$port_dir/../.." && pwd)"
binary="$repo_dir/build/macos/libCvGameCoreDLL_Expansion2_DLL.dylib"
app_path=""
installed=0

while (( $# > 0 )); do
  case "$1" in
    --binary) binary="${2:?--binary requires a path}"; shift 2 ;;
    --app) app_path="${2:?--app requires a path}"; shift 2 ;;
    --installed) installed=1; shift ;;
    -h|--help) echo "Usage: $0 [--binary dylib] [--app Civilization V.app] [--installed]"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

fail() { echo "validation error: $*" >&2; exit 1; }

[[ -f "$binary" ]] || fail "missing dylib: $binary"
if (( installed )) && [[ -z "$app_path" ]]; then
  fail "--installed requires --app"
fi
compat="$(python3 "$port_dir/bootstrap-compat.py" "$port_dir/compat.lock.json")"
validation_args=(--binary "$binary")
[[ -z "$app_path" ]] || validation_args+=(--app "$app_path")
python3 "$compat/tools/validate.py" "${validation_args[@]}"

if [[ -n "$app_path" ]]; then
  if (( installed )); then
    target_mod="$app_path/Contents/Assets/Assets/DLC/LEKMOD"
    ui_dir="$target_mod/Lua/UI"
    for required in VERSION MPModsPack.Civ5Pkg Lua/UI/CityView.lua \
        Lua/UI/CityView.xml Lua/UI/CityView_small.xml \
        Lua/UI/LekmodUiConfigured.lua Lua/UI/MainMenu.lua; do
      [[ -f "$target_mod/$required" ]] || fail "installed payload is missing $required"
    done
    [[ ! -f "$ui_dir/MainMenu.xml" ]] || \
      fail "MainMenu.xml must remain Aspyr-native; the DLC override crashes the frontend"
    for forbidden in CvGameCore_Expansion2.dll CvGameCore_Expansion2.pdb zlib1.dll ui_check.bat; do
      [[ ! -e "$target_mod/$forbidden" ]] || fail "Windows-only file was installed: $forbidden"
    done
    grep -q 'ID="GoldenAgePointsPerTurnLabel"' "$ui_dir/CityView.xml" || \
      fail "CityView.xml lacks Lekmod production controls"
    if [[ -f "$ui_dir/ProductionPopup.lua" ]]; then
      [[ -f "$ui_dir/ProductionPopup.xml" ]] || fail "ProductionPopup.lua has no companion XML"
      grep -q 'ID="GoldenAgePoints"' "$ui_dir/ProductionPopup.xml" || \
        fail "ProductionPopup.xml lacks the Golden Age production control"
    fi
    if command -v xmllint >/dev/null 2>&1; then
      xmllint --noout "$ui_dir/CityView.xml" "$ui_dir/CityView_small.xml" \
        >/dev/null || fail "installed core UI XML is malformed"
    fi
    codesign --verify "$binary" >/dev/null 2>&1 || fail "installed GameCore is not code signed"
  fi
fi

echo "Validated macOS GameCore: $binary"
