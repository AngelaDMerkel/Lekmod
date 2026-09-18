-- Execute the actual periodic handler, including filters not claimed as native
-- gameplay by the ordinary-turn fixture. Deferred death matches CvUnit::kill(true).
local source=assert(arg[1]);function include()end
GameInfoTypes={CIVILIZATION_OMAN=1,BUILDING_MC_OMANI_MINAA=2,DOMAIN_SEA=0}
SECTOR_NORTH=0;DIRECTION_CLOCKWISE=0;DIRECTION_OUTWARDS=0;CENTRE_EXCLUDE=0
LekmodUtilities={is_civilization_active=function()return true end}
local handler;GameEvents={PlayerDoTurn={Add=function(f)handler=f end}}
local current
Players={}
Players[0]={IsAlive=function()return current.alive~=false end,GetCivilizationType=function()return current.civ or 1 end,GetTeam=function()return 3 end,
Cities=function()local once=false;return function()if not once then once=true;return {IsHasBuilding=function()return current.building~=false end,GetX=function()return 10 end,GetY=function()return 10 end}end end end}
Players[1]={GetTeam=function()return 7 end}
Teams={[3]={IsAtWar=function(_,team)return team==7 and current.war~=false end}}
Map={GetPlot=function()return {}end}
function PlotAreaSweepIterator(_,radius,_,_,_,center)
 assert(radius==1 and center==CENTRE_EXCLUDE)
 local once=false;return function()if not once then once=true;return {GetNumUnits=function()return #current.units end,GetUnit=function(_,i)return current.units[i+1]end}end end
end
assert(loadfile(source))()
local cases={
 {name="enemy-sea",domain=0,want=30},
 {name="embarked-land",domain=2,embarked=true,want=30},
 {name="unembarked-land",domain=2,want=0},
 {name="owned-sea",domain=0,owner=0,want=0},
 {name="peace-sea",domain=0,war=false,want=0},
 {name="no-building",domain=0,building=false,want=0},
 {name="other-civilization",domain=0,civ=9,want=0},
 {name="dead-owner",domain=0,alive=false,want=0},
 {name="deferred-lethal-stack",domain=0,initial=80,want=100,stack=true},
}
local failed=0
for _,c in ipairs(cases)do
 local function unit(domain,owner,embarked,damage)
  local u={damage=damage or 0};function u:GetOwner()return owner end;function u:GetDomainType()return domain end;function u:IsEmbarked()return embarked or false end
  function u:ChangeDamage(n)self.damage=math.min(100,self.damage+n);self.delayed=self.damage==100 end
  return u
 end
 current=c;c.units={unit(c.domain,c.owner or 1,c.embarked,c.initial)}
 if c.stack then c.units[2]=unit(2,1,true,0)end
 local ok,err=pcall(function()handler(0);assert(c.units[1].damage==c.want);if c.stack then assert(c.units[1].delayed and c.units[2].damage==30)end end)
 print((ok and "PASS " or "FAIL ")..c.name..(ok and "" or " "..tostring(err)));if not ok then failed=failed+1 end
end
print(#cases.." Minaa handler cases; "..failed.." failures");os.exit(failed==0 and 0 or 1)
