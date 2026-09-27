-- Native method surface: GameCore
-- Load the authentic pre-fix failed checkpoint. No setup mutation precedes the
-- protected-state check. The repaired count must not refund old costs or moves.
LekmodScenario={name="mughal-garrison-load",items={"garrison-loaded-unrelated-state","garrison-loaded-cache-repair","garrison-loaded-cache-control","garrison-loaded-next-turn"}}
local building=GameInfoTypes.BUILDING_MUGHALS_CARAVANSARY
local phase,treasury="init",nil
local function protected(p)
 local units,cities={},{}
 for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),garrison=u:IsGarrisoned()}end end
 for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),building=c:GetNumRealBuilding(building),ordinary=c:GetNumRealBuilding(GameInfoTypes.BUILDING_CARAVANSARY),strength=c:GetStrengthValue(false)}end
 return {turn=Game.GetGameTurn(),owners={[0]={units=units,cities=cities,gold=p:GetGold()}}}
end
function LekmodScenario.snapshot(p)
 return {protected=protected(p),free=p:GetNumMaintenanceFreeUnits(-1,false),cost=p:CalculateUnitCost(),rate100=p:CalculateGoldRateTimes100()}
end
function LekmodScenario.step(p)
 assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MUGHALS)
 local c=assert(p:GetCapitalCity());assert(c:GetNumRealBuilding(building)==1)
 if phase=="init"then
  assert(LekmodScenarioJSON(protected(p))==LekmodScenarioParameters.expected_state,"repair changed unrelated saved gold/units/cities/movement")
  LekmodScenarioRecord("garrison-loaded-unrelated-state","PASS","all saved unit identities/positions/moves, city state/strength and treasury preserved before mutation")
  assert(p:GetNumMaintenanceFreeUnits(-1,false)==1,"old cached zero not repaired")
  assert(p:CalculateUnitCost()==6,"14-unit fixture with one exemption should cost6 rather than pre-fix7")
  LekmodScenarioRecord("garrison-loaded-cache-repair","PASS","authentic failed checkpoint now has one exemption and cost6; no old treasury refund")
  c:SetNumRealBuilding(building,0);assert(p:GetNumMaintenanceFreeUnits(-1,false)==0 and p:CalculateUnitCost()==7)
  c:SetNumRealBuilding(building,1);assert(p:GetNumMaintenanceFreeUnits(-1,false)==1 and p:CalculateUnitCost()==6)
  assert(LekmodScenarioJSON(protected(p))==LekmodScenarioParameters.expected_state)
  LekmodScenarioRecord("garrison-loaded-cache-control","PASS","matched removal/restore changes count once; unrelated saved state remains exact")
  treasury={turn=Game.GetGameTurn(),gold=p:GetGold(),rate100=p:CalculateGoldRateTimes100()};phase="settle";return "turn"
 end
 if Game.GetGameTurn()==treasury.turn then return "turn"end
 assert(Game.GetGameTurn()==treasury.turn+1)
 assert(p:GetGold()==math.floor((treasury.gold*100+treasury.rate100)/100),"post-repair ordinary gold settlement differs from quote")
 assert(p:GetNumMaintenanceFreeUnits(-1,false)==1)
 LekmodScenarioRecord("garrison-loaded-next-turn","PASS","ordinary next-turn upkeep uses repaired exemption and exact quoted treasury settlement")
 return true
end
