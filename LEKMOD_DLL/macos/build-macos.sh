#!/usr/bin/env bash
set -euo pipefail

port_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$port_dir/../.." && pwd)"
source_dir="$repo_dir/LEKMOD_DLL/CvGameCoreDLL_Expansion2"
build_dir="$repo_dir/build/macos"
object_dir="$build_dir/objects"

if [[ ! -f "$source_dir/CvGameCoreDLL.cpp" ]]; then
  echo "error: expected Lekmod DLL sources at $source_dir" >&2
  exit 1
fi

mkdir -p "$object_dir"

common_flags=(
  -target x86_64-apple-macos10.11.6
  -std=c++11
  -fms-extensions
  -fdeclspec
  -fdelayed-template-parsing
  -fvisibility=hidden
  -O2
  -DNDEBUG
  -DFINAL_RELEASE
  -DFXS_IS_DLL
  -DWIN32
  -D_WIN64
  -D_WINPC
  -D_WINDOWS
  -D_USRDLL
  -DCVGAMECOREDLL_EXPORTS
  -D_CRT_SECURE_NO_WARNINGS
  -DAUI_VC120_FORMALITIES
  -Wno-deprecated-declarations
  -Wno-ignored-attributes
  -Wno-macro-redefined
  -Wno-microsoft-pure-definition
  -Wno-nonportable-include-path
  -Wno-unused-value
  -I"$port_dir/include"
  -I"$source_dir"
  -I"$source_dir/CvWorldBuilderMap/include"
  -I"$source_dir/CvGameCoreDLLUtil/include"
  -I"$source_dir/CvLocalization/include"
  -I"$source_dir/CvGameDatabase/include"
  -I"$source_dir/FirePlace/include"
  -I"$source_dir/FirePlace/include/FireWorks"
  -I"$source_dir/ThirdPartyLibs/Lua51/include"
  -include Windows.h
  -include FireWorks/FMemHooks.h
)

sources=("$port_dir/mac_compat.cpp")
while IFS= read -r -d '' source_file; do
  [[ "$(basename "$source_file")" == "_precompile.cpp" ]] || sources+=("$source_file")
done < <(find "$source_dir" -maxdepth 1 -type f -name '*.cpp' -print0 | sort -z)
while IFS= read -r -d '' source_file; do
  sources+=("$source_file")
done < <(find "$source_dir/Lua" -maxdepth 1 -type f -name '*.cpp' -print0 | sort -z)

objects=()
for source_file in "${sources[@]}"; do
  object_file="$object_dir/$(basename "${source_file%.cpp}").o"
  echo "CXX $(basename "$source_file")"
  clang++ "${common_flags[@]}" -c "$source_file" -o "$object_file"
  objects+=("$object_file")
done

output="$build_dir/libCvGameCoreDLL_Expansion2_DLL.dylib"
clang++ -target x86_64-apple-macos10.11.6 -dynamiclib -undefined dynamic_lookup \
  -install_name /libCvGameCoreDLL_Expansion2_DLL.dylib \
  -compatibility_version 1.0.0 -current_version 1.0.0 \
  -Wl,-exported_symbol,_DllGetGameContext \
  "${objects[@]}" -o "$output"

echo "$output"
