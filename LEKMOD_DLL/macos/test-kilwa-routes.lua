-- Real route-filter utility and Kilwa callback; no native route lifecycle claim.
local root=assert(arg[1],"pass LEKMOD/Lua")
local function city(owner,id)
 local c={owner=owner,id=id,buildings={}}
 function c:GetOwner()return self.owner end
 function c:SetNumRealBuilding(id,n)assert(id==100);self.buildings[id]=n end
 return c
end
local function fixture(active)
 local e=setmetatable({},{__index=_G});e._G=e;e.events={};e.Players={};e.include=function()end
 e.GameInfoTypes={CIVILIZATION_KILWA=1,BUILDING_KILWA_TRAIT=100};e.GameDefines={MAX_MAJOR_CIVS=4}
 e.SlotStatus={SS_TAKEN=1,SS_COMPUTER=2};e.PreGame={GetSlotStatus=function(id)return id<2 and id+1 or 0 end,GetCivilization=function(id)return active~=false and 1 or 2 end}
 e.GameEvents=setmetatable({},{__index=function(_,name)return {Add=function(f)e.events[name]=f end}end})
 for id=0,2 do
  local p={id=id,team=id,civ=id<2 and 1 or 2,alive=true,cities={city(id,0),city(id,1)},routes={}}
  function p:GetID()return self.id end;function p:GetTeam()return self.team end;function p:GetCivilizationType()return self.civ end
  function p:IsAlive()return self.alive end;function p:GetTradeRoutes()return self.routes end
  function p:Cities()local i=0;return function()i=i+1;return self.cities[i]end end
  e.Players[id]=p
 end
 local a,b=e.Players[0].cities[1],e.Players[0].cities[2];local foreign=e.Players[1].cities[1]
 local minor=city(22,0)
 e.Players[0].routes={
  {FromCity=a,ToCity=foreign,Domain=0},{FromCity=a,ToCity=minor,Domain=1},
  {FromCity=a,ToCity=b,Domain=0},{FromCity=b,ToCity=foreign,Domain=1},
  {FromCity=foreign,ToCity=a,Domain=1},{FromCity=a,Domain=0}}
 for _,path in ipairs({root.."/Utilities/Lekmod_utilities.lua",root.."/Civilizations/Lekmod_kilwa.lua"})do
  local f=assert(loadfile(path));setfenv(f,e);f()
 end
 function e:count(international,internal,domain)
  return self.LekmodUtilities:get_number_trade_routes_from_city(self.Players[0],self.Players[0].cities[1],international,internal,domain)
 end
 return e
