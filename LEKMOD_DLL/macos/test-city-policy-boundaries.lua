-- Offline execution of shipped handlers with engine event argument order.
-- Native city disposition, conversion timing and policy adoption are not mocked outcomes.
local root=assert(arg[1],"pass LEKMOD/Lua/Civilizations")
local ids={CIVILIZATION_ROMANIA=1,CIVILIZATION_VATICAN=2,CIVILIZATION_YUGOSLAVIA=3,
 BUILDING_COURTHOUSE=100,POLICY_BRANCH_AUTOCRACY=10,POLICY_BRANCH_FREEDOM=11,POLICY_BRANCH_ORDER=12}
local function fixture(file,active)
 local e=setmetatable({},{__index=_G});e._G=e;e.events={};e.Players={};e.GameInfoTypes=ids
 e.include=function()end;e.print=function()end
 e.LekmodUtilities={is_civilization_active=function()return active~=false end}
 e.GameEvents=setmetatable({},{__index=function(_,name)return {Add=function(fn)
  e.events[name]=e.events[name] or {};table.insert(e.events[name],fn)
 end}end})
 e.GameInfo={GameSpeeds={[0]={GoldenAgePercent=100}}};e.Game={GetGameSpeedType=function()return 0 end}
 e.city={religion=5,occupied=true,puppet=false,buildings={},writes=0}
 function e.city:IsOccupied()return self.occupied end;function e.city:IsPuppet()return self.puppet end
 function e.city:GetReligiousMajority()return self.religion end
 function e.city:SetNumRealBuilding(id,n)self.buildings[id]=n;self.writes=self.writes+1 end
 e.Map={GetPlot=function(x,y)assert(x==12 and y==14,"event city coordinate order changed");return {GetPlotCity=function()return e.city end}end}
 for id=0,2 do
  local p={id=id,civ=-1,alive=true,points=0,rawPoints={},religion=5,anarchy=0,tenets=2,tenetWrites=0}
  function p:IsAlive()return self.alive end;function p:GetCivilizationType()return self.civ end
  function p:ChangeGoldenAgeProgressMeter(n)
   -- BasicLuaMethod converts this positive numeric argument to an int.
   table.insert(self.rawPoints,n);self.points=self.points+math.floor(n)
  end
  function p:GetReligionCreatedByPlayer()return self.religion end
  function p:GetAnarchyNumTurns()return self.anarchy end;function p:GetNumFreeTenets()return self.tenets end
  function p:SetNumFreeTenets(n,countAsFree)self.tenets=n;self.countAsFree=countAsFree;self.tenetWrites=self.tenetWrites+1 end
  e.Players[id]=p
 end
 local f=assert(loadfile(root.."/Lekmod_"..file..".lua"));setfenv(f,e);f()
 function e:emit(name,...)assert(self.events[name],"missing event "..name);for _,fn in ipairs(self.events[name])do fn(...)end end
 return e
