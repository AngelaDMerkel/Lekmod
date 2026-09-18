from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
script=r'''
include=function()end
GameInfoTypes={CIVILIZATION_AKSUM=1,IMPROVEMENT_AKSUM=9,DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2}
DomainTypes={DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2}
LekmodUtilities={is_civilization_active=function()return true end}
Game={GetActivePlayer=function()return 99 end}
local handlers={}
GameEvents=setmetatable({}, {__index=function(_,name)return {Add=function(fn)handlers[name]=fn end}end})
Map={GetPlot=function()return {GetX=function()return 4 end,GetY=function()return 5 end}end}
local function player(domain,near)
 local u={domain=domain,near=near}
 function u:IsNearImprovementType(kind,radius,same)assert(kind==9 and radius==1 and same==false);return self.near end
 function u:GetDomainType()return self.domain end
 local p={faith=0,unit=u}
 function p:GetUnitByID(id)if id==8192 then return u end end
 function p:ChangeFaith(n)self.faith=self.faith+n end
 return p
end
assert(loadfile(arg[1]))()
local count,failed=0,0
local function check(name,domain,near,expected)
 Players={[0]=player(domain,near)};count=count+1
 local ok,err=pcall(function()handlers.UnitHealed(0,8192,-10,4,5);assert(Players[0].faith==expected,'faith='..Players[0].faith..' expected='..expected)end)
 failed=failed+(ok and 0 or 1);print((ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ' '..tostring(err)))
end
check('land-heal-near-church',0,true,2)
check('land-heal-away-from-church',0,false,0)
check('sea-heal-not-land-benefit',1,true,0)
check('air-heal-not-land-benefit',2,true,0)
print(count..' cases, '..failed..' failures');os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-aksum-events-') as d:
 p=Path(d)/'test.lua';p.write_text(script)
 raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(p),str(root/'LEKMOD/Lua/Civilizations/Lekmod_aksum.lua')]).returncode)
