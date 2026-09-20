-- Execute shipped Lua with controlled inputs and the C++ event signatures.
-- This establishes callback behavior, not native event timing or gameplay.
local root=assert(arg[1], "pass LEKMOD/Lua/Civilizations")
local ids={CIVILIZATION_SWISS=10,CIVILIZATION_POLYNESIA=11,CIVILIZATION_NEW_ZEALAND=12,
 PROMOTION_SWISS_MOUNTAINEER=100,PROMOTION_SWISS_MOUNTAINEER_ACTIVE=101,TERRAIN_MOUNTAIN=102,
 PROMOTION_OCEAN_IMPASSABLE=103,PROMOTION_ATTACK_AWAY_CAPITAL=104,
 PROMOTION_JFD_DEFENDER_ACTIVE=105,PROMOTION_JFD_DEFENDER=106}
local function iterator(values)
 local i=0;return function()i=i+1;return values[i]end
end
local function plot(owner,radii)
 local p={owner=owner or -1,radii=radii or {},x=0,y=0}
 function p:GetOwner()return self.owner end
 function p:IsPlayerCityRadius(id)local v=self.radii[id];return v==true or(type(v)=="number"and v<=3)end
 function p:GetX()return self.x end;function p:GetY()return self.y end
 return p
end
local function unit(id,promotions,p)
 local u={id=id,promotions=promotions or {},plot=p or plot(),near=false,terrainQueries=0,writes=0}
 function u:IsHasPromotion(id)return self.promotions[id] or false end
 function u:SetHasPromotion(id,value)self.promotions[id]=value;self.writes=self.writes+1 end
 function u:IsNearTerrainType(terrain,distance,sameArea)
  assert(terrain==ids.TERRAIN_MOUNTAIN and distance==1 and sameArea==false)
  self.terrainQueries=self.terrainQueries+1;return self.near
 end
 function u:GetPlot()return self.plot end
 function u:GetX()return 12 end;function u:GetY()return 14 end
 return u
end
local function player(id,civ)
 local p={id=id,civ=civ or -1,alive=true,minor=false,barbarian=false,human=id==0,
 units={},cities={},friends={},influence={},friendshipLevel=0,faith=0,culture=0,gold=0,overflow=0,research=-1,team=id+7}
 function p:GetID()return self.id end;function p:GetName()return "Owner "..self.id end
 function p:GetCivilizationType()return self.civ end;function p:IsAlive()return self.alive end
 function p:IsMinorCiv()return self.minor end;function p:IsBarbarian()return self.barbarian end
 function p:IsHuman()return self.human end;function p:GetTeam()return self.team end
 function p:Units()return iterator(self.units)end
 function p:Cities()return iterator(self.cities)end
 function p:GetUnitByID(id)for _,u in ipairs(self.units)do if u.id==id then return u end end end
 function p:IsDoF(id)assert(id<4,"friendship query used a non-major ID");return self.friends[id] or false end
 function p:GetMinorCivFriendshipLevelWithMajor(id)assert(id<4);return self.friendshipLevel end
 function p:ChangeMinorCivFriendshipWithMajor(id,n)assert(id<4);self.influence[id]=(self.influence[id] or 0)+n end
 function p:GetCurrentResearch()return self.research end
 function p:ChangeFaith(n)self.faith=self.faith+n end
 function p:ChangeJONSCulture(n)self.culture=self.culture+n end
 function p:ChangeGold(n)self.gold=self.gold+n end
 function p:ChangeOverflowResearch(n)self.overflow=self.overflow+n end
 return p
