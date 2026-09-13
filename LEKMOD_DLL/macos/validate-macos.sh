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
file "$binary" | grep -q 'Mach-O 64-bit.*x86_64' || fail "dylib is not x86_64 Mach-O"
[[ "$(nm -gU "$binary" | awk '{print $3}')" == "_DllGetGameContext" ]] || \
  fail "DllGetGameContext is not the sole exported symbol"
otool -D "$binary" | grep -qx '/libCvGameCoreDLL_Expansion2_DLL.dylib' || \
  fail "incorrect dylib install name"
otool -l "$binary" | grep -A3 'LC_VERSION_MIN_MACOSX' | grep -q 'version 10.11.6' || \
  fail "incorrect deployment target"

if [[ -n "$app_path" ]]; then
  exe="$app_path/Contents/MacOS/Civilization V"
  stock="$app_path/Contents/MacOS/libCvGameCoreDLL_Expansion2_DLL.dylib"
  if [[ -f "$stock.lekmod-original" ]]; then
    stock="$stock.lekmod-original"
  fi
  [[ -f "$exe" && -f "$stock" ]] || fail "invalid Civilization V app bundle"

  extras="$(comm -13 <(nm -u "$stock" | sort -u) <(nm -u "$binary" | sort -u))"
  exe_exports="$(mktemp "${TMPDIR:-/tmp}/civ5-exports.XXXXXX")"
  trap 'rm -f "$exe_exports"' EXIT
  nm -gU "$exe" | awk '{print $3}' | sort -u > "$exe_exports"
  while IFS= read -r symbol; do
    [[ -z "$symbol" ]] && continue
    if grep -Fqx "$symbol" "$exe_exports"; then
      continue
    fi
    case "$symbol" in
      __ZNSt*|__ZNKSt*|__ZTISt*|__ZTVSt*|__ZTVNSt*|__ZSt*|__ZTv*|___cxa_*|___gxx_*|___Unwind_*|___stack_*|dyld_stub_binder|_atan*|_ceil*|_fflush|_flockfile|_floor*|_fopen|_fprintf|_free|_funlockfile|_getenv|_log*|_malloc|_memcmp|_memcpy|_memmove|_memset*|_pow|_setvbuf|_snprintf|_sprintf|_strcase*|_strcmp|_strcpy|_strdup|_strlen|_strncase*|_strncmp|_vsnprintf|_wcscmp|_wcslen|_wmemchr) ;;
      *) fail "unresolved symbol is absent from the Aspyr executable: $symbol" ;;
    esac
  done <<< "$extras"

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
