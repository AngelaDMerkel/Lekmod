#!/usr/bin/env python3
"""Offline regression for scenario supervision and snapshot serialization."""
from pathlib import Path
import subprocess

port=Path(__file__).resolve().parent
lua=port.parents[1]/"build/macos/test-deps/lua-5.1.4/src/lua"
if not lua.is_file():
    raise SystemExit("Run bootstrap-test-lua.py before the offline scenario tests")
raise SystemExit(subprocess.run([str(lua),str(port/"test-scenario-core.lua"),str(port/"playtest-scenario-core.lua")]).returncode)
