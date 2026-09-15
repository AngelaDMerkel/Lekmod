#!/usr/bin/env python3
"""Run product civilization callbacks against real engine event signatures."""
import argparse
from pathlib import Path
import subprocess

root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument("--source-root",type=Path,default=root)
parser.add_argument("--lua",type=Path,default=root/"build/macos/test-deps/lua-5.1.4/src/lua")
args=parser.parse_args()
raise SystemExit(subprocess.run([str(args.lua),str(Path(__file__).with_suffix(".lua")),
    str(args.source_root/"LEKMOD/Lua/Civilizations/Lekmod_mughals.lua"),
    str(args.source_root/"LEKMOD/Lua/Civilizations/Lekmod_bolivia.lua")]).returncode)
