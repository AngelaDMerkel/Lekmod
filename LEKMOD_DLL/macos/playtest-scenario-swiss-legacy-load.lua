-- Native method surface: GameCore
-- Read-only old-package save check. No units, promotions, moves or turns supplied.
LekmodScenario={name="swiss-legacy-load",items={"mountaineer-old-save-terrain","mountaineer-old-save-moves","mountaineer-old-save-control"}}
local base,active=GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER,GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER_ACTIVE
function LekmodScenario.snapshot(player)
 local owners={}
 for _,owner in ipairs({0,3})do local units={}
  for u in Players[owner]:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),maximum=u:MaxMoves(),base=u:IsHasPromotion(base),active=u:IsHasPromotion(active)}end end
  owners[owner]={civilization=Players[owner]:GetCivilizationType(),units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SPAIN and Players[3]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SWISS)
 local p=Players[3];local trained=assert(p:GetUnitByID(32770));local reward=assert(p:GetUnitByID(24576))
 assert(trained:GetUnitType()==GameInfoTypes.UNIT_LONGSWORDSMAN and trained:GetX()==77 and trained:GetY()==13)
 assert(reward:GetUnitType()==GameInfoTypes.UNIT_SWISS_REISLAUFER and reward:GetX()==30 and reward:GetY()==17)
 for _,u in ipairs({trained,reward})do
  assert(u:IsHasPromotion(base));assert(u:IsHasPromotion(active)==u:IsNearTerrainType(GameInfoTypes.TERRAIN_MOUNTAIN,1,false))
 end
 local repairs=(trained:IsHasPromotion(active)and 1 or 0)+(reward:IsHasPromotion(active)and 0 or 1)
 LekmodScenarioRecord("mountaineer-old-save-terrain","PASS","loaded old-package terrain state matches actual saved positions; changed derived flags="..repairs)
 assert(trained:GetMoves()==120 and reward:GetMoves()==240)
 LekmodScenarioRecord("mountaineer-old-save-moves","PASS","old saved current movement remains120/240; load does not refund movement")
 local control=assert(player:GetUnitByID(32770));assert(control:GetUnitType()==GameInfoTypes.UNIT_LONGSWORDSMAN and not control:IsHasPromotion(base)and not control:IsHasPromotion(active)and control:GetMoves()==120)
 LekmodScenarioRecord("mountaineer-old-save-control","PASS","unpromoted Spanish saved Longswordsman remains unchanged")
 LekmodScenarioEvent("old-swiss-save-state",LekmodScenario.snapshot(player));return true
end