end
local tests={};local function test(name,fn)tests[#tests+1]={name,fn}end
test("international includes major and minor destinations",function()local e=fixture();assert(e:count(true,false)==2)end)
test("internal excludes foreign destinations",function()local e=fixture();assert(e:count(false,true)==1)end)
test("unfiltered includes all valid originating routes",function()local e=fixture();assert(e:count(false,false)==3)end)
test("nil flags use unfiltered mode",function()local e=fixture();assert(e:count(nil,nil)==3)end)
test("domain zero is an active land filter",function()local e=fixture();assert(e:count(true,false,0)==1)end)
test("sea filter selects one outgoing international route",function()local e=fixture();assert(e:count(true,false,1)==1)end)
test("unavailable domain has no routes",function()local e=fixture();assert(e:count(false,false,2)==0)end)
test("empty route list returns zero",function()local e=fixture();e.Players[0].routes={};assert(e:count(true,false)==0)end)
test("owner-local city IDs do not merge unrelated origins",function()
 local e=fixture();local p=e.Players[0];p.routes={{FromCity=e.Players[1].cities[1],ToCity=e.Players[2].cities[1],Domain=0}}
 assert(p.cities[1].id==e.Players[1].cities[1].id and e:count(true,false)==0)
end)
test("Kilwa assigns independent counts per city",function()
 local e=fixture();e.events.PlayerDoTurn(0);assert(e.Players[0].cities[1].buildings[100]==2 and e.Players[0].cities[2].buildings[100]==1)
end)
test("Kilwa removed routes clear stale building counts",function()
 local e=fixture();e.events.PlayerDoTurn(0);e.Players[0].routes={};e.events.PlayerDoTurn(0)
 for _,c in ipairs(e.Players[0].cities)do assert(c.buildings[100]==0)end
end)
test("Kilwa repeated callback does not stack counts",function()
 local e=fixture();e.events.PlayerDoTurn(0);e.events.PlayerDoTurn(0);assert(e.Players[0].cities[1].buildings[100]==2)
end)
test("Kilwa AI owner routes are separate",function()
 local e=fixture();local p=e.Players[1];p.routes={{FromCity=p.cities[2],ToCity=e.Players[0].cities[1],Domain=0}}
 e.events.PlayerDoTurn(1);assert(p.cities[1].buildings[100]==0 and p.cities[2].buildings[100]==1 and not e.Players[0].cities[1].buildings[100])
end)
test("Kilwa real prekill argument order refreshes owner only",function()
 local e=fixture();e.events.UnitPrekill(0,8192,42,12,14,true,1)
 assert(e.Players[0].cities[1].buildings[100]==2 and not e.Players[1].cities[1].buildings[100])
end)
test("Kilwa other civilization is excluded",function()
 local e=fixture();e.events.PlayerDoTurn(2);assert(not e.Players[2].cities[1].buildings[100])
end)
test("Kilwa dead owner is excluded",function()
 local e=fixture();e.Players[0].alive=false;e.events.PlayerDoTurn(0);assert(not e.Players[0].cities[1].buildings[100])
end)
test("war cancellation refreshes after the prekill stale count",function()
 local e=fixture();local p=e.Players[0]
 e.events.PlayerDoTurn(0);assert(p.cities[1].buildings[100]==2)
 p.routes={{FromCity=p.cities[1],ToCity=e.Players[2].cities[1],Domain=0}}
 e.events.UnitPrekill(0,8192,42,12,14,false,2);assert(p.cities[1].buildings[100]==1)
 p.routes={};assert(e.events.DeclareWar,"post-cancellation war callback missing");e.events.DeclareWar(0,2)
 assert(p.cities[1].buildings[100]==0 and p.cities[2].buildings[100]==0)
end)
test("war refresh retains internal-route exclusion",function()
 local e=fixture();local p=e.Players[0];e.events.PlayerDoTurn(0)
 p.routes={{FromCity=p.cities[1],ToCity=p.cities[2],Domain=0}}
 assert(e.events.DeclareWar,"war callback missing");e.events.DeclareWar(0,2)
 assert(p.cities[1].buildings[100]==0)
end)
test("war team IDs update every matching Kilwa owner",function()
 local e=fixture();local a,b=e.Players[0],e.Players[1];a.team=7;b.team=7;e.Players[2].team=8
 b.routes={{FromCity=b.cities[1],ToCity=e.Players[2].cities[1],Domain=1}}
 e.events.PlayerDoTurn(0);e.events.PlayerDoTurn(1);a.routes={};b.routes={}
 assert(e.events.DeclareWar,"war callback missing");e.events.DeclareWar(7,8)
 assert(a.cities[1].buildings[100]==0 and b.cities[1].buildings[100]==0)
end)
test("war excludes unrelated teams",function()
 local e=fixture();assert(e.events.DeclareWar,"war callback missing");e.events.DeclareWar(2,3)
 assert(not e.Players[0].cities[1].buildings[100]and not e.Players[1].cities[1].buildings[100])
end)
test("war excludes non-Kilwa participants",function()
 local e=fixture();assert(e.events.DeclareWar,"war callback missing");e.events.DeclareWar(0,2)
 assert(not e.Players[2].cities[1].buildings[100])
end)
test("war excludes dead Kilwa owners",function()
 local e=fixture();e.Players[0].alive=false;assert(e.events.DeclareWar,"war callback missing");e.events.DeclareWar(0,2)
 assert(not e.Players[0].cities[1].buildings[100])
end)
test("inactive Kilwa registers no callbacks",function()local e=fixture(false);assert(next(e.events)==nil)end)
local failed=0
for _,t in ipairs(tests)do local ok,err=pcall(t[2]);print((ok and "PASS " or "FAIL ")..t[1]..(ok and "" or ": "..tostring(err)));if not ok then failed=failed+1 end end
print(#tests.." Kilwa route-helper/callback cases; "..failed.." failures")
os.exit(failed==0 and 0 or 1)
