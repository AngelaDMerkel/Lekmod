-- Isolated actual-handler coverage; not native gameplay or immediate founding.
function include()end
GameInfoTypes={CIVILIZATION_MOORS=4,BUILDING_MOORS_TRAIT2=9,ERA_MEDIEVAL=2,ERA_RENAISSANCE=3}
LekmodUtilities={is_civilization_active=function()return true end}
local eraHandler,turnHandler
GameEvents={TeamSetEra={Add=function(f)eraHandler=f end},PlayerDoTurn={Add=function(f)turnHandler=f end}}
local function city()return {count=0,SetNumRealBuilding=function(self,id,n)assert(id==9);self.count=n end}end
local function player(civ,team,alive,era)
 local p={civ=civ,team=team,alive=alive,era=era,cities={city(),city()}}
 function p:IsAlive()return self.alive end;function p:GetCivilizationType()return self.civ end;function p:GetTeam()return self.team end;function p:GetCurrentEra()return self.era end
 function p:Cities()local i=0;return function()i=i+1;return self.cities[i]end end
 return p
end
Players={[0]=player(4,7,true,2),[1]=player(4,7,true,2),[2]=player(5,7,true,2),[3]=player(4,9,true,3),[4]=player(4,7,false,2)}
assert(loadfile(assert(arg[1])))()
local passed=0
local function check(name,fn)fn();passed=passed+1;print("PASS "..name)end
local function counts(id,n)for _,c in ipairs(Players[id].cities)do assert(c.count==n,"owner "..id.." expected "..n.." got "..c.count)end end
check("medieval-team-human-and-AI",function()eraHandler(7,2);counts(0,2);counts(1,2)end)
check("other-civilization-excluded",function()counts(2,0)end)
check("other-team-excluded",function()counts(3,0)end)
check("dead-owner-excluded",function()counts(4,0)end)
check("renaissance-reduces-existing-bonus",function()eraHandler(7,3);counts(0,1);counts(1,1)end)
check("industrial-clears-bonus",function()eraHandler(7,4);counts(0,0);counts(1,0)end)
check("owner-turn-restores-current-era",function()turnHandler(3);counts(3,1)end)
check("new-owned-city-covered-on-owner-turn",function()Players[3].cities[3]=city();turnHandler(3);counts(3,1)end)
check("repeated-turn-does-not-stack",function()turnHandler(3);counts(3,1)end)
check("all-other-eras-clear",function()for _,era in ipairs({0,1,4,5,6,7})do Players[3].era=era;turnHandler(3);counts(3,0)end end)
print(passed.." Moors era-handler cases passed")
