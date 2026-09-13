#!/usr/bin/env bash
set -euo pipefail

port_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$port_dir/../.." && pwd)"
default_app="$HOME/Library/Application Support/Steam/steamapps/common/Sid Meier's Civilization V/Civilization V.app"
app_path="$default_app"
ui_mode="auto"
uninstall=0
verify_payload=0
dylib_name="libCvGameCoreDLL_Expansion2_DLL.dylib"

usage() {
  echo "Usage: $0 [--app /path/to/Civilization V.app] [--standard|--eui] [--uninstall|--verify-payload]"
}

while (( $# > 0 )); do
  case "$1" in
    --app) app_path="${2:?--app requires a path}"; shift 2 ;;
    --standard) ui_mode="standard"; shift ;;
    --eui) ui_mode="eui"; shift ;;
    --uninstall) uninstall=1; shift ;;
    --verify-payload) verify_payload=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

layout="repository"
source_mod="$repo_dir/LEKMOD"
built_dylib="$repo_dir/build/macos/$dylib_name"
build_script="$port_dir/build-macos.sh"
if [[ -d "$port_dir/LEKMOD" && -f "$port_dir/$dylib_name" ]]; then
  layout="package"
  source_mod="$port_dir/LEKMOD"
  built_dylib="$port_dir/$dylib_name"
  build_script=""
fi

if (( ! uninstall )) && \
   { [[ ! -d "$source_mod" ]] || [[ ! -f "$port_dir/configure-ui.py" ]] || [[ ! -x "$port_dir/validate-macos.sh" ]]; }; then
  echo "Incomplete Lekmod macOS $layout payload in $port_dir" >&2
  exit 1
fi
if (( ! uninstall )) && ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is required to configure Lekmod's macOS UI." >&2
  exit 1
fi

prepare_binary() {
  if [[ "$layout" == "repository" ]] && { [[ ! -f "$built_dylib" ]] || \
     find "$repo_dir/LEKMOD_DLL" -type f \
       \( -name '*.cpp' -o -name '*.h' -o -name '*.hpp' -o -name '*.inl' -o -name '*.sh' \) \
       -newer "$built_dylib" -print -quit | grep -q .; }; then
    "$build_script"
  fi
  [[ -f "$built_dylib" ]] || { echo "Missing macOS GameCore: $built_dylib" >&2; exit 1; }
}

copy_payload() {
  local destination="$1"
  mkdir -p "$destination"
  rsync -a \
    --exclude 'CvGameCore_Expansion2.dll' \
    --exclude 'CvGameCore_Expansion2.pdb' \
    --exclude 'zlib1.dll' \
    --exclude 'ui_check.bat' \
    "$source_mod/" "$destination/"
}

if (( verify_payload )); then
  prepare_binary
  "$port_dir/validate-macos.sh" --binary "$built_dylib"
  verify_dir="$(mktemp -d "${TMPDIR:-/tmp}/lekmod-payload.XXXXXX")"
  trap 'rm -rf "$verify_dir"' EXIT
  copy_payload "$verify_dir/LEKMOD"
  python3 "$port_dir/configure-ui.py" --lekmod-dir "$verify_dir/LEKMOD" --mode standard
  for required in VERSION MPModsPack.Civ5Pkg Lua/UI/CityView.lua Lua/UI/CityView.xml \
      Lua/UI/ProductionPopup.lua Lua/UI/ProductionPopup.xml Lua/UI/LekmodUiConfigured.lua; do
    [[ -f "$verify_dir/LEKMOD/$required" ]] || {
      echo "Payload verification failed: missing $required" >&2
      exit 1
    }
  done
  echo "Verified self-contained Lekmod macOS $layout payload: $port_dir"
  exit 0
fi

app_path="${app_path%/}"
contents="$app_path/Contents"
macos_dir="$contents/MacOS"
assets_dir="$contents/Assets/Assets"
target_dylib="$macos_dir/$dylib_name"
backup_dylib="$macos_dir/$dylib_name.lekmod-original"
dlc_dir="$assets_dir/DLC"
target_mod="$dlc_dir/LEKMOD"

if [[ ! -d "$app_path" || ! -f "$contents/Info.plist" || ! -f "$target_dylib" ]]; then
  echo "Not a supported Civilization V app bundle: $app_path" >&2
  exit 1
fi

if pgrep -x "Civilization V" >/dev/null 2>&1; then
  echo "Quit Civilization V before installing or uninstalling Lekmod." >&2
  exit 1
fi

if (( uninstall )); then
  if [[ -f "$backup_dylib" ]]; then
    cp -p "$backup_dylib" "$target_dylib"
    rm -f "$backup_dylib"
  fi
  if [[ -d "$target_mod" ]]; then
    rm -rf "$target_mod"
  fi
  echo "Lekmod removed; the original Aspyr GameCore library was restored."
  exit 0
fi

prepare_binary
"$port_dir/validate-macos.sh" --binary "$built_dylib" --app "$app_path"

if [[ ! -f "$backup_dylib" ]]; then
  cp -p "$target_dylib" "$backup_dylib"
fi

stage_dir="$(mktemp -d "${TMPDIR:-/tmp}/lekmod-macos.XXXXXX")"
trap 'rm -rf "$stage_dir"' EXIT
mkdir -p "$stage_dir/LEKMOD"
copy_payload "$stage_dir/LEKMOD"

eui_dir=""
if [[ -d "$dlc_dir/UI_bc1" ]]; then
  eui_dir="$dlc_dir/UI_bc1"
elif [[ -d "$dlc_dir/UI_bc1_xits" ]]; then
  eui_dir="$dlc_dir/UI_bc1_xits"
fi

configure_args=(--lekmod-dir "$stage_dir/LEKMOD" --mode "$ui_mode")
if [[ -n "$eui_dir" ]]; then
  configure_args+=(--eui-dir "$eui_dir")
fi
python3 "$port_dir/configure-ui.py" "${configure_args[@]}"

resolved_ui_mode="$ui_mode"
if [[ "$resolved_ui_mode" == "auto" ]]; then
  resolved_ui_mode="standard"
  [[ -n "$eui_dir" ]] && resolved_ui_mode="eui"
fi

if [[ -d "$target_mod" ]]; then
  rm -rf "$target_mod"
fi
ditto "$stage_dir/LEKMOD" "$target_mod"
cp -p "$built_dylib" "$target_dylib"
codesign --force --sign - "$target_dylib" >/dev/null
"$port_dir/validate-macos.sh" --binary "$target_dylib" --app "$app_path" --installed

echo "Installed Lekmod $(cat "$target_mod/VERSION") for macOS ($resolved_ui_mode UI, $layout payload)."
echo "Backup: $backup_dylib"
echo "Run '$0 --uninstall' to restore the original GameCore library."
