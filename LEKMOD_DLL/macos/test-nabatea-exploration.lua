-- Execute the actual Zabonah handler; geometry is a stand-in, not native vision.
local source=assert(arg[1],"pass Lekmod_nabatea.lua")
local function fixture(active)
 local e=setmetatable({},{__index=_G});e._G=e;e.events={};e.alerts=0;e.scans=0;e.plots={}
 e.GameInfoTypes={CIVILIZATION_NABATEA=9,UNIT_MC_ZABONAH=77};e.include=function()end
 e.LekmodUtilities={is_civilization_active=function()return active~=false end}
 e.GameEvents={UnitSetXY={Add=function(fn)e.events.UnitSetXY=fn end}}
 e.Game={GetActivePlayer=function()return 0 end};e.Events={GameplayAlertMessage=function()e.alerts=e.alerts+1 end};e.Locale={ConvertTextKey=function()return 'reward'end}
 e.SECTOR_NORTH=1;e.DIRECTION_CLOCKWISE=false;e.DIRECTION_OUTWARDS=false;e.CENTRE_EXCLUDE=false
 e.Players={};for id=0,1 do
  local p={alive=true,gold=0,human=id==0,id=id,units={}}
  function p:IsAlive()return self.alive end;function p:IsHuman()return self.human end;function p:GetID()return self.id end
  function p:GetUnitByID(id)return self.units[id]end;function p:ChangeGold(n)self.gold=self.gold+n end
  e.Players[id]=p
 end
 local u={kind=77,sight=2,dead=false,delayed=false}
 function u:GetUnitType()return self.kind end;function u:GetTeam()return 7 end;function u:VisibilityRange()return self.sight end
 function u:IsDead()return self.dead end;function u:IsDelayedDeath()return self.delayed end
 e.unit=u;e.Players[0].units[8192]=u;e.Players[1].units[8192]=u
 local center={};e.Map={GetPlot=function(x,y)if x==10 and y==10 then return center end end}
 e.PlotAreaSweepIterator=function(p,r,sector,direction,inwards,centre)
  assert(p==center,'off-map position reached iterator');assert(r==u.sight+3 and sector==1 and not direction and not inwards and not centre)
  e.scans=e.scans+1;local i=0;return function()i=i+1;return e.plots[i]end
 end
 function e:addCity(capital,revealed)
  local c={capital=capital,revealed=revealed or false}
  function c:IsCapital()return self.capital end;function c:IsRevealed(team)assert(team==7);return self.revealed end;function c:GetName()return 'City'end
  local plot={};function plot:GetPlotCity()return c end;function plot:SetRevealed(team,value)assert(team==7 and value);c.revealed=value end
  self.plots[#self.plots+1]=plot;return c
 end
 local f=assert(loadfile(source));setfenv(f,e);f()
 function e:move(owner,id,x,y)self.events.UnitSetXY(owner or 0,id or 8192,x or 10,y or 10)end
 return e
end
local tests={};local function test(name,fn)tests[#tests+1]={name,fn}end
test('unrevealed capital awards ten gold and one active-human alert',function()local e=fixture();local c=e:addCity(true);e:move();assert(c.revealed and e.Players[0].gold==10 and e.alerts==1)end)
test('repeat event cannot reward the same revealed capital',function()local e=fixture();e:addCity(true);e:move();e:move();assert(e.Players[0].gold==10 and e.alerts==1)end)
test('already revealed capital gives no gold',function()local e=fixture();e:addCity(true,true);e:move();assert(e.Players[0].gold==0 and e.alerts==0)end)
test('noncapital city gives no gold',function()local e=fixture();e:addCity(false);e:move();assert(e.Players[0].gold==0)end)
test('two newly discovered capitals give independent rewards',function()local e=fixture();e:addCity(true);e:addCity(true);e:move();assert(e.Players[0].gold==20 and e.alerts==2)end)
test('AI unit owner receives gold without human alert',function()local e=fixture();e:addCity(true);e:move(1);assert(e.Players[1].gold==10 and e.Players[0].gold==0 and e.alerts==0)end)
test('unrelated unit does not scan or reward',function()local e=fixture();e.unit.kind=99;e:addCity(true);e:move();assert(e.scans==0 and e.Players[0].gold==0)end)
test('unique unit works with civilization inactive',function()local e=fixture(false);e:addCity(true);e:move();assert(e.Players[0].gold==10)end)
test('missing owner is ignored',function()local e=fixture();e:move(99);assert(e.scans==0)end)
test('missing unit is ignored',function()local e=fixture();e:move(0,123);assert(e.scans==0)end)
test('off-map removal position is ignored',function()local e=fixture();e:move(0,8192,-1,-1);assert(e.scans==0 and e.Players[0].gold==0)end)
test('dead owner cannot receive a reward',function()local e=fixture();e.Players[0].alive=false;e:addCity(true);e:move();assert(e.scans==0 and e.Players[0].gold==0)end)
test('pending-deletion unit cannot reveal or reward',function()local e=fixture();e.unit.delayed=true;e:addCity(true);e:move();assert(e.scans==0 and e.Players[0].gold==0)end)
local failed=0
for _,t in ipairs(tests)do local ok,err=pcall(t[2]);print((ok and'PASS 'or'FAIL ')..t[1]..(ok and''or': '..tostring(err)));if not ok then failed=failed+1 end end
print(#tests..' actual Nabatea exploration-handler cases; '..failed..' failures');os.exit(failed==0 and 0 or 1)
