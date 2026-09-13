#!/usr/bin/env python3
"""Execute actual product unit handlers in Lua 5.1 with minimal engine stand-ins."""
import argparse
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--lua", type=Path, default=ROOT / "build/macos/test-deps/lua-5.1.4/src/lua")
parser.add_argument("--source-root", type=Path, default=ROOT)
args = parser.parse_args()
if not args.lua.is_file():
    parser.error("Build the pinned test interpreter with bootstrap-test-lua.py, or supply --lua")
raise SystemExit(subprocess.run([str(args.lua), str(Path(__file__).with_suffix(".lua")),
    str(args.source_root / "LEKMOD/Lua/Lekmod_units.lua"),
    str(args.source_root / "LEKMOD/Lua/Civilizations/Lekmod_newzealand.lua")]).returncode)
