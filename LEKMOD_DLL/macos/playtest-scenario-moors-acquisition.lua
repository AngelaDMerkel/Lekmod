-- Native method surface: GameCore
-- City founding, tech, attack units/resources and near-complete hammers are inputs.
-- Actual gift/capture and production events must apply the all-cities era bonus.
local mode=assert(LekmodScenarioParameters.mode)
local era=assert(LekmodScenarioParameters.era)
LekmodScenario={name="moors-acquisition",items={"moors-acquisition-event","moors-immediate-era-bonus","moors-previous-owner-control","moors-next-owner-update","moors-production-modifiers","moors-production-completion"}}
local marker=GameInfoTypes.BUILDING_MOORS_TRAIT2
local targetBuilding=GameInfoTypes.BUILDING_MARKET
local phase,oldOwner,newOwner,target,captured,proposed,accepted,closed,sent,queued,constructed="init"
local captureCounter,ownerCounter=0,{}
local amount=era=="medieval"and 2 or 1
local isGift=mode=="gift-in"or mode=="gift-out"
local function cityState(c)
 return {x=c:GetX(),y=c:GetY(),marker=c:GetNumRealBuilding(marker),market_modifier=c:GetBuildingProductionModifier(targetBuilding),wonder_modifier=c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_GREAT_LIBRARY),market=c:GetNumRealBuilding(targetBuilding),puppet=c:IsPuppet(),resistance=c:GetResistanceTurns(),production=c:GetProductionTimes100()}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,2 do local p=Players[id];local cities={};for c in p:Cities()do cities[c:GetID()]=cityState(c)end
  owners[id]={civilization=p:GetCivilizationType(),era=p:GetCurrentEra(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function at()return assert(Map.GetPlot(target.x,target.y):GetPlotCity())end
LuaEvents.LekmodRomaniaCityGiftProposed.Add(function()proposed=true end)
LuaEvents.LekmodRomaniaCityGiftAccepted.Add(function()accepted=true end)
LuaEvents.LekmodScenarioDiplomacyResponse.Add(function(kind)if kind=="closed"then closed=true end end)
GameEvents.CityCaptureComplete.Add(function(old,capital,x,y,new,pop,conquest)
 if target and x==target.x and y==target.y then
  assert(old==oldOwner and new==newOwner and not capital and conquest==not isGift)
  captured={old=old,new=new,conquest=conquest,state=cityState(at())};captureCounter=ownerCounter[newOwner]or 0
  LekmodScenarioEvent("native-Moorish-acquisition",captured)
 end
end)
GameEvents.CityConstructed.Add(function(owner,city,building,gold,faith)
 if target and owner==newOwner and building==targetBuilding and at():GetID()==city then
  assert(not gold and not faith);constructed=true;LekmodScenarioEvent("native-acquired-city-production",{owner=owner,city=city,building=building})
 end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 ownerCounter[owner]=(ownerCounter[owner]or 0)+1
 if owner~=newOwner then return end
 local p=Players[owner];assert(not p:IsHuman()and p:IsTurnActive())
 if phase=="capture"and not sent then
  local c=at();local tile
  for d=0,5 do local q=Map.PlotDirection(c:GetX(),c:GetY(),d)
   if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then tile=q;break end
  end
  assert(tile);p:ChangeGold(1000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
  local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,tile:GetX(),tile:GetY()))
  LekmodScenarioEvent("fixture-setup",{operation="provided-AI-attacker",owner=owner,unit=u:GetID(),gold_added=1000,uranium_added=1,x=tile:GetX(),y=tile:GetY()})
  assert(u:CanMoveOrAttackInto(c:Plot()));sent=true;u:PushMission(MissionTypes.MISSION_MOVE_TO,c:GetX(),c:GetY(),0,0,1)
 elseif phase=="production"and not queued then
  local c=at();assert(c:GetOwner()==newOwner)
  if c:IsPuppet()then c:DoTask(TaskTypes.TASK_ANNEX_PUPPET,-1,-1,0)end
  if c:IsResistance()then return end
  local n=newOwner==1 and amount or 0
  assert((ownerCounter[owner]or 0)>captureCounter and c:GetNumRealBuilding(marker)==n)
  LekmodScenarioRecord("moors-next-owner-update","PASS","distinct actual recipient turn retains current-owner era marker="..n)
  assert(c:GetBuildingProductionModifier(targetBuilding)==n*15 and c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_GREAT_LIBRARY)==0)
  LekmodScenarioRecord("moors-production-modifiers","PASS","ordinary Market modifier="..(n*15).." percent; wonder modifier0")
  assert(c:GetNumRealBuilding(targetBuilding)==0 and c:CanConstruct(targetBuilding,c:GetProductionBuilding()==targetBuilding and 1 or 0))
  if c:GetProductionBuilding()~=targetBuilding then c:PushOrder(OrderTypes.ORDER_CONSTRUCT,targetBuilding,-1,0,true,false,0)end
  assert(c:GetProductionBuilding()==targetBuilding)
  local cost=c:GetBuildingProductionNeeded(targetBuilding);assert(cost>1);c:SetBuildingProduction(targetBuilding,cost-1);queued=true
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-Market",owner=owner,city=c:GetID(),hammers=cost-1,cost=cost,quoted_production100=c:GetCurrentProductionDifferenceTimes100(false,false)})
 end
end)
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MOORS and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MOORS and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init"then
  for id=0,2 do if not Players[id]:GetCapitalCity()then return "turn"end end
  assert(player:GetCurrentEra()==GameInfoTypes.ERA_MEDIEVAL and Players[1]:GetCurrentEra()==GameInfoTypes.ERA_MEDIEVAL)
  if era=="renaissance"then
   LekmodScenarioGrantTech(player,"TECH_ACOUSTICS");LekmodScenarioGrantTech(Players[1],"TECH_ACOUSTICS")
  else assert(era=="medieval")end
  oldOwner=mode=="capture-in"and 2 or 0;newOwner=(mode=="capture-in"or mode=="gift-in")and 1 or 2
  local p=Players[oldOwner];local home=Players[newOwner]:GetCapitalCity();local q
  for i=0,Map.GetNumPlots()-1 do local tile=Map.GetPlotByIndex(i)
   if tile:GetOwner()==-1 and tile:GetNumUnits()==0 and Map.PlotDistance(home:GetX(),home:GetY(),tile:GetX(),tile:GetY())<=10 and p:CanFound(tile:GetX(),tile:GetY())then q=tile;break end
  end
  assert(q);p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());assert(not c:IsCapital());target={id=c:GetID(),x=q:GetX(),y=q:GetY()}
  local original=oldOwner==0 and amount or 0;assert(c:GetNumRealBuilding(marker)==original and c:GetNumRealBuilding(targetBuilding)==0)
  LekmodScenarioEvent("fixture-setup",{operation="provided-secondary-city",owner=oldOwner,city=target,era=era,initial_marker=original})
  Teams[p:GetTeam()]:Meet(Players[newOwner]:GetTeam(),true)
  if isGift then
   LuaEvents.LekmodRomaniaCityGift({player=newOwner,city=target.id,x=target.x,y=target.y});LuaEvents.LekmodScenarioDiplomacyOpen(newOwner);phase="gift"
  else
   assert(Teams[Players[newOwner]:GetTeam()]:CanDeclareWar(p:GetTeam()));Teams[Players[newOwner]:GetTeam()]:DeclareWar(p:GetTeam())
   LekmodScenarioEvent("fixture-setup",{operation="provided-AI-war",old=oldOwner,new=newOwner});phase="capture";return "turn"
  end
 elseif phase=="capture"or phase=="gift"then
  if not captured then if not isGift then return "turn"end;return false end
  if isGift and not closed then return false end
  if isGift then assert(proposed and accepted)end
  assert(at():GetOwner()==newOwner and Players[oldOwner]:IsAlive()and Game.GetWinner()==-1)
  LekmodScenarioRecord("moors-acquisition-event","PASS",isGift and"original city-gift/propose/AI-reply callbacks and non-conquest event"or"normal AI-owner-turn combat and conquest event")
  local n=newOwner==1 and amount or 0
  assert(captured.state.marker==n and captured.state.market_modifier==n*15,"immediate acquired-city bonus expected="..n.."/"..(n*15).." actual="..captured.state.marker.."/"..captured.state.market_modifier)
  assert(captured.state.wonder_modifier==0)
  LekmodScenarioRecord("moors-immediate-era-bonus","PASS","capture-event state already matches current owner: marker="..n.." ordinary building modifier="..(n*15))
  assert(player:GetCapitalCity():GetNumRealBuilding(marker)==amount and Players[2]:GetCapitalCity():GetNumRealBuilding(marker)==0)
  LekmodScenarioRecord("moors-previous-owner-control","PASS","remaining Moorish home capital keeps era benefit; Roman capital remains unmarked")
  phase="production";return "turn"
 elseif phase=="production"then
  if not constructed then return "turn"end
  local c=at();assert(queued and c:GetNumRealBuilding(targetBuilding)==1 and not c:CanConstruct(targetBuilding))
  assert(c:GetNumRealBuilding(marker)==(newOwner==1 and amount or 0))
  LekmodScenarioRecord("moors-production-completion","PASS","unforced ordinary owner-turn production completed Market; duplicate rejected; ownership marker intact")
  return true
 end
 return false
end
