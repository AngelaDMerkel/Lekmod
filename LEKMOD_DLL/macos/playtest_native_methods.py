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


def event_arity_errors(code):
    """Check fixed callback parameters for the verified UnitCreated hook only.

    Native UnitCreated provides owner, id, x, y. Derive the argument count from
    its current source block so a changed hook cannot silently retain this rule.
    This does not infer parameter meanings or cover other native/UI events.
    """
    source=(LUA.parent/'CvUnit.cpp').read_text(errors='replace')
    end=source.index('LuaSupport::CallHook(pkScriptSystem, "UnitCreated"')
    start=source.rfind('CvLuaArgsHandle args',0,end)
    if start<0:raise ValueError('UnitCreated source argument block missing')
    count=len(re.findall(r'args->Push\(',source[start:end]))
    if count!=4:raise ValueError('UnitCreated native signature changed; review the callback contract')
    code=re.sub(r'--\[\[.*?\]\]|--[^\n]*|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', '', code, flags=re.S)
    errors=[]
    for match in re.finditer(r'GameEvents\s*\.\s*UnitCreated\s*\.\s*Add\s*\(\s*function\s*\(([^)]*)\)',code):
        fixed=[p.strip()for p in match.group(1).split(',')if p.strip()and p.strip()!='...']
        if len(fixed)>count:errors.append('UnitCreated supplies 4 arguments (owner,id,x,y), callback declares '+str(len(fixed)))
    return errors
