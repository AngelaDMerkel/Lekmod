"""Binding-name checks for scenarios declaring the GameCore method surface."""
from pathlib import Path
import re

PORT=Path(__file__).resolve().parent
LUA=PORT.parent/'CvGameCoreDLL_Expansion2/Lua'

def registered_methods():
    methods=set()
    for source in LUA.glob('CvLua*.cpp'):
        methods.update(re.findall(r'\bMethod\s*\(\s*(\w+)\s*\)',source.read_text(errors='replace')))
    return methods

def missing_methods(code,registered):
    # Strip comments and quoted literals before looking for call syntax.
    tokens=re.sub(r'--\[\[.*?\]\]|--[^\n]*|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', '', code, flags=re.S)
    return sorted(set(re.findall(r':\s*(\w+)\s*\(',tokens))-registered)