end
local function fixture(file,active)
 local e=setmetatable({},{__index=_G});e._G=e;e.GameInfoTypes=ids;e.Players={};e.Teams={}
 e.events={};e.alerts=0;e.popups=0;e.random=1;e.randomCalls=0;e.researchAwards={}
 for id=0,5 do
  local p=player(id);p.minor=id==4;p.barbarian=id==5;e.Players[id]=p
  e.Teams[p.team]={GetLeaderID=function()return id end,GetTeamTechs=function()return {
   ChangeResearchProgress=function(_,tech,n,owner)table.insert(e.researchAwards,{team=p.team,tech=tech,amount=n,owner=owner})end}end}
 end
 e.Map={PlotDistance=function(x,y,cx,cy)return math.max(math.abs(x-cx),math.abs(y-cy),math.abs(x-cx+y-cy))end}
 e.GameDefines={MAX_MAJOR_CIVS=4}
 e.Game={GetActivePlayer=function()return 0 end}
 e.GameEvents=setmetatable({},{__index=function(_,name)return {Add=function(fn)
  e.events[name]=e.events[name] or {};table.insert(e.events[name],fn)
 end}end})
 e.include=function()end;e.print=function()end
 e.LekmodUtilities={is_civilization_active=function()return active~=false end,
  get_random_between=function(_,a,b)assert(a==1 and b==4);e.randomCalls=e.randomCalls+1;return e.random end}
 e.Locale={ConvertTextKey=function(...)return "text" end}
 e.Events=setmetatable({GameplayAlertMessage=function()e.alerts=e.alerts+1 end,AddPopupTextEvent=function()e.popups=e.popups+1 end},{__index=function(_,name)return {Add=function(fn)
  e.events[name]=e.events[name]or{};table.insert(e.events[name],fn)
 end}end})
 e.Vector2=function(x,y)return {x,y}end;e.ToHexFromGrid=function(p)return p end;e.HexToWorld=function(p)return p end
 local chunk=assert(loadfile(root.."/Lekmod_"..file..".lua"));setfenv(chunk,e);chunk()
 function e:emit(name,...)assert(self.events[name],"missing event "..name);for _,fn in ipairs(self.events[name])do fn(...)end end
 return e