end
local tests={};local function test(name,fn)tests[#tests+1]={name,fn}end
for _,v in ipairs({{"Quick",80,100},{"Standard",100,125},{"Epic",125,156},{"Marathon",200,250}})do
 test("Romania "..v[1].." capture award",function()
  local e=fixture("romania");e.Players[1].civ=1;e.GameInfo.GameSpeeds[0].GoldenAgePercent=v[2]
  e:emit("CityCaptureComplete",0,false,12,14,1,5,true,0,0)
  assert(e.Players[1].points==v[3] and e.Players[0].points==0)
  assert(e.Players[1].rawPoints[1]==125*v[2]/100)
 end)
end
test("Romania two owners retain independent awards",function()
 local e=fixture("romania");e.Players[0].civ=1;e.Players[1].civ=1
 e:emit("CityCaptureComplete",2,false,12,14,0,5,true,0,0)
 e:emit("CityCaptureComplete",2,false,12,14,1,5,true,0,0)
 assert(e.Players[0].points==125 and e.Players[1].points==125 and e.Players[2].points==0)
end)
for _,kind in ipairs({"other civilization","dead owner"})do test("Romania excludes "..kind,function()
 local e=fixture("romania");e.Players[1].civ=kind=="dead owner" and 1 or -1;e.Players[1].alive=kind~="dead owner"
 e:emit("CityCaptureComplete",0,false,12,14,1,5,true,0,0);assert(e.Players[1].points==0)
end)end
test("Vatican captured occupied own-religion city gets courthouse",function()
 local e=fixture("vatican");e.Players[1].civ=2;e:emit("CityCaptureComplete",0,false,12,14,1,5,true,0,0);assert(e.city.buildings[100]==1)
end)
test("Vatican conversion coordinates locate occupied city",function()
 local e=fixture("vatican");e.Players[0].civ=2;e:emit("CityConvertsReligion",0,5,12,14);assert(e.city.buildings[100]==1)
end)
test("Vatican puppet qualifies before annexation",function()
 local e=fixture("vatican");e.Players[0].civ=2;e.city.occupied=false;e.city.puppet=true
 e:emit("CityConvertsReligion",0,5,12,14);assert(e.city.buildings[100]==1)
end)
for _,kind in ipairs({"unoccupied","foreign majority","no religion","no founded religion","other owner","dead owner"})do
 test("Vatican excludes "..kind,function()
  local e=fixture("vatican");e.Players[0].civ=2
  if kind=="unoccupied" then e.city.occupied=false
  elseif kind=="foreign majority" then e.city.religion=6
  elseif kind=="no religion" then e.city.religion=-1;e.Players[0].religion=-1
  elseif kind=="no founded religion" then e.Players[0].religion=-1
  elseif kind=="other owner" then e.Players[0].civ=-1
  elseif kind=="dead owner" then e.Players[0].alive=false end
  e:emit("CityConvertsReligion",0,e.city.religion,12,14);assert(e.city.writes==0)
 end)
end
test("Vatican capture uses recipient rather than previous owner",function()
 local e=fixture("vatican");e.Players[0].civ=2;e:emit("CityCaptureComplete",0,false,12,14,1,5,true,0,0);assert(e.city.writes==0)
end)
test("Vatican repeated conversion does not stack courthouses",function()
 local e=fixture("vatican");e.Players[0].civ=2
 e:emit("CityConvertsReligion",0,5,12,14);e:emit("CityConvertsReligion",0,5,12,14);assert(e.city.buildings[100]==1)
end)
for _,branch in ipairs({10,11,12})do test("Yugoslavia ideology "..branch.." adds one free tenet",function()
 local e=fixture("yugoslavia");e.Players[0].civ=3;e:emit("PlayerPolicyBranchUnlocked",0,branch)
 assert(e.Players[0].tenets==3 and e.Players[0].countAsFree==true and e.Players[1].tenets==2)
end)end
test("Yugoslavia independent AI reward preserves existing tenets",function()
 local e=fixture("yugoslavia");e.Players[0].civ=3;e.Players[1].civ=3;e.Players[1].tenets=4
 e:emit("PlayerPolicyBranchUnlocked",1,11);assert(e.Players[1].tenets==5 and e.Players[0].tenets==2)
end)
for _,kind in ipairs({"ordinary branch","other civilization","dead owner","anarchy"})do test("Yugoslavia excludes "..kind,function()
 local e=fixture("yugoslavia");e.Players[0].civ=kind=="other civilization" and -1 or 3
 if kind=="dead owner" then e.Players[0].alive=false elseif kind=="anarchy" then e.Players[0].anarchy=1 end
 e:emit("PlayerPolicyBranchUnlocked",0,kind=="ordinary branch" and 1 or 10);assert(e.Players[0].tenetWrites==0)
end)end
for _,file in ipairs({"romania","vatican","yugoslavia"})do test(file.." inactive civilization registers no callbacks",function()
 local e=fixture(file,false);assert(next(e.events)==nil)
end)end
local failed=0
for _,t in ipairs(tests)do local ok,err=pcall(t[2]);print((ok and "PASS " or "FAIL ")..t[1]..(ok and "" or ": "..tostring(err)));if not ok then failed=failed+1 end end
print(#tests.." city/policy callback cases; "..failed.." failures")
os.exit(failed==0 and 0 or 1)
