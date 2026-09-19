-- Diagnostic replay of the recorded turn-five fixture. No unit or gameplay
-- value is assigned; allow one ordinary turn, then sample two distinct updates.
LekmodScenario={name="maori-refresh",items={"maori-expired-move-budget"}}
local first
local function units(player)
 local result={}
 for u in player:Units()do
  if u:GetGameTurnCreated()==5 and (u:GetUnitType()==GameInfoTypes.UNIT_WARRIOR or u:GetUnitType()==GameInfoTypes.UNIT_WORKER)then
   result[u:GetID()]={type=u:GetUnitType(),created=u:GetGameTurnCreated(),moves=u:GetMoves(),maximum=u:MaxMoves(),sight=u:VisibilityRange(),maori=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI),civilian=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN),x=u:GetX(),y=u:GetY()}
  end
 end
 return result
end
function LekmodScenario.snapshot(player)return {turn=Game.GetGameTurn(),units=units(player)}end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI)
 local turn=Game.GetGameTurn();assert(turn==5 or turn==6,"load the recorded turn-five fixture")
 if turn==5 then return "turn" end
 local s=LekmodScenario.snapshot(player)
 if not first then first=s;LekmodScenarioEvent("maori-first-turn-six-observation",s);return false end
 LekmodScenarioEvent("maori-stable-turn-six-observation",s)
 local count,excess=0,0
 for id,u in pairs(s.units)do
  count=count+1;assert(first.units[id] and u.moves==first.units[id].moves and u.maximum==first.units[id].maximum,"movement changed between read-only observations")
  assert(not u.maori and not u.civilian and u.maximum==120 and u.sight==2,"expired promotion/limit fixture differs")
  if u.moves~=u.maximum then excess=excess+1 end
 end
 assert(count>=2,"missing both late-created test units")
 LekmodScenarioRecord("maori-expired-move-budget",excess==0 and "PASS" or "FAIL","stable-samples=2 late-units="..count.." unequal-remaining-and-maximum="..excess)
 return true
end
