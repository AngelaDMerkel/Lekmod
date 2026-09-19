-- Actual handler with supplied capital-culture quotes. Native yield updates,
-- capital transfers and feedback between Cuban capitals are separate checks.
local source=assert(arg[1])
local function fixture(active)
 local e=setmetatable({},{__index=_G});e._G=e;e.Players={};e.Teams={};e.events={}
 e.GameInfoTypes={CIVILIZATION_CUBA=1,BUILDING_CUBA_TRAIT_UB2=100}
 e.GameDefines={MAX_MAJOR_CIVS=4};e.include=function()end;e.print=function()end
 e.LekmodUtilities={is_civilization_active=function()return active~=false end}
 e.GameEvents=setmetatable({},{__index=function(_,name)return {Add=function(fn)e.events[name]=fn end}end})
 for id=0,3 do
  local city={culture=0,count=0,writes=0}
  function city:GetBaseJONSCulturePerTurn()return self.culture end
  function city:SetNumRealBuilding(building,n)assert(building==100);self.count=n;self.writes=self.writes+1 end
  local p={civ=(id<2 and 1 or 2),team=id+7,capital=city}
  function p:GetCivilizationType()return self.civ end;function p:GetTeam()return self.team end
  function p:GetCapitalCity()return self.capital end
  e.Players[id]=p
  local team={met={}}
  function team:IsHasMet(other)assert(other>=7,"player ID used in place of team ID");return self.met[other] or false end
  e.Teams[p.team]=team
 end
 local f=assert(loadfile(source));setfenv(f,e);f()
 function e:meet(owner,other)self.Teams[self.Players[owner].team].met[self.Players[other].team]=true end
 return e
end
local tests={};local function test(name,fn)tests[#tests+1]={name,fn}end
for _,row in ipairs({{0,0},{4,0},{5,1},{9,1},{10,2}})do test("culture threshold "..row[1],function()
 local e=fixture();e.Players[2].capital.culture=row[1];e:meet(0,2);e.events.PlayerDoTurn(0);assert(e.Players[0].capital.count==row[2])
end)end
test("round each foreign capital before summing",function()
 local e=fixture();e.Players[2].capital.culture=4;e.Players[3].capital.culture=4;e:meet(0,2);e:meet(0,3)
 e.events.PlayerDoTurn(0);assert(e.Players[0].capital.count==0)
end)
test("met capitals contribute independently",function()
 local e=fixture();e.Players[2].capital.culture=9;e.Players[3].capital.culture=10;e:meet(0,2);e:meet(0,3)
 e.events.PlayerDoTurn(0);assert(e.Players[0].capital.count==3)
end)
test("unmet foreign capital is excluded",function()
 local e=fixture();e.Players[2].capital.culture=100;e.events.PlayerDoTurn(0);assert(e.Players[0].capital.count==0)
end)
test("own capital is excluded even when own team is met",function()
 local e=fixture();e.Players[0].capital.culture=100;e:meet(0,0);e.events.PlayerDoTurn(0);assert(e.Players[0].capital.count==0)
end)
test("missing foreign capital is excluded",function()
 local e=fixture();e.Players[2].capital=nil;e:meet(0,2);e.events.PlayerDoTurn(0);assert(e.Players[0].capital.count==0)
end)
test("owner without a capital is safe",function()
 local e=fixture();e.Players[0].capital=nil;e.events.PlayerDoTurn(0)
end)
test("non-Cuban owner receives no write",function()
 local e=fixture();e.Players[0].capital.culture=20;e:meet(2,0);e.events.PlayerDoTurn(2);assert(e.Players[2].capital.writes==0)
end)
test("AI owner uses its own met teams and capital",function()
 local e=fixture();e.Players[0].capital.culture=5;e.Players[2].capital.culture=10;e:meet(1,0);e:meet(1,2)
 e.events.PlayerDoTurn(1);assert(e.Players[1].capital.count==3 and e.Players[0].capital.writes==0)
end)
test("falling source quote clears stale bonus",function()
 local e=fixture();e:meet(0,2);e.Players[2].capital.culture=10;e.events.PlayerDoTurn(0);assert(e.Players[0].capital.count==2)
 e.Players[2].capital.culture=4;e.events.PlayerDoTurn(0);assert(e.Players[0].capital.count==0)
end)
test("repeat with identical quotes does not stack",function()
 local e=fixture();e:meet(0,2);e.Players[2].capital.culture=10;e.events.PlayerDoTurn(0);e.events.PlayerDoTurn(0);assert(e.Players[0].capital.count==2)
end)
test("inactive Cuba does not register callbacks",function()local e=fixture(false);assert(next(e.events)==nil)end)
local failed=0
for _,t in ipairs(tests)do local ok,err=pcall(t[2]);print((ok and "PASS "or"FAIL ")..t[1]..(ok and ""or": "..tostring(err)));if not ok then failed=failed+1 end end
print(#tests.." Cuba capital-culture handler cases; "..failed.." failures");os.exit(failed==0 and 0 or 1)
