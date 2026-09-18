from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
script=r'''
include=function()end
GameInfoTypes={CIVILIZATION_UAE=1,UNIT_QASIMI_RAIDER=55}
GameDefines={MOVE_DENOMINATOR=60}
LekmodUtilities={is_civilization_active=function()return true end}
Game={GetActivePlayer=function()return 99 end}
local handlers={}
GameEvents=setmetatable({}, {__index=function(_,name)return {Add=function(fn)handlers[name]=fn end}end})
local function player(civ,kind)
 local u={moves=300,xp=0}
 function u:GetUnitType()return kind end
 function u:ChangeMoves(n)self.moves=self.moves+n end
 function u:ChangeExperience(n)self.xp=self.xp+n end
 local p={unit=u}
 function p:GetCivilizationType()return civ end
 function p:GetUnitByID(id)if id==8192 then return self.unit end end
 return p
end
assert(loadfile(arg[1]))()
local count,failed=0,0
local function check(name,fn)
 Players={[0]=player(1,55),[1]=player(2,55),[2]=player(1,56)}
 count=count+1;local ok,err=pcall(fn);failed=failed+(ok and 0 or 1)
 print((ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ' '..tostring(err)))
end
check('Raider-plunder-restores-two-moves',function()handlers.UnitPlundered(0,8192,4,5);assert(Players[0].unit.moves==420,'two moves must be 120 internal points');assert(Players[0].unit.xp==15)end)
check('Raider-can-overfill-movement',function()Players[0].unit.moves=480;handlers.UnitPlundered(0,8192,4,5);assert(Players[0].unit.moves==600)end)
check('ordinary-unit-no-reward',function()handlers.UnitPlundered(2,8192,4,5);assert(Players[2].unit.moves==300 and Players[2].unit.xp==0)end)
check('missing-unit-no-reward',function()handlers.UnitPlundered(0,9000,4,5);assert(Players[0].unit.moves==300 and Players[0].unit.xp==0)end)
print(count..' cases, '..failed..' failures');os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-uae-events-') as d:
 p=Path(d)/'test.lua';p.write_text(script)
 raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(p),str(root/'LEKMOD/Lua/Civilizations/Lekmod_uae.lua')]).returncode)
