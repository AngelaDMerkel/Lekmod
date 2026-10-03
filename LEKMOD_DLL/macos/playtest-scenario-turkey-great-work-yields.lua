-- Native method surface: GameCore
-- Slot buildings, Great People, one extra city and Archaeology research are
-- supplied. Works come from ordinary Great Person actions and a real dig/choice.
LekmodScenario={name="turkey-great-work-yields",items={"turkey-work-data","turkey-native-people-works","turkey-native-artifact","turkey-four-class-yields","turkey-work-movement","turkey-foreign-owner","turkey-returned-owner"}}
local phase,index,unitID,closed,waitFrames,otherCity,digIndex,digStarted,answered,pending="init",1,nil,false,0,nil,nil,nil,nil,nil
local kinds={{unit="UNIT_WRITER",class="GREAT_WORK_LITERATURE"},{unit="UNIT_ARTIST",class="GREAT_WORK_ART"},{unit="UNIT_MUSICIAN",class="GREAT_WORK_MUSIC"}}
local buildingNames={"BUILDING_AMPHITHEATER","BUILDING_MUSEUM","BUILDING_OPERA_HOUSE"}
local tracked={};local digComplete=false
LuaEvents.LekmodCultureGreatWorkClosed.Add(function()closed=true end)
LuaEvents.LekmodArchaeologyAnswered.Add(function(kind,x,y)answered={kind=kind,x=x,y=y}end)
GameEvents.BuildFinished.Add(function(owner,x,y,improvement)
 if owner==0 and digIndex and Map.GetPlot(x,y):GetPlotIndex()==digIndex then assert(improvement==GameInfoTypes.IMPROVEMENT_ARCHAEOLOGICAL_DIG);digComplete=true end
end)
local function slots(p)
 local r={};for c in p:Cities()do for info in GameInfo.Buildings()do
  if info.GreatWorkCount>0 and c:GetNumBuilding(info.ID)>0 then
   local class=GameInfoTypes[info.BuildingClass]
   for i=0,info.GreatWorkCount-1 do local id=c:GetBuildingGreatWork(class,i);r[#r+1]={city=c:GetID(),class=class,slot=i,work=id,kind=info.GreatWorkSlotType}end
  end
 end end;return r
end
local function cityYields(c)
 return {production=c:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_PRODUCTION),gold=c:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_GOLD),science=c:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_SCIENCE)}
end
local function checkYields(p,multiplier)
 for c in p:Cities()do local count=c:GetNumGreatWorks();local actual=cityYields(c)
  assert(actual.production==count*multiplier and actual.gold==count*multiplier and actual.science==count*multiplier,"wrong per-work Production/Gold/Science for owner "..p:GetID())
 end
end
local function discover(p)
 local seen=0
 for _,r in ipairs(slots(p))do if r.work>=0 then
  if not tracked[r.work]then tracked[r.work]={class=Game.GetGreatWorkClass(r.work),creator=Game.GetGreatWorkCreator(r.work)};seen=seen+1 end
 end end;return seen
end
local function action(u,kind)
 UI.SelectUnit(u)
 for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type==kind then assert(Game.CanHandleAction(i),"native action unavailable: "..kind);Game.HandleAction(i);return end end
 error("native action missing")
end
local function cityInput(p)
 local cap=p:GetCapitalCity()
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:GetResourceType(-1)==-1 and Map.PlotDistance(q:GetX(),q:GetY(),cap:GetX(),cap:GetY())>=5 and p:CanFound(q:GetX(),q:GetY())then p:Found(q:GetX(),q:GetY());return assert(q:GetPlotCity())end
 end
 error("no legal extra city")
