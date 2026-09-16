#!/usr/bin/env python3
"""Run product Georgia event handlers across creation, owner and age boundaries."""
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[2]
lua=root/'build/macos/test-deps/lua-5.1.4/src/lua'
script=r'''
include=function() end
GameInfoTypes={CIVILIZATION_GEORGIA=1,UNIT_GEORGIA_KHEVSUR=11,PROMOTION_GEORGIA_KHEVSUR_GA=33}
LekmodUtilities={is_civilization_active=function() return true end}
local events={}
GameEvents=setmetatable({}, {__index=function(_,name)
    events[name]=events[name] or {}
    return {Add=function(fn) table.insert(events[name],fn) end}
end})
local function emit(name,...)
    for _,fn in ipairs(events[name] or {}) do fn(...) end
end
local function unit(kind)
    local u={kind=kind,prom=false}
    function u:GetUnitType() return self.kind end
    function u:IsDead() return false end
    function u:IsHasPromotion(id) assert(id==33);return self.prom end
    function u:SetHasPromotion(id,value) assert(id==33);self.prom=value end
    return u
end
local function player(civ,golden,alive)
    local p={civ=civ,golden=golden,alive=alive~=false,units={}}
    function p:GetCivilizationType() return self.civ end
    function p:IsAlive() return self.alive end
    function p:IsGoldenAge() return self.golden end
    function p:Units() local i=0;return function() i=i+1;return self.units[i] end end
    return p
end
Players={}
assert(loadfile(arg[1]))()
local failed,count=0,0
local function check(name,value)
    count=count+1;print((value and "PASS " or "FAIL ")..name)
    if not value then failed=failed+1 end
end
local function setup(civ,golden,alive)
    Players={[0]=player(civ,golden,alive),[1]=player(1,true)}
    local k,w=unit(11),unit(12);Players[0].units={k,w};return k,w
end
local k,w=setup(1,false);emit('PlayerDoTurn',0);check('before-golden-age',not k.prom and not w.prom)
k,w=setup(1,true);emit('GreatPersonExpended',0,13);check('existing-unit-on-artist-event',k.prom and not w.prom)
k,w=setup(1,true);emit('UnitCreated',0,1007);check('new-Khevsur-during-golden-age',k.prom and not w.prom)
k,w=setup(1,false);emit('UnitCreated',0,1007);check('new-unit-outside-golden-age',not k.prom and not w.prom)
k,w=setup(2,true);emit('UnitCreated',0,1007);emit('PlayerDoTurn',0);check('other-civilization',not k.prom)
k,w=setup(1,true,false);emit('UnitCreated',0,1007);emit('PlayerDoTurn',0);check('dead-owner',not k.prom)
k,w=setup(1,false);k.prom=true;emit('PlayerDoTurn',0);check('ordinary-turn-expiration',not k.prom)
k,w=setup(1,false);local other=unit(11);Players[1].units={other};emit('UnitCreated',1,1007);check('duplicate-civ-correct-owner',not k.prom and other.prom)
print(count..' cases, '..failed..' failures');os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-georgia-events-') as directory:
    p=Path(directory)/'test.lua';p.write_text(script)
    raise SystemExit(subprocess.run([str(lua),str(p),str(root/'LEKMOD/Lua/Civilizations/Lekmod_georgia.lua')]).returncode)
