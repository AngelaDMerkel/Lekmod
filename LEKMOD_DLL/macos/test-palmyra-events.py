#!/usr/bin/env python3
"""Run Palmyra's actual event handler with founding/capture owner boundaries."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
script=r'''
include=function()end
GameInfoTypes={CIVILIZATION_PALMYRA=1,IMPROVEMENT_BUGANDA_LAKE=45}
LekmodUtilities={is_civilization_active=function()return true end}
local events={}
GameEvents=setmetatable({}, {__index=function(_,key) events[key]=events[key] or {};return {Add=function(fn)table.insert(events[key],fn)end} end})
local function emit(name,...) for _,fn in ipairs(events[name] or {}) do fn(...) end end
local function player(id,civ,alive)
 return {GetID=function()return id end,GetCivilizationType=function()return civ end,IsAlive=function()return alive end}
end
local city={owner=0}
function city:IsCity()return true end
function city:GetOwner()return self.owner end
function city:GetX()return 4 end
function city:GetY()return 5 end
Map={GetPlot=function()return city end}
local neighbors={}
PlotAreaSweepIterator=function()local i=0;return function()i=i+1;return neighbors[i]end end
local function setup(oldCiv,newCiv,oldAlive,owner,initial)
 Players={[0]=player(0,oldCiv,oldAlive),[1]=player(1,newCiv,true)};city.owner=owner;neighbors={}
 for i=1,6 do
  local p={water=i==6,fresh=initial,natural=false}
  function p:IsWater()return self.water end
  function p:IsFreshWater()return self.natural or self.fresh end
  function p:SetFreshWater(v)self.fresh=v end
  neighbors[i]=p
 end
end
assert(loadfile(arg[1]))()
local count,failed=0,0
local function check(name,expected)
 local ok=true;for i=1,5 do ok=ok and neighbors[i]:IsFreshWater()==expected end
 count=count+1;failed=failed+(ok and 0 or 1);print((ok and 'PASS ' or 'FAIL ')..name)
end
setup(1,2,true,0,false);emit('PlayerCityFounded',0,4,5);check('Palmyra-founding',true)
assert(not neighbors[6].fresh,'founding gave freshwater to ordinary water')
setup(2,2,true,0,false);emit('PlayerCityFounded',0,4,5);check('other-civ-founding',false)
setup(2,1,true,1,false);emit('CityCaptureComplete',0,false,4,5,1,5,true);check('capture-by-Palmyra',true)
setup(1,2,true,1,true);emit('CityCaptureComplete',0,false,4,5,1,5,true);check('capture-away-from-living-Palmyra',false)
setup(1,1,true,1,true);emit('CityCaptureComplete',0,false,4,5,1,5,true);check('Palmyra-to-Palmyra-keeps-benefit',true)
setup(1,2,false,1,true);emit('CityCaptureComplete',0,true,4,5,1,5,true);check('eliminated-Palmyra-loses-benefit',false)
setup(1,1,false,1,true);emit('CityCaptureComplete',0,true,4,5,1,5,true);check('eliminated-to-living-Palmyra',true)
setup(2,2,true,1,false);emit('CityCaptureComplete',0,false,4,5,1,5,true);check('unrelated-capture',false)
print(count..' cases, '..failed..' failures');os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-palmyra-events-') as d:
 p=Path(d)/'test.lua';p.write_text(script)
 raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(p),str(root/'LEKMOD/Lua/Civilizations/Lekmod_palmyra.lua')]).returncode)
