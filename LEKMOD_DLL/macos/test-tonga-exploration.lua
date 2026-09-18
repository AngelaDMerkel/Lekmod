-- Actual Tonga callback and shipped plot iterators on a finite axial hex grid.
-- Grid conversion and area/visibility bindings are stand-ins, not native proof.
local root=assert(arg[1],"pass LEKMOD/Lua")
local source=arg[2] or root.."/Civilizations/Lekmod_tonga.lua"
local function fixture(active)
 local e=setmetatable({},{__index=_G});e._G=e;e.Players={};e.GameInfoTypes={CIVILIZATION_TONGA=1}
 e.LekmodUtilities={is_civilization_active=function()return active~=false end}
 e.include=function()end;e.print=function()end
 e.ToHexFromGrid=function(p)return {x=p.x,y=p.y}end
 e.ToGridFromHex=function(x,y)return x,y end
 local plots={}
 for x=-30,30 do for y=-30,30 do
  local p={x=x,y=y,area=0,water=true,coastal=false,lake=false,revealed={}}
  function p:GetX()return self.x end;function p:GetY()return self.y end
  function p:Area()return self.area end;function p:IsWater()return self.water end
  function p:IsCoastalLand()return self.coastal end;function p:IsLake()return self.lake end
  function p:SetRevealed(team,value)assert(value==true,"exploration must not hide plots");self.revealed[team]=true end
  plots[x..","..y]=p
 end end
 e.Map={GetPlot=function(x,y)return plots[x..","..y]end}
 function e:land(x,y,area,coastal)
  local p=assert(self.Map.GetPlot(x,y));p.area=area;p.water=false;p.coastal=coastal~=false;return p
 end
 function e:player(id,x,y,area,civ,everAlive)
  local start=self:land(x,y,area);local p={civ=civ or 1,everAlive=everAlive~=false,team=id+7,start=start}
  function p:GetTeam()return self.team end;function p:GetStartingPlot()return self.start end
  function p:GetCivilizationType()return self.civ end;function p:IsEverAlive()return self.everAlive end
  self.Players[id]=p;return p
 end
 e:player(0,0,0,1)
 e.Events={SequenceGameInitComplete={Add=function(f)assert(not e.init);e.init=f end}}
 for _,path in ipairs({root.."/Utilities/PlotIterators.lua",source})do local f=assert(loadfile(path));setfenv(f,e);f()end
 return e
end
local tests={};local function test(name,fn)tests[#tests+1]={name,fn}end
local function revealed(e,x,y,team)return e.Map.GetPlot(x,y).revealed[team or 7] or false end
test("single-tile island within discovery radius is explored",function()
 local e=fixture();e:land(10,0,2);e.init();assert(revealed(e,10,0),"nearby single-tile island remained hidden")
end)
test("single-tile island's adjacent coast is explored",function()
 local e=fixture();e:land(10,0,2);e.init();assert(revealed(e,11,0),"water next to nearby island remained hidden")
end)
test("island at radius twelve is included",function()
 local e=fixture();e:land(12,0,2);e.init();assert(revealed(e,12,0),"outer-boundary island remained hidden")
end)
test("island beyond radius twelve is excluded",function()
 local e=fixture();e:land(13,0,2);e.init();assert(not revealed(e,13,0))
end)
test("two-tile island remains explored",function()
 local e=fixture();e:land(10,0,2);e:land(11,0,2);e.init();assert(revealed(e,10,0) and revealed(e,11,0))
end)
test("unconnected farther island is not revealed by nearby island scan",function()
 local e=fixture();e:land(12,0,2);e:land(15,0,3);e.init();assert(not revealed(e,15,0))
end)
test("nearby mainland coast reveals adjacent water",function()
 local e=fixture();for x=1,5 do e:land(x,0,1)end;e.init();assert(revealed(e,5,1))
end)
test("mainland beyond coastal radius is not treated as an island",function()
 local e=fixture();for x=1,10 do e:land(x,0,1)end;e.init();assert(not revealed(e,10,0))
end)
test("inland lake shore is excluded",function()
 local e=fixture();for x=1,5 do e:land(x,0,1,false)end
 e:land(5,0,1,true);e.Map.GetPlot(5,1).lake=true;e.init();assert(not revealed(e,5,1))
end)
test("human and AI Tonga retain separate revealed-team state",function()
 local e=fixture();e:player(1,0,-10,3);e:land(7,-5,2);e.init()
 assert(revealed(e,7,-5,7) and revealed(e,7,-5,8) and not revealed(e,7,-5,9))
end)
test("other and never-alive civilizations are excluded",function()
 local e=fixture();e.Players[0].civ=2;e:player(1,0,-10,3,1,false);e:land(7,-5,2);e.init()
 assert(not revealed(e,7,-5,7) and not revealed(e,7,-5,8))
end)
test("repeated initialization preserves prior revealed plots",function()
 local e=fixture();e:land(10,0,2);e.Map.GetPlot(-20,0):SetRevealed(7,true);e.init();e.init()
 assert(revealed(e,-20,0) and revealed(e,10,0))
end)
test("inactive Tonga registers no initialization callback",function()local e=fixture(false);assert(not e.init)end)
local failed=0
for _,t in ipairs(tests)do local ok,err=pcall(t[2]);print((ok and "PASS " or "FAIL ")..t[1]..(ok and "" or ": "..tostring(err)));if not ok then failed=failed+1 end end
print(#tests.." Tonga exploration cases; "..failed.." failures")
os.exit(failed==0 and 0 or 1)
