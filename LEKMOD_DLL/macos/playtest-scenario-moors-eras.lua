-- Supplied research and one Settler. Native era events, founding and ordinary
-- turns determine city bonuses; no era or production-modifier value is set.
LekmodScenario={name="moors-eras",items={"moors-Medieval-human-AI","moors-Renaissance-team-isolation","moors-Renaissance-founding","moors-Industrial-expiry","moors-Roman-control"}}
local phase,site="init",nil
local dummy=GameInfoTypes.BUILDING_MOORS_TRAIT2
local function cityState(c)
 return {marker=c:GetNumRealBuilding(dummy),market=c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_MARKET),library=c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_LIBRARY),wonder=c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_GREAT_LIBRARY),x=c:GetX(),y=c:GetY()}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,2 do local cities={};for c in Players[id]:Cities()do cities[c:GetID()]=cityState(c)end
  owners[id]={civilization=Players[id]:GetCivilizationType(),era=Players[id]:GetCurrentEra(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function counts(owner,n)
 local count=0;for c in Players[owner]:Cities()do count=count+1;assert(c:GetNumRealBuilding(dummy)==n,"wrong era marker count for owner "..owner)end;assert(count>0)
end
local function found(player)
 local capital=assert(player:GetCapitalCity());local best=999
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);local distance=Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())
  if distance>=4 and distance<=10 and distance<best and p:GetArea()==capital:Plot():GetArea() and p:GetOwner()==-1 and p:GetNumUnits()==0 and player:CanFound(p:GetX(),p:GetY())then best=distance;site=p end
 end
 assert(site,"no legal expansion site")
 local u=assert(player:InitUnit(GameInfoTypes.UNIT_SETTLER,site:GetX(),site:GetY()))
 LekmodScenarioEvent("fixture-setup",{operation="provided-settler-and-legal-position",id=u:GetID(),x=site:GetX(),y=site:GetY()})
 assert(u:CanFound(site));UI.SelectUnit(u)
 for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_FOUND"then assert(Game.CanHandleAction(i));Game.HandleAction(i);return end end
 error("Found action missing")
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MOORS and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MOORS and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init" then
  if not player:GetCapitalCity() or not Players[1]:GetCapitalCity() or not Players[2]:GetCapitalCity()then return "turn"end
  assert(player:GetCurrentEra()==GameInfoTypes.ERA_MEDIEVAL and Players[1]:GetCurrentEra()==GameInfoTypes.ERA_MEDIEVAL)
  counts(0,2);counts(1,2);counts(2,0)
  LekmodScenarioEvent("moors-native-Medieval",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("moors-Medieval-human-AI","PASS","normal-human-and-AI-founded-capitals markers=2")
  LekmodScenarioGrantTech(player,"TECH_ACOUSTICS");phase="Renaissance"
 elseif phase=="Renaissance" then
  assert(player:GetCurrentEra()==GameInfoTypes.ERA_RENAISSANCE and Players[1]:GetCurrentEra()==GameInfoTypes.ERA_MEDIEVAL)
  counts(0,1);counts(1,2);counts(2,0)
  LekmodScenarioEvent("moors-native-Renaissance",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("moors-Renaissance-team-isolation","PASS","native-era-event human-markers=1 AI-team-stays=2")
  found(player);phase="founded"
 elseif phase=="founded" then
  local c=site:GetPlotCity();if not LekmodScenarioAwait("moorish-Renaissance-expansion",c and c:GetOwner()==player:GetID())then return false end
  local s=cityState(c);LekmodScenarioEvent("moors-native-Renaissance-founded",s)
  assert(s.marker==1 and s.market==15 and s.library==15 and s.wonder==0,"Renaissance founding lacked immediate 15-percent building-only bonus")
  LekmodScenarioRecord("moors-Renaissance-founding","PASS","normal-Found new-city normal-building=15 wonder=0")
  LekmodScenarioGrantTech(player,"TECH_SCIENTIFIC_THEORY");phase="Industrial"
 elseif phase=="Industrial" then
  assert(player:GetCurrentEra()==GameInfoTypes.ERA_INDUSTRIAL);counts(0,0);counts(1,2);counts(2,0)
  LekmodScenarioRecord("moors-Industrial-expiry","PASS","native-era-event clears-all-human-city-markers AI-team-unchanged=true")
  LekmodScenarioGrantTech(Players[2],"TECH_ACOUSTICS");phase="control"
 elseif phase=="control" then
  assert(Players[2]:GetCurrentEra()==GameInfoTypes.ERA_RENAISSANCE);counts(2,0);counts(1,2)
  LekmodScenarioEvent("moors-native-final",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("moors-Roman-control","PASS","Roman-era-event adds-no-Moorish-marker=true")
  return true
 end
 return false
end
