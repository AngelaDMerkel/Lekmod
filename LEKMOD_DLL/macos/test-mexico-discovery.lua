-- Isolated product-handler regression: no game process or visibility is changed.
local source=assert(arg[1],"pass product Lua path")
local function event()
 local handlers={}
 return {Add=function(f)handlers[#handlers+1]=f end,Remove=function(f)for i=#handlers,1,-1 do if handlers[i]==f then table.remove(handlers,i)end end end,
 Emit=function(...)local copy={};for i,f in ipairs(handlers)do copy[i]=f end;for _,f in ipairs(copy)do f(...)end end}
end
Events={SequenceGameInitComplete=event()}
GameEvents={PlayerCityFounded=event(),PlayerDoTurn=event()}
GameInfoTypes={CIVILIZATION_MEXICO=10}
LekmodUtilities={is_civilization_active=function()return true end}
local elapsed=0
Game={GetElapsedGameTurns=function()return elapsed end}
function include()end
SECTOR_NORTH=0;DIRECTION_CLOCKWISE=0;DIRECTION_OUTWARDS=0;CENTRE_EXCLUDE=0
local plots={}
local function plot(x)
 local p={x=x,revealed={}}
 function p:GetX()return self.x end;function p:GetY()return 0 end
 function p:GetPlotCity()return self.city end
 function p:SetRevealed(team,value)self.revealed[team]=value;if self.city then self.city.revealed[team]=value end end
 plots[x]=p;return p
end
Map={PlotDistance=function(x,_,other)return math.abs(x-other)end,GetPlot=function(x)return plots[x]end}
Players={}
local function player(id,civ,minor,x,alive)
 local p={start=x and (plots[x] or plot(x)),alive=alive~=false}
 function p:IsAlive()return self.alive end
 function p:IsMinorCiv()return minor end
 function p:GetCivilizationType()return civ end
 function p:GetTeam()return id end
 function p:GetStartingPlot()return self.start end
 Players[id]=p;return p
end
player(0,10,false,0);player(1,10,false,20);player(2,11,false,1);player(3,10,false,-20,false)
player(32,-1,true,10);player(33,-1,true,-10);player(34,-1,true,-11);player(35,-1,true,31);player(36,-1,true,nil)
function PlotAreaSweepIterator(start,radius)
 local list={};for _,p in pairs(plots)do if p~=start and math.abs(p.x-start.x)<=radius then list[#list+1]=p end end
 local i=0;return function()i=i+1;return list[i]end
end
local function city(owner,x)
 local p=plots[x] or plot(x);local c={revealed={}}
 function c:GetOwner()return owner end;function c:IsRevealed(team)return self.revealed[team] or false end
 p.city=c;return c
end
assert(loadfile(source))()
local failed,count=0,0
local function check(name,ok)
 count=count+1;print((ok and "PASS " or "FAIL ")..name);if not ok then failed=failed+1 end
end
Events.SequenceGameInitComplete.Emit()
check("human-starting-location",plots[10].revealed[0]==true)
check("second-Mexico-starting-location",plots[10].revealed[1]==true)
check("radius-ten-included",plots[-10].revealed[0]==true)
check("radius-eleven-excluded",not plots[-11].revealed[0] and not plots[31].revealed[1])
check("unrelated-major-excluded",not plots[1].revealed[0])
check("dead-Mexico-excluded",not plots[-10].revealed[3])
local c=city(32,10);GameEvents.PlayerCityFounded.Emit(32,10,0)
check("human-city-founded",c.revealed[0]==true)
check("second-Mexico-city-founded",c.revealed[1]==true)
local far=city(34,-11);GameEvents.PlayerCityFounded.Emit(34,-11,0)
check("far-city-excluded",not far.revealed[0])
local major=city(2,1);GameEvents.PlayerCityFounded.Emit(2,1,0)
check("major-city-excluded",not major.revealed[0])
local near=plot(9);player(37,-1,true,9);local late=city(37,9)
elapsed=1;GameEvents.PlayerCityFounded.Emit(37,9,0);Events.SequenceGameInitComplete.Emit()
check("later-foundation-and-load-excluded",not near.revealed[0] and not late.revealed[0])
elapsed=0;GameEvents.PlayerCityFounded.Emit(99,9,0)
check("unknown-player-safe",not near.revealed[0])
print(count.." Mexico discovery cases; "..failed.." failures")
os.exit(failed==0 and 0 or 1)
