-- Extra human city, research and a strong staged AI attacker are inputs.
-- Occupation must follow a real attack/capture; resistance expires ordinarily.
LekmodScenario={name="jerusalem-outremer",items={"outremer-peaceful-gate","outremer-real-capture","outremer-annexed-eligibility","outremer-production","outremer-occupation-relief","outremer-yields"}}
local phase,x,y,sent,captured,queued,built,before="init",nil,nil,false,false,false,false,nil
local building=GameInfoTypes.BUILDING_OUTREMER
local function yields(c)
 local p=Players[c:GetOwner()];local values={}
 for _,kind in ipairs({YieldTypes.YIELD_CULTURE,YieldTypes.YIELD_FAITH})do
  local policy=0;for b in GameInfo.Buildings()do policy=policy+c:GetNumBuilding(b.ID)*p:GetPolicyBuildingClassYieldChange(GameInfoTypes[b.BuildingClass],kind)end
  values[kind]=c:GetBaseYieldRateFromBuildings(kind)-policy
 end
 return values
end
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,3 do local p=Players[owner];local cities={}
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),original=c:GetOriginalOwner(),capital=c:IsCapital(),occupied=c:IsOccupied(),puppet=c:IsPuppet(),resistance=c:GetResistanceTurns(),relief=c:IsNoOccupiedUnhappiness(),outremer=c:GetNumRealBuilding(building),yields=yields(c)}end
  owners[owner]={cities=cities,gold=p:GetGold(),faith=p:GetFaith(),happiness=p:GetExcessHappiness()}
 end
 return {turn=Game.GetGameTurn(),war=Teams[Players[0]:GetTeam()]:IsAtWar(Players[2]:GetTeam()),owners=owners}
end
GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,pop,conquest)
 if old==0 and new==2 and cx==x and cy==y then
  assert(capital and conquest and sent);captured=true
  LekmodScenarioEvent("native-Outremer-capture",{old=old,new=new,x=cx,y=cy,population=pop,conquest=conquest,capital=capital})
 end
end)
GameEvents.CityConstructed.Add(function(owner,city,b,gold,faith)
 if owner==2 and b==building then assert(not gold and not faith);built=true;LekmodScenarioEvent("native-Outremer-production",{owner=owner,city=city})end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=2 then return end
 local p=Players[owner]
 if phase=="capture"and not sent then
  assert(not p:IsHuman()and p:IsTurnActive());local c=assert(Map.GetPlot(x,y):GetPlotCity());local tile
  for d=0,5 do local q=Map.PlotDirection(x,y,d)
   if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then tile=q;break end
  end
  assert(tile);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1);p:ChangeGold(1000)
  local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,tile:GetX(),tile:GetY()))
  LekmodScenarioEvent("fixture-setup",{operation="provided-AI-attacker-uranium-and-upkeep",owner=2,unit=u:GetID(),x=tile:GetX(),y=tile:GetY(),gold_added=1000,uranium_added=1})
  assert(u:CanMoveOrAttackInto(c:Plot()));sent=true;u:PushMission(MissionTypes.MISSION_MOVE_TO,x,y,0,0,1)
 elseif phase=="production"and not queued then
  assert(not p:IsHuman()and p:IsTurnActive());local c=assert(Map.GetPlot(x,y):GetPlotCity());assert(c:GetOwner()==2 and c:GetOriginalOwner()==0 and(c:IsPuppet()or c:IsOccupied()))
  if c:IsPuppet()then c:DoTask(TaskTypes.TASK_ANNEX_PUPPET,-1,-1,0);LekmodScenarioEvent("normal-city-task",{operation="annex-captured-puppet",owner=2,city=c:GetID()})end
  assert(not c:IsPuppet()and c:IsOccupied())
  if c:IsResistance()then LekmodScenarioEvent("ordinary-resistance-wait",{turn=Game.GetGameTurn(),remaining=c:GetResistanceTurns()});return end
  assert(not c:IsNoOccupiedUnhappiness()and c:CanConstruct(building,c:GetProductionBuilding()==building and 1 or 0),"annexed captured city not eligible")
  assert(not c:CanConstruct(GameInfoTypes.BUILDING_COURTHOUSE),"default Courthouse bypassed owner replacement")
  LekmodScenarioRecord("outremer-annexed-eligibility","PASS","real occupied city; normal annex if needed; resistance expired ordinarily; default replacement rejected")
  before=yields(c);if c:GetProductionBuilding()~=building then c:PushOrder(OrderTypes.ORDER_CONSTRUCT,building,-1,0,true,false,0)else LekmodScenarioEvent("inherited-Outremer-order",{city=c:GetID()})end
  assert(c:GetProductionBuilding()==building);local cost=c:GetBuildingProductionNeeded(building);assert(cost>1);c:SetBuildingProduction(building,cost-1);queued=true
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-Outremer",owner=2,city=c:GetID(),hammers=cost-1,cost=cost})
 end
end)
function LekmodScenario.step(player)
 local p=Players[2];assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_JERUSALEM)
 if phase=="init"then
  LekmodScenarioGrantTech(p,"TECH_MATHEMATICS")
  assert(not p:GetCapitalCity():IsOccupied()and not p:GetCapitalCity():CanConstruct(building))
  LekmodScenarioRecord("outremer-peaceful-gate","PASS","unoccupied home capital rejects Outremer")
  local site;for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==-1 and q:GetNumUnits()==0 and player:CanFound(q:GetX(),q:GetY())then site=q;break end
  end
  assert(site);player:Found(site:GetX(),site:GetY());assert(player:GetNumCities()==2)
  local c=assert(player:GetCapitalCity());x,y=c:GetX(),c:GetY()
  LekmodScenarioEvent("fixture-setup",{operation="provided-human-survival-city",city=site:GetPlotCity():GetID(),target_original_capital=c:GetID()})
  Teams[player:GetTeam()]:Meet(p:GetTeam(),true);Network.SendChangeWar(p:GetTeam(),true);phase="war"
 elseif phase=="war"then
  if not LekmodScenarioAwait("Outremer-war",Teams[player:GetTeam()]:IsAtWar(p:GetTeam()))then return false end
  phase="capture";return "turn"
 elseif phase=="capture"then
  if not captured then return "turn"end
  local c=assert(Map.GetPlot(x,y):GetPlotCity());assert(c:GetOwner()==2 and c:GetOriginalOwner()==0 and(c:IsPuppet()or c:IsOccupied())and player:IsAlive())
  LekmodScenarioRecord("outremer-real-capture","PASS","AI owner-turn normal move-attack/native CityCaptureComplete; human survives in supplied second city")
  phase="production";return "turn"
 elseif phase=="production"then
  if not built then return "turn"end
  local c=assert(Map.GetPlot(x,y):GetPlotCity());assert(c:GetNumRealBuilding(building)==1 and not c:CanConstruct(building))
  LekmodScenarioRecord("outremer-production","PASS","unforced owner-turn queue/native CityConstructed; duplicate rejected")
  assert(c:IsOccupied()and c:IsNoOccupiedUnhappiness()and not p:GetCapitalCity():IsNoOccupiedUnhappiness())
  LekmodScenarioRecord("outremer-occupation-relief","PASS","captured city retains occupation but gains native unhappiness exemption; home control unchanged")
  local after=yields(c);for kind,value in pairs(before)do assert(after[kind]==value+2,"Outremer yield differs: "..kind)end
  LekmodScenarioRecord("outremer-yields","PASS","culture and faith building contributions +2 after accounting for observed policy yields")
  assert(Game.GetWinner()==-1);return true
 end
 return false
end
