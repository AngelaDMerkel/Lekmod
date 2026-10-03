-- Execute the real UAE callback file; these are isolated callback checks,
-- not native production, path/tooltip, pillage or physical-input outcomes.
include=function()end
GameInfoTypes={CIVILIZATION_UAE=1,UNIT_QASIMI_RAIDER=55}
GameDefines={MOVE_DENOMINATOR=60}
LekmodUtilities={is_civilization_active=function()return true end}
Game={GetActivePlayer=function()return 99 end}
GameInfo={Buildings={[100]={BuildingClass="WORLD"},[101]={BuildingClass="NORMAL"},[102]={BuildingClass="NATIONAL"},[103]={BuildingClass="TEAM"}},BuildingClasses={WORLD={MaxGlobalInstances=1},NORMAL={MaxGlobalInstances=-1},NATIONAL={MaxGlobalInstances=-1,MaxPlayerInstances=1},TEAM={MaxGlobalInstances=-1,MaxTeamInstances=1}}}
local handlers={}
GameEvents=setmetatable({}, {__index=function(_,name)return {Add=function(fn)handlers[name]=fn end}end})
local function unit(id,kind,combat,route)
 local u={id=id,kind=kind,moves=300,xp=0,combat=combat,plot={route=route}}
 function u:GetUnitType()return self.kind end
 function u:ChangeMoves(n)self.moves=self.moves+n end
 function u:ChangeExperience(n)self.xp=self.xp+n end
 function u:GetPlot()return self.plot end
 function u:IsCombatUnit()return self.combat end
 return u
end
local function player(civ,kind)
 local p={civ=civ,alive=true,gold=0,unit=unit(8192,kind,true,true),city={king=0}}
 p.units={p.unit}
 function p.city:ChangeWeLoveTheKingDayCounter(n)self.king=self.king+n end
 function p:GetCivilizationType()return self.civ end
 function p:IsAlive()return self.alive end
 function p:IsHuman()return false end
 function p:GetCityByID(id)assert(id==42);return self.city end
 function p:ChangeGold(n)self.gold=self.gold+n end
 function p:GetUnitByID(id)for _,u in ipairs(self.units)do if u.id==id then return u end end end
 function p:Units()local i=0;return function()i=i+1;return self.units[i]end end
 function p:GetInternationalTradeRoutePlotToolTip(plot)return plot.route and {"first visible route","second visible route"}or{}end
 return p
end
assert(loadfile(arg[1]))()
local count,failed=0,0
local function check(name,fn)
 Players={[0]=player(1,55),[1]=player(2,55),[2]=player(1,56)}
 count=count+1;local ok,err=pcall(fn);failed=failed+(ok and 0 or 1)
 print((ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ' '..tostring(err)))
end
check('Raider-plunder-restores-two-moves',function()handlers.UnitPlundered(0,8192,4,5);assert(Players[0].unit.moves==420);assert(Players[0].unit.xp==15)end)
check('Raider-pillage-restores-two-moves',function()handlers.UnitPillaged(0,8192,4,5);assert(Players[0].unit.moves==420 and Players[0].unit.xp==15)end)
check('Raider-can-overfill-movement',function()Players[0].unit.moves=480;handlers.UnitPlundered(0,8192,4,5);assert(Players[0].unit.moves==600)end)
check('ordinary-unit-no-reward',function()handlers.UnitPlundered(2,8192,4,5);assert(Players[2].unit.moves==300 and Players[2].unit.xp==0)end)
check('foreign-Raider-no-reward',function()handlers.UnitPillaged(1,8192,4,5);assert(Players[1].unit.moves==300 and Players[1].unit.xp==0)end)
check('missing-unit-no-reward',function()handlers.UnitPillaged(0,9000,4,5);assert(Players[0].unit.moves==300 and Players[0].unit.xp==0)end)
check('world-wonder-fixed-gold-and-celebration',function()handlers.CityConstructed(0,42,100,false,false);assert(Players[0].gold==100 and Players[0].city.king==15)end)
check('world-wonder-repeated-award-stacks',function()Players[0].gold=10;Players[0].city.king=7;handlers.CityConstructed(0,42,100,false,false);handlers.CityConstructed(0,42,100,false,false);assert(Players[0].gold==210 and Players[0].city.king==37)end)
check('ordinary-building-no-wonder-reward',function()handlers.CityConstructed(0,42,101,false,false);assert(Players[0].gold==0 and Players[0].city.king==0)end)
check('national-building-no-world-reward',function()handlers.CityConstructed(0,42,102,false,false);assert(Players[0].gold==0 and Players[0].city.king==0)end)
check('team-building-no-world-reward',function()handlers.CityConstructed(0,42,103,false,false);assert(Players[0].gold==0 and Players[0].city.king==0)end)
check('foreign-wonder-no-UAE-reward',function()handlers.CityConstructed(1,42,100,false,false);assert(Players[1].gold==0 and Players[1].city.king==0)end)
check('dead-owner-construction-ignored',function()Players[0].alive=false;handlers.CityConstructed(0,42,100,false,false);assert(Players[0].gold==0 and Players[0].city.king==0)end)
check('route-guard-counts-units-not-tooltip-entries',function()handlers.PlayerDoTurn(0);assert(Players[0].gold==3 and Players[0].unit.xp==1)end)
check('route-guard-repeat-is-per-owner-turn',function()handlers.PlayerDoTurn(0);handlers.PlayerDoTurn(0);assert(Players[0].gold==6 and Players[0].unit.xp==2)end)
check('route-guard-combat-and-location-controls',function()local p=Players[0];p.units={unit(1,55,true,true),unit(2,56,true,true),unit(3,57,false,true),unit(4,55,true,false)};handlers.PlayerDoTurn(0);assert(p.gold==6 and p.units[1].xp==1 and p.units[2].xp==1 and p.units[3].xp==0 and p.units[4].xp==0)end)
check('foreign-route-guard-rejected',function()handlers.PlayerDoTurn(1);assert(Players[1].gold==0 and Players[1].unit.xp==0)end)
check('empty-army-no-guard-reward',function()Players[0].units={};handlers.PlayerDoTurn(0);assert(Players[0].gold==0)end)
print(count..' cases, '..failed..' failures');os.exit(failed==0 and 0 or 1)
