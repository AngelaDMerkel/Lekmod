-- Native method surface: GameCore
-- The authentic failed capture/gift save must be repaired by the real load event.
-- Expected marker/modifier changes are declared in the plan. Production progress,
-- city identity/disposition/resistance and other owners remain unchanged.
LekmodScenario={name="moors-acquisition-load",items={"moors-loaded-era-repair","moors-loaded-production-preserved","moors-loaded-next-owner-turn"}}
local phase,turns="init",0
local marker=GameInfoTypes.BUILDING_MOORS_TRAIT2
local function cityState(c)
 return {x=c:GetX(),y=c:GetY(),marker=c:GetNumRealBuilding(marker),market_modifier=c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_MARKET),wonder_modifier=c:GetBuildingProductionModifier(GameInfoTypes.BUILDING_GREAT_LIBRARY),market=c:GetNumRealBuilding(GameInfoTypes.BUILDING_MARKET),puppet=c:IsPuppet(),resistance=c:GetResistanceTurns(),production=c:GetProductionTimes100()}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,2 do local p=Players[id];local cities={};for c in p:Cities()do cities[c:GetID()]=cityState(c)end
  owners[id]={civilization=p:GetCivilizationType(),era=p:GetCurrentEra(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
GameEvents.PlayerDoTurn.Add(function(owner)if owner==1 then turns=turns+1 end end)
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MOORS and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MOORS)
 if phase=="init"then
  assert(LekmodScenarioJSON(LekmodScenario.snapshot(player))==LekmodScenarioParameters.expected_state,"load repair differs from declared marker/modifier-only correction")
  LekmodScenarioRecord("moors-loaded-era-repair","PASS","native load callback repairs the actual stale acquisition checkpoint before any scenario mutation")
  LekmodScenarioRecord("moors-loaded-production-preserved","PASS","saved production progress, city identities/disposition/resistance and other-owner state match exactly; no production refund")
  phase="turn";return "turn"
 end
 if turns==0 then return "turn"end
 for owner=0,2 do local p=Players[owner];local n=0
  if p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MOORS then
   if p:GetCurrentEra()==GameInfoTypes.ERA_MEDIEVAL then n=2 elseif p:GetCurrentEra()==GameInfoTypes.ERA_RENAISSANCE then n=1 end
  end
  for c in p:Cities()do assert(c:GetNumRealBuilding(marker)==n,"next owner turn stacked or lost era marker")end
 end
 LekmodScenarioRecord("moors-loaded-next-owner-turn","PASS","actual subsequent recipient owner turn remains idempotent; foreign control unmarked")
 return true
end
