#!/usr/bin/env python3
"""Exercise Venice's product Lua against actual TeamTechResearched arguments."""
import argparse
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--source-root', type=Path, default=root)
args = parser.parse_args()
script = r'''
include=function()end
GameInfoTypes={CIVILIZATION_VENEZ=1,TECH_COMPASS=20}
LekmodUtilities={is_civilization_active=function()return true end}
local handlers={}
local ready
Events={SequenceGameInitComplete={Add=function(fn)ready=fn end}}
Teams=setmetatable({}, {__index=function(_,id)return {GetTeamTechs=function()return {HasTech=function()return id==0 end}end}end})
GameEvents={TeamTechResearched={Add=function(fn)handlers[#handlers+1]=fn end,Remove=function(fn)
 for i=#handlers,1,-1 do if handlers[i]==fn then table.remove(handlers,i)end end
end}}
local function player(civ,team,alive)
 local p={routes=0}
 function p:IsAlive()return alive end
 function p:GetTeam()return team end
 function p:GetNumMiscTradeRoutes()return self.routes end
 function p:GetCivilizationType()return civ end
 function p:ChangeNumMiscTradeRoutes(n)self.routes=self.routes+n end
 return p
end
local function setup()
 handlers={};ready=nil;Players={[0]=player(1,0,true),[1]=player(1,1,true),[2]=player(2,0,true),[3]=player(1,0,true),[4]=player(1,0,false)}
 assert(loadfile(arg[1]))()
end
local function emit(team,tech,change)
 local snapshot={};for _,fn in ipairs(handlers)do snapshot[#snapshot+1]=fn end
 for _,fn in ipairs(snapshot)do fn(team,tech,change)end
end
local count,failed=0,0
local function check(name,fn)
 setup();count=count+1;local ok,err=pcall(fn);if not ok then failed=failed+1 end
 print((ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ' '..tostring(err)))
end
check('all-living-Venice-teammates-only',function()
 emit(0,20,1);assert(Players[0].routes==1 and Players[3].routes==1)
 assert(Players[1].routes==0 and Players[2].routes==0 and Players[4].routes==0)
end)
check('other-technology-no-bonus',function()
 emit(0,19,1);for _,p in pairs(Players)do assert(p.routes==0)end
end)
check('separate-Venice-team-keeps-listener',function()
 emit(0,20,1);emit(1,20,1);assert(Players[1].routes==1,'first team removed another Venice player\'s listener')
end)
check('research-order-independent',function()
 emit(1,20,1);emit(0,20,1);assert(Players[0].routes==1 and Players[3].routes==1)
end)
check('technology-removal-reverses-only-its-team',function()
 emit(0,20,1);emit(1,20,1);emit(0,20,-1)
 assert(Players[0].routes==0 and Players[3].routes==0 and Players[1].routes==1)
end)
check('zero-change-event-no-bonus',function()
 emit(0,20,0);for _,p in pairs(Players)do assert(p.routes==0)end
end)
check('known-Compass-restores-missing-owner-only',function()
 assert(ready,'missing game-init recovery');ready()
 assert(Players[0].routes==1 and Players[3].routes==1)
 assert(Players[1].routes==0 and Players[2].routes==0 and Players[4].routes==0)
end)
check('saved-awards-not-repeated-or-overwritten',function()
 Players[0].routes=1;Players[3].routes=3;assert(ready);ready();ready()
 assert(Players[0].routes==1 and Players[3].routes==3)
end)
print(count..' cases, '..failed..' failures');os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-venice-events-') as directory:
    path=Path(directory)/'test.lua'
    path.write_text(script)
    raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(path),str(args.source_root/'LEKMOD/Lua/Civilizations/Lekmod_venice.lua')]).returncode)