end
function LekmodScenario.snapshot(p)
 local owners={}
 for owner=0,1 do local o=Players[owner];local cities,works={},{}
  for c in o:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),owner=c:GetOwner(),works=c:GetNumGreatWorks(),yields=cityYields(c)}end
  for _,r in ipairs(slots(o))do if r.work>=0 then works[r.work]={city=r.city,class=r.class,slot=r.slot,type=Game.GetGreatWorkClass(r.work),creator=Game.GetGreatWorkCreator(r.work),controller=Game.GetGreatWorkController(r.work)}end end
  owners[owner]={civilization=o:GetCivilizationType(),count=o:GetNumGreatWorks(),cities=cities,works=works}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_TURKEY and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init"then
  assert(p:GetNumGreatWorks()==0 and Players[1]:GetNumGreatWorks()==0)
  local n=0;for r in GameInfo.Trait_GreatWorkYieldChanges{TraitType="TRAIT_WESTERNIZATION"}do assert(not r.GreatWorkClassType and r.YieldChange==1 and(r.YieldType=="YIELD_PRODUCTION"or r.YieldType=="YIELD_GOLD"or r.YieldType=="YIELD_SCIENCE"));n=n+1 end;assert(n==3)
  for r in GameInfo.GreatWorkClasses_Yields()do assert(r.YieldType~="YIELD_PRODUCTION"and r.YieldType~="YIELD_GOLD"and r.YieldType~="YIELD_SCIENCE"or r.Yield==0)end
  local extra=cityInput(p);otherCity=extra:GetID()
  for _,c in ipairs({p:GetCapitalCity(),extra})do for _,name in ipairs(buildingNames)do c:SetNumRealBuilding(GameInfoTypes[name],1)end end
  LekmodScenarioEvent("fixture-setup",{operation="provided-slot-buildings-and-extra-city",city=otherCity,buildings=buildingNames})
  checkYields(p,1);checkYields(Players[1],0);LekmodScenarioRecord("turkey-work-data","PASS","all3null-class Westernization rows are+1Production/Gold/Science; ordinary class base yields contribute none of these")
  phase="create"
 elseif phase=="create"then
  local c=p:GetCapitalCity();local u=assert(p:InitUnit(GameInfoTypes[kinds[index].unit],c:GetX(),c:GetY()));unitID=u:GetID();closed=false;waitFrames=0
  LekmodScenarioEvent("fixture-setup",{operation="provided-Great-Person",unit=unitID,kind=kinds[index].unit});action(u,"MISSION_CREATE_GREAT_WORK");phase="created"
 elseif phase=="created"then
  if not LekmodScenarioAwait("Turkish-work-created",p:GetNumGreatWorks()==index)then return false end
  local u=p:GetUnitByID(unitID);assert(not u or u:IsDead()or u:IsDelayedDeath());assert(discover(p)==1)
  local count=0;for id,r in pairs(tracked)do if r.class==GameInfoTypes[kinds[index].class]then count=count+1 end end;assert(count==1);checkYields(p,1)
  phase="close-work"
 elseif phase=="close-work"then
  waitFrames=waitFrames+1;if waitFrames<8 then return false end
  if not closed then LuaEvents.LekmodCultureCloseGreatWork();return false end
  index=index+1
  if index<=#kinds then phase="create"else
   LekmodScenarioRecord("turkey-native-people-works","PASS","normal Writer/Artist/Musician actions create one work of each class, consume the unit and add one of every target yield; original popup Close callbacks used")
   LekmodScenarioGrantTech(p,"TECH_ARCHAEOLOGY");digStarted=Game.GetGameTurn();phase="dig-ready";return "turn"
  end
 elseif phase=="dig-ready"then
  if Game.GetGameTurn()==digStarted then return "turn"end
  local q
  for i=0,Map.GetNumPlots()-1 do local t=Map.GetPlotByIndex(i)
   if t:GetResourceType(p:GetTeam())==GameInfoTypes.RESOURCE_ARTIFACTS and not t:HasWrittenArtifact()and not t:IsWater()and not t:IsMountain()and t:GetNumUnits()==0 and t:GetImprovementType()==-1 and(t:GetOwner()==-1 or t:GetOwner()==0)and t:GetArchaeologyArtifactPlayer1()>=0 and t:CanBuild(GameInfoTypes.BUILD_ARCHAEOLOGY_DIG,0,false,true)then q=t;break end
  end
  assert(q,"no natural ordinary archaeology site");digIndex=q:GetPlotIndex();local u=assert(p:InitUnit(GameInfoTypes.UNIT_ARCHAEOLOGIST,q:GetX(),q:GetY()));unitID=u:GetID();assert(u:CanBuild(q,GameInfoTypes.BUILD_ARCHAEOLOGY_DIG));answered=nil
  LekmodScenarioEvent("fixture-setup",{operation="provided-Archaeologist-at-natural-site",unit=unitID,plot=digIndex,era=q:GetArchaeologyArtifactEra(),origin=q:GetArchaeologyArtifactPlayer1()});LuaEvents.LekmodArchaeologyChoice("artifact",unitID,q:GetX(),q:GetY());action(u,"BUILD_ARCHAEOLOGY_DIG");digStarted=Game.GetGameTurn();phase="digging"
 elseif phase=="digging"then
  local q=Map.GetPlotByIndex(digIndex)
  if answered then phase="artifact";return false end
  local pendingPlot=p:GetNextDigCompletePlot()
  if pendingPlot then
   assert(digComplete and pendingPlot:GetPlotIndex()==digIndex)
   if p:GetEndTurnBlockingType()~=EndTurnBlockingTypes.ENDTURN_BLOCKING_CHOOSE_ARCHAEOLOGY then return "turn"end
   UI.ActivateNotification(p:GetEndTurnBlockingNotificationIndex());phase="artifact-choice";return false
  end
  local u=assert(p:GetUnitByID(unitID));assert(u:GetBuildType()==GameInfoTypes.BUILD_ARCHAEOLOGY_DIG and u:GetPlot():GetPlotIndex()==digIndex)
  assert(Game.GetGameTurn()-digStarted<7,"dig exceeded bounded owner rounds");return "turn"
 elseif phase=="artifact-choice"then
  if answered then phase="artifact"end;return false
 elseif phase=="artifact"then
  local u=p:GetUnitByID(unitID);if not LekmodScenarioAwait("Turkish-artifact-unit-consumed",not u or u:IsDead()or u:IsDelayedDeath())then return false end
  assert(digComplete and answered.kind=="artifact"and p:GetNumGreatWorks()==4 and discover(p)==1)
  local classes={};for id,r in pairs(tracked)do classes[r.class]=true end;for row in GameInfo.GreatWorkClasses()do assert(classes[row.ID],"a configured Great Work class was not created")end
  assert(Map.GetPlotByIndex(digIndex):GetResourceType(-1)~=GameInfoTypes.RESOURCE_ARTIFACTS);checkYields(p,1);checkYields(Players[1],0)
  LekmodScenarioRecord("turkey-native-artifact","PASS","real dig completion and original artifact selection/confirmation produce the fourth class and consume Archaeologist/site")
  LekmodScenarioRecord("turkey-four-class-yields","PASS","all4actual work classes each contribute exactly+1Production/+1Gold/+1Science under Turkey; Rome remains zero")
  phase="move"
 elseif phase=="move"then
  if pending then
   local found=false;for _,r in ipairs(slots(p))do if r.work==pending.work and r.city==otherCity then found=true end end
   if not LekmodScenarioAwait("Turkish-work-moved",found)then return false end;pending=nil;checkYields(p,1)
  end
  local all=slots(p)
  for _,r in ipairs(all)do if r.work>=0 and r.city~=otherCity then
   local destination;for _,to in ipairs(all)do if to.city==otherCity and to.kind==r.kind and to.work==-1 then destination=to;break end end
   assert(destination);pending={work=r.work};Network.SendMoveGreatWorks(0,r.city,r.class,r.slot,otherCity,destination.class,destination.slot);return false
  end end
  local target=assert(p:GetCityByID(otherCity));assert(target:GetNumGreatWorks()==4 and p:GetCapitalCity():GetNumGreatWorks()==0);checkYields(p,1)
  LekmodScenarioRecord("turkey-work-movement","PASS","original great-work move commands transfer all4classes and their yields to the second city; capital contribution becomes0")
  local q=target:Plot();Players[1]:AcquireCity(target,false,true);local taken=assert(q:GetPlotCity());assert(taken:GetOwner()==1 and taken:GetNumGreatWorks()==4 and Players[1]:GetNumGreatWorks()==4 and p:GetNumGreatWorks()==0);checkYields(Players[1],0);checkYields(p,1)
  for id in pairs(tracked)do assert(Game.GetGreatWorkController(id)==1)end
  LekmodScenarioRecord("turkey-foreign-owner","PASS","native trade-API city acquisition preserves all4works but Rome receives no Turkish Production/Gold/Science modifier")
  p:AcquireCity(taken,false,true);local back=assert(q:GetPlotCity());assert(back:GetOwner()==0 and back:GetNumGreatWorks()==4 and p:GetNumGreatWorks()==4 and Players[1]:GetNumGreatWorks()==0);checkYields(p,1);checkYields(Players[1],0)
  for id in pairs(tracked)do assert(Game.GetGreatWorkController(id)==0)end
  LekmodScenarioRecord("turkey-returned-owner","PASS","returning the city restores exactly4Production/4Gold/4Science from the same work IDs without stacking")
  LekmodScenarioEvent("native-Turkey-work-yields",LekmodScenario.snapshot(p));return true
 end
 return false
end
