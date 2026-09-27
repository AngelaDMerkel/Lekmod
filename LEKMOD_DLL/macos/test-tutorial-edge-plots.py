#!/usr/bin/env python3
"""Execute actual stock checks and the minimal packaged override on map edges."""
from pathlib import Path
import re,subprocess,tempfile
root=Path(__file__).resolve().parents[2]
stock=Path.home()/"Library/Application Support/Steam/steamapps/common/Sid Meier's Civilization V/Civilization V.app/Contents/Assets/Assets/DLC/Expansion/Tutorial/lua/TutorialChecks.lua"
text=stock.read_text();functions=[]
for name in ['BesiegedCityCheck','GetBesiegedCityPlot']:
 m=re.search(r'function '+name+r'\s*\([^)]*\).*?\nend',text,re.S);assert m;functions.append(m.group())
program=r'''
ACTIVE=3;INACTIVE=4;GameDefines={TUTORIAL=-1};Game={SetStaticTutorialActive=function()end}
local player,grid,calls
function GetPlayer()return player end
function dprint()end
Map={GetPlotXY=function(x,y,dx,dy)return grid[dx..":"..dy]end}
local cityPlot={GetX=function()return 0 end,GetY=function()return 0 end}
local city={Plot=function()return cityPlot end}
local owner={GetID=function()return 0 end,Cities=function()local once=false;return function()if not once then once=true;return city end end end}
local function tile(water,enemy)return {IsWater=function()return water end,IsVisibleEnemyUnit=function(self,id)assert(id==0);return enemy end}end
STOCK
local function reset()
 player=owner;grid={};calls={}
 GlobalTutorialInfo={CITY_UNDER_ATTACK={CheckFunction=BesiegedCityCheck,PlotFunction=GetBesiegedCityPlot}}
end
reset();assert(not pcall(BesiegedCityCheck));assert(not pcall(GetBesiegedCityPlot));print("Verified original stock edge failures")
function include(name) calls[#calls+1]=name end
assert(loadfile(arg[1]))()
local count=0
for _,case in ipairs({{name="edge-empty",expected=false},{name="edge-enemy-land",expected=true,water=false,enemy=true},{name="edge-enemy-water",expected=false,water=true,enemy=true},{name="edge-friendly-land",expected=false,water=false,enemy=false}})do
 grid={};if case.enemy~=nil then grid["0:1"]=tile(case.water,case.enemy)end
 local found=case.expected and cityPlot or nil
 assert(GetBesiegedCityPlot()==found and BesiegedCityCheck()==(case.expected and ACTIVE or INACTIVE))
 assert(GlobalTutorialInfo.CITY_UNDER_ATTACK.PlotFunction()==found and GlobalTutorialInfo.CITY_UNDER_ATTACK.CheckFunction()==(case.expected and ACTIVE or INACTIVE))
 count=count+1
end
player=nil;assert(GetBesiegedCityPlot()==nil and BesiegedCityCheck()==INACTIVE);count=count+1
assert(calls[1]=="TutorialChecks"and calls[2]=="Tutorial_MainGame");count=count+1
print(count.." corrected edge/registry/route checks passed")
'''.replace('STOCK','\n'.join(functions))
with tempfile.TemporaryDirectory(prefix='lekmod-tutorial-edge-')as d:
 p=Path(d)/'test.lua';p.write_text(program)
 raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(p),str(root/'LEKMOD/Lua/tmp/ui/Tutorial.lua.ignore')]).returncode)
