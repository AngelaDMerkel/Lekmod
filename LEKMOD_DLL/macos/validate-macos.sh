#!/usr/bin/env bash
set -euo pipefail

port_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$port_dir/../.." && pwd)"
binary="$repo_dir/build/macos/libCvGameCoreDLL_Expansion2_DLL.dylib"
app_path=""

while (( $# > 0 )); do
  case "$1" in
    --binary) binary="${2:?--binary requires a path}"; shift 2 ;;
    --app) app_path="${2:?--app requires a path}"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--binary dylib] [--app Civilization V.app]"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

fail() { echo "validation error: $*" >&2; exit 1; }

[[ -f "$binary" ]] || fail "missing dylib: $binary"
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
      __ZNSt*|__ZNKSt*|__ZTISt*|__ZTVSt*|__ZTVNSt*|__ZSt*|__ZTv*|___cxa_*|___gxx_*|___Unwind_*|___stack_*|dyld_stub_binder|_atan*|_ceil*|_floor*|_free|_log*|_malloc|_memcmp|_memcpy|_memmove|_memset*|_pow|_sprintf|_strcase*|_strcmp|_strcpy|_strdup|_strlen|_strncase*|_strncmp|_vsnprintf|_wcscmp|_wcslen|_wmemchr) ;;
      *) fail "unresolved symbol is absent from the Aspyr executable: $symbol" ;;
    esac
  done <<< "$extras"
fi

echo "Validated macOS GameCore: $binary"
