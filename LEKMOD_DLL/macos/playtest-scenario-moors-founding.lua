-- Normal Medieval setup and the starting Settler's real Found action. Observe
-- the first playable capital state; no city, marker or production value is set.
LekmodScenario={name="moors-founding",items={"moors-immediate-founded-city-bonus"}}
local phase="init"
local dummy=GameInfoTypes.BUILDING_MOORS_TRAIT2
local function state(c)
 return {id=c:GetID(),x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),marker=c:GetNumRealBuilding(dummy),market_modifier=c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_MARKET),library_modifier=c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_LIBRARY),wonder_modifier=c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_GREAT_LIBRARY)}
end
GameEvents.PlayerCityFounded.Add(function(owner,x,y)
 local c=Map.GetPlot(x,y):GetPlotCity()
 LekmodScenarioEvent("moors-actual-city-founded",{owner=owner,turn=Game.GetGameTurn(),elapsed=Game.GetElapsedGameTurns(),city=state(c)})
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,2 do local cities={};for c in Players[id]:Cities()do cities[c:GetID()]=state(c)end
  owners[id]={civilization=Players[id]:GetCivilizationType(),era=Players[id]:GetCurrentEra(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),elapsed=Game.GetElapsedGameTurns(),owners=owners}
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MOORS and player:GetCurrentEra()==GameInfoTypes.ERA_MEDIEVAL and Game.GetElapsedGameTurns()==0,"requires a new normal Medieval Moorish opening")
 if phase=="init" then
  assert(not player:GetCapitalCity(),"capital already existed before observed founding")
  for u in player:Units()do
   if GameInfo.Units[u:GetUnitType()].Found and u:CanFound(u:GetPlot())then
    UI.SelectUnit(u)
    for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_FOUND"then
     assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="founded";return false
    end end
   end
  end
  error("no legal starting Settler Found action")
 end
 local c=player:GetCapitalCity();if not LekmodScenarioAwait("moorish-capital-founded",c~=nil)then return false end
 local s=state(c);LekmodScenarioEvent("moors-first-playable-capital",s)
 LekmodScenarioRecord("moors-immediate-founded-city-bonus",(s.marker==2 and s.market_modifier==30 and s.library_modifier==30 and s.wonder_modifier==0) and "PASS"or"FAIL","normal-Found Medieval markers="..s.marker.." market-modifier="..s.market_modifier.." library-modifier="..s.library_modifier)
 return true
end
