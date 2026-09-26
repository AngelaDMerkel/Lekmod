-- Native method surface: GameCore
-- Exact old-package failure save. No supplied state: inspect load reconciliation,
-- then issue one normal movement command using only the saved remaining moves.
LekmodScenario={name="swiss-migration-load",items={"mountaineer-saved-repair","mountaineer-saved-no-refund","mountaineer-saved-control","mountaineer-repaired-move"}}
local phase,target,budget="init"
local base,active=GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER,GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER_ACTIVE
function LekmodScenario.snapshot(player)
 local units={}
 for u in player:Units()do if u:IsHasPromotion(base)and not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),maximum=u:MaxMoves(),base=u:IsHasPromotion(base),active=u:IsHasPromotion(active)}end end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),units=units}
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SWISS and Game.GetGameTurn()==4)
 local u=assert(player:GetUnitByID(40963));assert(u:GetUnitType()==GameInfoTypes.UNIT_LONGSWORDSMAN)
 if phase=="init"then
  assert(u:GetX()==73 and u:GetY()==9 and u:IsNearTerrainType(GameInfoTypes.TERRAIN_MOUNTAIN,1,false))
  assert(u:IsHasPromotion(base)and u:IsHasPromotion(active)and u:MaxMoves()==180)
  LekmodScenarioRecord("mountaineer-saved-repair","PASS","exact old failure save loads with formerly missing mountain promotion repaired")
  assert(u:GetMoves()==120);LekmodScenarioRecord("mountaineer-saved-no-refund","PASS","load retains120 saved movement despite corrected maximum180")
  local reward=assert(player:GetUnitByID(32770));assert(reward:GetUnitType()==GameInfoTypes.UNIT_SWISS_REISLAUFER and reward:GetX()==31 and reward:GetY()==12 and reward:IsHasPromotion(base)and not reward:IsHasPromotion(active)and reward:GetMoves()==180 and reward:MaxMoves()==180)
  LekmodScenarioRecord("mountaineer-saved-control","PASS","off-mountain reward preserves original promotion and180 movement")
  LekmodScenarioEvent("repaired-saved-state",LekmodScenario.snapshot(player))
  for d=0,5 do local q=Map.PlotDirection(u:GetX(),u:GetY(),d)
   if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 and u:CanMoveOrAttackInto(q)then target=q;break end
  end
  assert(target,"no legal move for repaired saved unit");budget=u:GetMoves();UI.SelectUnit(u)
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,target:GetX(),target:GetY(),0,false,false);phase="moved"
 else
  if not LekmodScenarioAwait("repaired-unit-move",u:GetX()==target:GetX()and u:GetY()==target:GetY())then return false end
  assert(u:GetMoves()<budget and u:IsHasPromotion(active)==u:IsNearTerrainType(GameInfoTypes.TERRAIN_MOUNTAIN,1,false))
  LekmodScenarioRecord("mountaineer-repaired-move","PASS","normal synchronized move spends saved allowance and keeps terrain bonus consistent")
  return true
 end
 return false
end
