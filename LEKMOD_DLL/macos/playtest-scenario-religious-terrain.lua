-- Resources are supplied before legal city founding so native ownership
-- applies. Workers build normally; citizen assignments use normal city tasks.
LekmodScenario={name="religious-terrain",items={"luxury-faith-class-gate","luxury-faith-owner-control","worked-luxury-faith","pasture-native-builds","israel-pasture-culture","roman-pasture-control","pasture-city-culture","luxury-faith-settlement"}}
local phase,records,issued,events,ledger="init",{}, {},{},nil
local pasture=GameInfoTypes.BUILD_PASTURE
local function stage(owner,kind,worker)
 local p=Players[owner];local resource=GameInfo.Resources[kind];local center,plot
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:GetResourceType(-1)==-1 and p:CanFound(q:GetX(),q:GetY())then
   for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d)
    if a and a:GetOwner()==-1 and not a:IsWater()and not a:IsMountain()and a:GetFeatureType()==-1 and a:GetResourceType(-1)==-1 and a:GetImprovementType()==-1 and a:GetNumUnits()==0 and a:CanHaveResource(resource.ID,false)then center,plot=q,a;break end
   end
   if center then break end
  end
 end
 assert(center,"no legal city/resource pair for "..owner.."/"..kind)
 assert(plot:CalculateYield(YieldTypes.YIELD_FAITH,false)==0)
 plot:SetResourceType(resource.ID,1);p:Found(center:GetX(),center:GetY());local c=assert(center:GetPlotCity())
 assert(plot:GetOwner()==owner,"native founding did not claim supplied resource plot")
 local r={owner=owner,city=c:GetID(),plot=plot:GetPlotIndex(),resource=kind,worker=worker,index=c:GetCityPlotIndex(plot)};records[#records+1]=r
 LekmodScenarioEvent("fixture-setup",{operation="provided-resource-before-legal-city",owner=owner,city=c:GetID(),plot=r.plot,resource=kind,worker=worker})
 return r
end
local function assign(r,network)
 local c=assert(Players[r.owner]:GetCityByID(r.city));local q=Map.GetPlotByIndex(r.plot)
 if not c:IsForcedWorkingPlot(q)then
  if network then Network.SendDoTask(c:GetID(),TaskTypes.TASK_CHANGE_WORKING_PLOT,r.index,-1,false,false,false,false)
  else
   c:DoTask(TaskTypes.TASK_CHANGE_WORKING_PLOT,r.index,-1,0)
   -- A first click deselects an automatically worked tile; a second selects it.
   if not c:IsForcedWorkingPlot(q)then c:DoTask(TaskTypes.TASK_CHANGE_WORKING_PLOT,r.index,-1,0)end
  end
 end
end
GameEvents.BuildFinished.Add(function(owner,x,y,improvement)
 for _,r in ipairs(records)do local q=Map.GetPlotByIndex(r.plot)
  if r.worker and r.owner==owner and q:GetX()==x and q:GetY()==y then assert(improvement==GameInfoTypes.IMPROVEMENT_PASTURE);events[r.plot]=true;LekmodScenarioEvent("native-pasture-built",{owner=owner,plot=r.plot})end
 end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if phase~="building"or(owner~=2 and owner~=3)or issued[owner]then return end
 local p=Players[owner];assert(p:IsTurnActive()and not p:IsHuman());issued[owner]=true
 for _,r in ipairs(records)do if r.owner==owner then
  assign(r,false);local c=p:GetCityByID(r.city);local q=Map.GetPlotByIndex(r.plot);assert(c:IsWorkingPlot(q)and c:IsForcedWorkingPlot(q))
  r.before_city_culture=c:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_CULTURE)
  if r.worker then
   local u=assert(p:InitUnit(GameInfoTypes.UNIT_WORKER,q:GetX(),q:GetY()));r.unit=u:GetID()
   LekmodScenarioEvent("fixture-setup",{operation="provided-worker",owner=owner,unit=r.unit,plot=r.plot})
   assert(u:CanStartMission(MissionTypes.MISSION_BUILD,pasture,-1,q,0));u:PushMission(MissionTypes.MISSION_BUILD,pasture,-1,0,0,1)
  end
 end end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,3 do local p=Players[owner];local cities,plots={},{}
  for c in p:Cities()do
   cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),terrain_faith=c:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_FAITH),terrain_culture=c:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_CULTURE)}
   for i=1,c:GetNumCityPlots()-1 do local q=c:GetCityIndexPlot(i);local working=q and q:GetWorkingCity()
    if q and q:GetOwner()==owner and working and working:GetID()==c:GetID()and working:GetOwner()==owner and q:GetResourceType(-1)~=-1 then plots[q:GetPlotIndex()]={resource=q:GetResourceType(-1),improvement=q:GetImprovementType(),faith=q:CalculateYield(YieldTypes.YIELD_FAITH,false),culture=q:CalculateYield(YieldTypes.YIELD_CULTURE,false),worked=c:IsWorkingPlot(q),forced=c:IsForcedWorkingPlot(q)}end
   end
  end
  owners[owner]={faith=p:GetFaith(),faith_rate=p:GetTotalFaithPerTurn(),cities=cities,plots=plots}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ISRAEL and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_JERUSALEM and Players[3]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
  for _,owner in ipairs({0,2,3})do LekmodScenarioGrantTech(Players[owner],"TECH_ANIMAL_HUSBANDRY");LekmodScenarioGrantTech(Players[owner],"TECH_MINING");Players[owner]:ChangeGold(500);LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep",owner=owner,gold_added=500})end
  local human=stage(0,"RESOURCE_COW",true);stage(3,"RESOURCE_COW",true);stage(2,"RESOURCE_GEMS",false);stage(2,"RESOURCE_COW",false);stage(3,"RESOURCE_GEMS",false)
  for _,r in ipairs(records)do local q=Map.GetPlotByIndex(r.plot);local expected=r.owner==2 and r.resource=="RESOURCE_GEMS"and 1 or 0
   assert(q:CalculateYield(YieldTypes.YIELD_FAITH,false)==expected,"resource-class faith differs")
   assert(q:CalculateYield(YieldTypes.YIELD_CULTURE,false)==0)
  end
  LekmodScenarioRecord("luxury-faith-class-gate","PASS","Jerusalem raw Gems luxury gives +1 faith; Cow bonus resource gives zero")
  LekmodScenarioRecord("luxury-faith-owner-control","PASS","Roman raw Gems gives no faith; resource ownership came from legal founding")
  assign(human,true);phase="human-assigned"
 elseif phase=="human-assigned"then
  local r=records[1];local q=Map.GetPlotByIndex(r.plot);local c=player:GetCityByID(r.city)
  if not c:IsWorkingPlot(q)and not c:IsForcedWorkingPlot(q)and not r.reselected then
   r.reselected=true;assign(r,true);return false
  end
  if not LekmodScenarioAwait("pasture-human-assignment",c:IsWorkingPlot(q)and c:IsForcedWorkingPlot(q))then return false end
  r.before_city_culture=c:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_CULTURE)
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_WORKER,q:GetX(),q:GetY()));r.unit=u:GetID();LekmodScenarioEvent("fixture-setup",{operation="provided-human-worker",unit=r.unit,plot=r.plot})
  assert(u:CanBuild(q,pasture));UI.SelectUnit(u);local action;for id=0,#GameInfoActions do if GameInfoActions[id]and GameInfoActions[id].Type=="BUILD_PASTURE"then action=id;break end end
  assert(action and Game.CanHandleAction(action));Game.HandleAction(action);phase="building";return "turn"
 elseif phase=="building"then
  if not issued[2]or not issued[3]then return "turn"end
  for _,r in ipairs(records)do if r.worker and not events[r.plot]then return "turn"end end
  for _,r in ipairs(records)do local c=Players[r.owner]:GetCityByID(r.city);local q=Map.GetPlotByIndex(r.plot)
   assert(c:IsWorkingPlot(q)and c:IsForcedWorkingPlot(q),"normal forced plot assignment was lost")
   if r.worker then
    local expected=r.owner==0 and 1 or 0
    assert(q:GetImprovementType()==GameInfoTypes.IMPROVEMENT_PASTURE and q:CalculateYield(YieldTypes.YIELD_CULTURE,false)==expected)
    assert(c:IsHasResourceLocal(GameInfoTypes.RESOURCE_COW,false),"completed Pasture did not connect its Cow resource")
    assert(c:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_CULTURE)==r.before_city_culture+expected,"worked city culture did not update")
   elseif r.owner==2 and r.resource=="RESOURCE_GEMS"then assert(c:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_FAITH)==1,"worked luxury faith missing from city")end
  end
  LekmodScenarioRecord("worked-luxury-faith","PASS","normal city task works Gems; Jerusalem city terrain faith =1")
  LekmodScenarioRecord("pasture-native-builds","PASS","normal human action/AI owner-turn mission and real BuildFinished for both workers; no build progress supplied")
  LekmodScenarioRecord("israel-pasture-culture","PASS","Israel worked Cow Pasture supplies one culture")
  LekmodScenarioRecord("roman-pasture-control","PASS","Roman Cow Pasture supplies zero culture")
  LekmodScenarioRecord("pasture-city-culture","PASS","worked-city terrain culture updated by the same 1/0 owner deltas")
  ledger={turn=Game.GetGameTurn(),faith=Players[2]:GetFaith(),rate=Players[2]:GetTotalFaithPerTurn()};assert(ledger.rate>0);LekmodScenarioEvent("Jerusalem-faith-ledger-before",ledger);phase="settlement";return "turn"
 elseif phase=="settlement"then
  if Game.GetGameTurn()==ledger.turn then return "turn"end
  assert(Game.GetGameTurn()==ledger.turn+1)
  LekmodScenarioEvent("Jerusalem-faith-ledger-after",{faith=Players[2]:GetFaith(),rate=Players[2]:GetTotalFaithPerTurn()})
  assert(Players[2]:GetFaith()==ledger.faith+ledger.rate,"ordinary faith settlement differs from quote")
  LekmodScenarioRecord("luxury-faith-settlement","PASS","native empire faith increased by quoted "..ledger.rate.." over one ordinary turn")
  return true
 end
 return false
end
