-- Native method surface: GameCore
local gunboat=GameInfoTypes.POLICY_GUNBOAT_DIPLOMACY
local routeQuest=MinorCivQuestTypes.MINOR_CIV_QUEST_ROUTE
local kind=assert(LekmodScenarioParameters.kind)
local withPolicy=LekmodScenarioParameters.policy=="gunboat"
local function minor()local m=Players[22];assert(m:IsAlive()and m:IsMinorCiv()and m:GetMinorCivPersonalityType()=="MINOR_CIV_PERSONALITY_IMPOVERISHED");return m end
local function relation(m,owner)
 return {raw100=Game.ReadMinorInfluenceForTest(m:GetID(),owner),rate100=m:GetFriendshipChangePerTurnTimes100(owner),anchor=m:GetMinorCivFriendshipAnchorWithMajor(owner),quest=m:IsMinorCivDisplayedQuestForPlayer(owner,routeQuest),quest_record_present=m:IsMinorCivActiveQuestForPlayer(owner,routeQuest),quests=m:GetMinorCivNumDisplayedQuestsForPlayer(owner),can_gold=m:CanMajorBullyGold(owner),can_worker=m:CanMajorBullyUnit(owner),gold_quote=m:GetMinorCivBullyGoldAmount(owner),policy=Players[owner]:HasPolicy(gunboat)}
end
local function state(p)
 local relations,units={},{};for owner=0,2 do relations[owner]=relation(minor(),owner)end
 for u in p:Units()do units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage()}end
 return {turn=Game.GetGameTurn(),relations=relations,units=units,gold=p:GetGold(),free=p:GetNumFreePolicies(),tenets=p:GetNumFreeTenets(),next_cost=p:GetNextPolicyCost()}
end
local function workers(p)local n=0;for u in p:Units()do if u:GetUnitClassType()==GameInfoTypes.UNITCLASS_WORKER then n=n+1 end end;return n end
local function bully(p)if kind=="gold"then Game.DoMinorBullyGold(p:GetID(),minor():GetID())else Game.DoMinorBullyUnit(p:GetID(),minor():GetID())end end
LekmodScenario={name="gunboat-continuation",items={"tribute-loaded-state","tribute-next-turn-quest","tribute-next-turn-influence","tribute-continued-cooldown"}}
local phase,turn,before="init",nil,nil
function LekmodScenario.snapshot(p)return state(p)end
function LekmodScenario.step(p)
 local m=minor();assert(p:HasPolicy(gunboat)==withPolicy)
 if phase=="init"then
  before=relation(m,0);assert(before.quest==withPolicy and not before.can_gold and not before.can_worker)
  LekmodScenarioRecord("tribute-loaded-state","PASS","authentic post-tribute save preserves exact quest/policy/cooldown state")
  turn=Game.GetGameTurn();phase="settle";return "turn"
 elseif phase=="settle"then
  if Game.GetGameTurn()==turn then return "turn"end;assert(Game.GetGameTurn()==turn+1)
  local after=relation(m,0);LekmodScenarioEvent("native-tribute-next-turn",{before=before,after=after,with_policy=withPolicy,kind=kind})
  assert(after.quest==withPolicy,"Gunboat quest protection did not survive the ordinary minor update")
  LekmodScenarioRecord("tribute-next-turn-quest","PASS","retained policy quest survives ordinary quest evaluation; no-policy quest remains removed")
  local expected=before.raw100+before.rate100;if before.raw100>=before.anchor*100 and expected<before.anchor*100 then expected=before.anchor*100 end
  assert(after.raw100==expected);LekmodScenarioRecord("tribute-next-turn-influence","PASS","ordinary influence matches pre-turn quote without assigning its result")
  assert(not after.can_gold and not after.can_worker);LekmodScenarioRecord("tribute-continued-cooldown","PASS","quest protection does not clear the tribute cooldown")
  return true
 end
 return false
end