end
local tests={}
local function test(name,fn)tests[#tests+1]={name,fn}end
local function swiss(event,owner,near,active)
 local e=fixture("switzerland",active);local u=unit(8192,{[100]=true});u.near=near
 e.Players[owner].units={u};e:emit(event,owner,8192,12,14);return e,u
end
test("Swiss creation applies mountain bonus",function()local _,u=swiss("UnitCreated",0,true);assert(u:IsHasPromotion(101))end)
test("Swiss movement removes stale mountain bonus",function()
 local e,u=swiss("UnitCreated",0,true);u.near=false;e:emit("UnitSetXY",0,8192,13,14);assert(not u:IsHasPromotion(101))
end)
test("Swiss foreign owner works with civilization inactive",function()local _,u=swiss("UnitSetXY",2,true,false);assert(u:IsHasPromotion(101))end)
test("Swiss city-state unit retains terrain ability",function()local _,u=swiss("UnitCreated",4,true,false);assert(u:IsHasPromotion(101))end)
test("Swiss owner-local instance ID selects only event owner",function()
 local e,u=swiss("UnitCreated",0,true);local other=unit(8192,{[100]=true});other.near=false;e.Players[1].units={other}
 e:emit("UnitSetXY",1,8192,12,14);assert(u:IsHasPromotion(101) and not other:IsHasPromotion(101))
end)
test("Swiss unrelated unit has no terrain query or promotion writes",function()
 local e=fixture("switzerland");local u=unit(8192);e.Players[0].units={u};e:emit("UnitCreated",0,8192,12,14)
 assert(u.writes==0 and u.terrainQueries==0)
end)
test("Polynesia creation clears ocean restriction on all owned units",function()
 local e=fixture("polynesia");local p=e.Players[0];p.civ=11;p.units={unit(8192,{[103]=true,[999]=true}),unit(16384,{[103]=true})}
 e:emit("UnitCreated",0,16384,12,14);assert(not p.units[1]:IsHasPromotion(103) and not p.units[2]:IsHasPromotion(103) and p.units[1]:IsHasPromotion(999))
end)
test("Polynesia AI owner receives ocean access",function()
 local e=fixture("polynesia");local p=e.Players[1];p.civ=11;p.units={unit(8192,{[103]=true})};e:emit("UnitCreated",1,8192,12,14);assert(not p.units[1]:IsHasPromotion(103))
end)
for _,kind in ipairs({"unrelated","dead"})do test("Polynesia excludes "..kind.." owner",function()
 local e=fixture("polynesia");local p=e.Players[0];p.civ=kind=="dead" and 11 or -1;p.alive=kind~="dead";p.units={unit(8192,{[103]=true})}
 e:emit("UnitCreated",0,8192,12,14);assert(p.units[1]:IsHasPromotion(103))
end)end
for _,owner in ipairs({0,1})do test("Polynesia post-upgrade restores ocean access for owner "..owner,function()
 local e=fixture("polynesia");local p=e.Players[owner];p.civ=11;local u=unit(16384,{[103]=true,[999]=true});p.units={u}
 e:emit("UnitCreated",owner,16384,12,14);assert(not u:IsHasPromotion(103))
 -- The actual C++ conversion reapplies the upgraded type's free promotions.
 u.promotions[103]=true;e:emit("UnitConverted",owner,owner,8192,16384,true)
 assert(not u:IsHasPromotion(103)and u:IsHasPromotion(999))
end)end
test("Polynesia incoming gift refreshes the new owner",function()
 local e=fixture("polynesia");e.Players[1].civ=11;e.Players[0].units={unit(8192,{[103]=true})};e.Players[1].units={unit(8192,{[103]=true})}
 e:emit("UnitConverted",0,1,8192,8192,false)
 assert(e.Players[0].units[1]:IsHasPromotion(103)and not e.Players[1].units[1]:IsHasPromotion(103))
end)
test("Polynesia outgoing gift leaves foreign restriction intact",function()
 local e=fixture("polynesia");e.Players[0].civ=11;e.Players[0].units={unit(8192,{[103]=true})};e.Players[1].units={unit(16384,{[103]=true})}
 e:emit("UnitConverted",0,1,8192,16384,false)
 assert(e.Players[0].units[1]:IsHasPromotion(103)and e.Players[1].units[1]:IsHasPromotion(103))
end)
test("Polynesia conversion excludes dead recipient",function()
 local e=fixture("polynesia");local p=e.Players[1];p.civ=11;p.alive=false;p.units={unit(8192,{[103]=true})}
 e:emit("UnitConverted",0,1,8192,8192,false);assert(p.units[1]:IsHasPromotion(103))
end)
test("Polynesia conversion leaves third owner untouched",function()
 local e=fixture("polynesia");for _,owner in ipairs({1,2})do e.Players[owner].civ=11;e.Players[owner].units={unit(8192,{[103]=true})}end
 e:emit("UnitConverted",0,1,8192,8192,false)
 assert(not e.Players[1].units[1]:IsHasPromotion(103)and e.Players[2].units[1]:IsHasPromotion(103))
end)
test("Polynesia initialization reconciles saved human and AI ships",function()
 local e=fixture("polynesia")
 for _,owner in ipairs({0,1})do e.Players[owner].civ=11;e.Players[owner].units={unit(8192,{[103]=true,[999]=true})}end
 e:emit("SequenceGameInitComplete");e:emit("SequenceGameInitComplete")
 for _,owner in ipairs({0,1})do local u=e.Players[owner].units[1];assert(not u:IsHasPromotion(103)and u:IsHasPromotion(999)and u.writes==1)end
end)
test("Polynesia initialization excludes foreign and dead owners",function()
 local e=fixture("polynesia");e.Players[2].units={unit(8192,{[103]=true})};e.Players[3].civ=11;e.Players[3].alive=false;e.Players[3].units={unit(8192,{[103]=true})}
 e:emit("SequenceGameInitComplete");assert(e.Players[2].units[1]:IsHasPromotion(103)and e.Players[3].units[1]:IsHasPromotion(103))
end)
test("Polynesia inactive civilization registers no callback",function()local e=fixture("polynesia",false);assert(next(e.events)==nil)end)
local function battalion(owner,territory,level,promotion)
 local e=fixture("newzealand",false);e.Players[4].friendshipLevel=level or 0
 local u=unit(8192,promotion==false and {} or {[104]=true},plot(territory));e.Players[owner].units={u}
 e:emit("PlayerDoTurn",owner);return e,u
end
test("Battalion friend gains one influence and human popup",function()local e=battalion(0,4,1);assert(e.Players[4].influence[0]==1 and e.popups==1)end)
test("Battalion allied AI gets reward without human popup",function()local e=battalion(2,4,2);assert(e.Players[4].influence[2]==1 and e.popups==0)end)
for _,v in ipairs({{"neutral city-state",4,0,true},{"major territory",1,2,true},{"unowned territory",-1,2,true},{"unrelated unit",4,2,false}})do
 test("Battalion excludes "..v[1],function()local e=battalion(0,v[2],v[3],v[4]);assert(next(e.Players[4].influence)==nil and e.popups==0)end)
end
for _,owner in ipairs({4,5})do test("Battalion non-major owner "..owner.." is safely excluded",function()local e=battalion(owner,4,2);assert(next(e.Players[4].influence)==nil)end)end
test("Battalion each eligible unit contributes independently",function()
 local e=fixture("newzealand",false);e.Players[4].friendshipLevel=1;e.Players[0].units={unit(1,{[104]=true},plot(4)),unit(2,{[104]=true},plot(4))}
 e:emit("PlayerDoTurn",0);assert(e.Players[4].influence[0]==2)
end)
test("Battalion dead owner gets no reward",function()
 local e=fixture("newzealand");e.Players[0].alive=false;e.Players[4].friendshipLevel=1;e.Players[0].units={unit(1,{[104]=true},plot(4))}
 e:emit("PlayerDoTurn",0);assert(next(e.Players[4].influence)==nil)
end)
local function defender(owner,radii,friend)
 local e=fixture("newzealand",false);local u=unit(8192,{[106]=true},plot(-1,radii));e.Players[owner].units={u}
 for id,value in pairs(radii)do if value then local distance=value==true and 2 or value;e.Players[id].cities={{GetX=function()return distance end,GetY=function()return 0 end}}end end
 if friend then e.Players[1].friends[owner]=true end;e:emit("PlayerDoTurn",owner);return e,u
end
test("Defender own-city radius toggles to active promotion",function()local _,u=defender(0,{[0]=true});assert(u:IsHasPromotion(105) and not u:IsHasPromotion(106))end)
test("Defender living friend city radius enables bonus",function()local _,u=defender(0,{[1]=true},true);assert(u:IsHasPromotion(105))end)
test("Defender foreign nonfriend city radius is excluded",function()local _,u=defender(0,{[1]=true});assert(not u:IsHasPromotion(105) and u:IsHasPromotion(106))end)
test("Defender leaving radius restores default promotion",function()
 local e,u=defender(0,{[0]=true});u.plot.radii={};u.plot.x=8;e:emit("PlayerDoTurn",0);assert(not u:IsHasPromotion(105) and u:IsHasPromotion(106))
end)
test("Defender losing friendship clears active promotion",function()
 local e,u=defender(0,{[1]=true},true);e.Players[1].friends[0]=false;e:emit("PlayerDoTurn",0);assert(not u:IsHasPromotion(105) and u:IsHasPromotion(106))
end)
test("Defender dead friend does not qualify",function()
 local e,u=defender(0,{[1]=true},true);e.Players[1].alive=false;e:emit("PlayerDoTurn",0);assert(not u:IsHasPromotion(105))
end)
test("Defender minor can use own radius without major friendship indexing",function()local _,u=defender(4,{[4]=true});assert(u:IsHasPromotion(105))end)
test("Defender minor outside own radius does not query major friendship",function()local _,u=defender(4,{[1]=true});assert(not u:IsHasPromotion(105))end)
test("Defender barbarian owner is excluded",function()local _,u=defender(5,{[5]=true});assert(not u:IsHasPromotion(105))end)
test("Defender unrelated unit is untouched",function()
 local e=fixture("newzealand");local u=unit(1,{},plot(-1,{[0]=true}));e.Players[0].units={u};e:emit("PlayerDoTurn",0);assert(u.writes==0)
end)
for _,distance in ipairs({0,1,2,3,4})do test("Defender exact own-city distance "..distance,function()
 local _,u=defender(0,{[0]=distance});assert(u:IsHasPromotion(105)==(distance<=2))
end)end
test("Defender exact friendly-city distance three is excluded",function()local _,u=defender(0,{[1]=3},true);assert(not u:IsHasPromotion(105))end)
test("Defender minor distance three is excluded",function()local _,u=defender(4,{[4]=3});assert(not u:IsHasPromotion(105))end)
test("Defender AI distance two works",function()local _,u=defender(2,{[2]=2});assert(u:IsHasPromotion(105))end)
test("Defender stale distance-three active flag clears",function()
 local e,u=defender(0,{[0]=3});u.promotions[105]=true;u.promotions[106]=false;e:emit("PlayerDoTurn",0);assert(not u:IsHasPromotion(105)and u:IsHasPromotion(106))
end)
test("Defender nil plot does not activate or query cities",function()
 local e=fixture("newzealand",false);local u=unit(1,{[106]=true});u.plot=nil;e.Players[0].units={u};e:emit("PlayerDoTurn",0);assert(not u:IsHasPromotion(105)and u:IsHasPromotion(106))
end)
for _,v in ipairs({{1,"faith",10},{2,"culture",6},{3,"overflow",12},{4,"gold",40}})do test("New Zealand meeting reward "..v[2],function()
 local e=fixture("newzealand");e.Players[0].civ=12;e.random=v[1];e:emit("TeamMeet",8,7)
 assert(e.Players[0][v[2]]==v[3] and e.Players[1][v[2]]==0 and e.randomCalls==1 and e.alerts==1)
end)end
test("New Zealand science routes to current research on owner's team",function()
 local e=fixture("newzealand");e.Players[1].civ=12;e.Players[1].research=77;e.random=3;e:emit("TeamMeet",7,8)
 local a=assert(e.researchAwards[1]);assert(#e.researchAwards==1 and a.team==8 and a.owner==1 and a.tech==77 and a.amount==12 and e.Players[1].overflow==0 and e.alerts==0)
end)
test("New Zealand meeting awards both qualifying owners independently",function()
 local e=fixture("newzealand");e.Players[0].civ=12;e.Players[1].civ=12;e:emit("TeamMeet",8,7)
 assert(e.Players[0].faith==10 and e.Players[1].faith==10 and e.randomCalls==2 and e.alerts==1)
end)
test("New Zealand dead owner gets no reward or random draw",function()
 local e=fixture("newzealand");e.Players[0].civ=12;e.Players[0].alive=false;e:emit("TeamMeet",8,7);assert(e.randomCalls==0 and e.alerts==0)
end)
test("New Zealand inactive registration preserves unique-unit callbacks",function()
 local e=fixture("newzealand",false);assert(not e.events.TeamMeet and #e.events.PlayerDoTurn==2)
end)
local failed=0
for _,t in ipairs(tests)do local ok,err=pcall(t[2]);print((ok and "PASS " or "FAIL ")..t[1]..(ok and "" or ": "..tostring(err)));if not ok then failed=failed+1 end end
print(#tests.." unit/owner callback cases; "..failed.." failures")
os.exit(failed==0 and 0 or 1)
