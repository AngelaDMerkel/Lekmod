#!/usr/bin/env python3
"""Run the actual UAE Lua handlers through isolated event and owner boundaries."""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[2]
raise SystemExit(subprocess.run([str(root/"build/macos/test-deps/lua-5.1.4/src/lua"),
    str(Path(__file__).with_suffix(".lua")),str(root/"LEKMOD/Lua/Civilizations/Lekmod_uae.lua")]).returncode)
