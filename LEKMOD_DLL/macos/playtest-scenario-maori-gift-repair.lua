-- Load the retained affected save. The next real recipient turn must expire
-- inherited promotions; no promotion, movement, owner or turn value is assigned.
LekmodScenario={name="maori-gift-repair",items={"maori-inherited-save-expiry"}}
local startTurn,tracked=nil,{}
local function state(u)
 return {type=u:GetUnitType(),created=u:GetGameTurnCreated(),moves=u:GetMoves(),maximum=u:MaxMoves(),sight=u:VisibilityRange(),maori=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI),civilian=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN),x=u:GetX(),y=u:GetY()}
end
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newID)
 if oldOwner==2 and tracked[oldID]then assert(newOwner==2);tracked[oldID]=nil;tracked[newID]=true end
end)
function LekmodScenario.snapshot(player)
 local units={};for u in Players[2]:Units()do if not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
 return {turn=Game.GetGameTurn(),recipient_civilization=Players[2]:GetCivilizationType(),units=units}
end
function LekmodScenario.step(player)
 assert(Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if not startTurn then
  startTurn=Game.GetGameTurn();assert(Game.GetElapsedGameTurns()>=8)
  local count=0
  for u in Players[2]:Units()do
   if u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI) or u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN)then
    assert(u:GetGameTurnCreated()<startTurn);tracked[u:GetID()]=true;count=count+1
   end
  end
  assert(count==2,"load the preserved affected Warrior/Worker gift save")
  LekmodScenarioEvent("maori-affected-save-before-recipient-turn",LekmodScenario.snapshot(player));return "turn"
 end
 if Game.GetGameTurn()==startTurn then return "turn"end;assert(Game.GetGameTurn()==startTurn+1)
 for id in pairs(tracked)do local u=assert(Players[2]:GetUnitByID(id));local s=state(u)
  LekmodScenarioEvent("maori-affected-save-after-recipient-turn",{id=id,state=s})
  assert(not s.maori and not s.civilian and s.maximum==120 and s.sight==2,"affected save retained inherited bonus after recipient turn")
 end
 LekmodScenarioRecord("maori-inherited-save-expiry","PASS","path=ordinary-recipient-turn affected-units=2 inherited-bonuses-cleared=true")
 return true
end
