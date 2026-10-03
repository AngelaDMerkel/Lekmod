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
-- Quest, military, city and policy prerequisites are supplied. Tribute rewards,
-- quest cancellation/preservation and the native policy choice are outcomes.
LekmodScenario={name="gunboat-tribute",items={"tribute-fixture","tribute-quest-input","tribute-policy-choice","tribute-score-modifier","tribute-native-reward","tribute-influence-change","tribute-immediate-quest","tribute-cooldown-and-repeat"}}
local phase,choice,adopted,before,oldGold,oldWorkers,baseGlobal,baseLocal="init",nil,false,nil,nil,nil,nil,nil
GameEvents.PlayerAdoptPolicy.Add(function(owner,id)if owner==0 and id==gunboat then adopted=true end end)
function LekmodScenario.snapshot(p)return state(p)end
local function factor(details,key,maximum)
 local found
 for n=0,maximum do local text=Locale.ConvertTextKey("TXT_KEY_POP_CSTATE_BULLY_FACTOR_POSITIVE",n,key)
  if string.find(details,text,1,true)then assert(not found);found=n end
 end
 assert(found,"native tribute tooltip factor missing: "..key);return found
end
local function begin(p)
 local m=minor();before=relation(m,0);oldGold=p:GetGold();oldWorkers=workers(p)
 assert(before.can_gold and before.can_worker and before.raw100==0 and before.quest)
 LekmodScenarioEvent("native-tribute-before",{kind=kind,with_policy=withPolicy,relation=before,gold=oldGold,workers=oldWorkers,details=m:GetMajorBullyGoldDetails(0)})
 bully(p);phase="tributed"
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and p:IsHuman()and p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GREECE)
 local m=minor()
 if phase=="init"then
  assert(not p:HasPolicy(gunboat)and not p:HasCreatedReligion()and not m:IsProtectedByMajor(0))
  local row=GameInfo.Policies[gunboat];assert(row.MinorBullyScoreModifier==50 and row.MinorBullyInfluenceReward==5000 and(row.MinorBullyNoPenalty==true or row.MinorBullyNoPenalty==1))
  Teams[p:GetTeam()]:Meet(m:GetTeam(),true);local target=m:GetCapitalCity();target:SetPopulation(4,true)
  local city
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local d=Map.PlotDistance(q:GetX(),q:GetY(),target:GetX(),target:GetY())
   if d>=4 and d<=6 and q:GetArea()==target:Plot():GetArea()and q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then p:Found(q:GetX(),q:GetY());city=q:GetPlotCity();break end
  end
  assert(city,"no legal nearby city for a route quest")
  assert(not m:IsMinorCivActiveQuestForPlayer(0,routeQuest)and m:AddMinorCivQuestIfAble(0,routeQuest))
  assert(m:IsMinorCivActiveQuestForPlayer(0,routeQuest));LekmodScenarioRecord("tribute-quest-input","PASS","provided legal route quest through native testing API; no quest outcome assigned")
  p:ChangeGold(5000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,2)
  local q
  for i=0,Map.GetNumPlots()-1 do local v=Map.GetPlotByIndex(i);local d=Map.PlotDistance(v:GetX(),v:GetY(),target:GetX(),target:GetY())
   if d>=2 and d<=4 and v:GetOwner()==-1 and not v:IsWater()and not v:IsMountain()and v:GetNumUnits()==0 then q=v;break end
  end
  assert(q);local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,q:GetX(),q:GetY()))
  local influence=Game.ReadMinorInfluenceForTest(22,0);assert(influence%100==0);m:ChangeMinorCivFriendshipWithMajor(0,-influence/100)
  p:SetPolicyBranchUnlocked(GameInfoTypes.POLICY_BRANCH_AUTOCRACY,true,false)
  for _,name in ipairs({"POLICY_MOBILIZATION","POLICY_FUTURISM","POLICY_INDUSTRIAL_ESPIONAGE","POLICY_POLICE_STATE","POLICY_THIRD_ALTERNATIVE"})do p:SetHasPolicy(GameInfoTypes[name],true)end
  assert(not p:HasPolicy(gunboat)and m:CanMajorBullyGold(0)and m:CanMajorBullyUnit(0))
  local details=m:GetMajorBullyGoldDetails(0);baseGlobal=factor(details,"TXT_KEY_POP_CSTATE_BULLY_FACTOR_GLOBAL_MILITARY",75);baseLocal=factor(details,"TXT_KEY_POP_CSTATE_BULLY_FACTOR_MILITARY_PRESENCE",150)
  LekmodScenarioEvent("fixture-setup",{operation="provided-legal-quest-city-population-military-policy-prerequisites",minor=22,city=city:GetID(),unit=u:GetID(),x=q:GetX(),y=q:GetY(),population=4,global_score=baseGlobal,local_score=baseLocal,details=details})
  LekmodScenarioRecord("tribute-fixture","PASS","native quest eligibility and both tribute kinds available with supplied military and four-population minor")
  if withPolicy then choice=LekmodScenarioPolicyChoice(p,gunboat);Network.SendUpdatePolicies(gunboat,true,true);phase="adopted"
  else
   LekmodScenarioRecord("tribute-policy-choice","PASS","policy absent control retains identical supplied prerequisites")
   LekmodScenarioRecord("tribute-score-modifier","PASS","baseline positive military factors recorded without policy bonus");begin(p)
  end
 elseif phase=="adopted"then
  if not LekmodScenarioAwait("gunboat-adopted",adopted and p:HasPolicy(gunboat))then return false end
  LekmodScenarioVerifyPolicyChoice(p,gunboat,choice);assert(not p:IsPolicyBlocked(gunboat))
  local details=m:GetMajorBullyGoldDetails(0);assert(factor(details,"TXT_KEY_POP_CSTATE_BULLY_FACTOR_GLOBAL_MILITARY",75)==baseGlobal and factor(details,"TXT_KEY_POP_CSTATE_BULLY_FACTOR_MILITARY_PRESENCE",150)==baseLocal)
  local bonus=factor(details,"TXT_KEY_POP_CSTATE_BULLY_FACTOR_GUNBOAT_DIPLOMACY",120);assert(bonus==math.floor((baseGlobal+baseLocal)*50/100))
  LekmodScenarioEvent("native-tribute-policy-score",{global_score=baseGlobal,local_score=baseLocal,bonus=bonus,details=details})
  LekmodScenarioRecord("tribute-policy-choice","PASS","normal level-three policy message consumes one supplied native choice")
  LekmodScenarioRecord("tribute-score-modifier","PASS","Gunboat adds exactly50percent of unchanged positive global and local military factors");begin(p)
 elseif phase=="tributed"then
  local after=relation(m,0);local reward=withPolicy and 5000 or(kind=="gold"and GameDefines.MINOR_FRIENDSHIP_DROP_BULLY_GOLD_SUCCESS or GameDefines.MINOR_FRIENDSHIP_DROP_BULLY_WORKER_SUCCESS)
  assert(after.raw100==before.raw100+reward,"tribute influence reward/penalty differs")
  assert(p:GetGold()==oldGold+(kind=="gold"and before.gold_quote or 0)and workers(p)==oldWorkers+(kind=="worker"and 1 or 0))
  assert(after.quest==withPolicy,"immediate quest removal/preservation differs")
  assert(not after.can_gold and not after.can_worker,"recent tribute failed to impose native cooldown")
  LekmodScenarioEvent("native-tribute-after",{kind=kind,with_policy=withPolicy,before=before,after=after,gold_before=oldGold,gold_after=p:GetGold(),workers_before=oldWorkers,workers_after=workers(p),reward100=reward})
  LekmodScenarioRecord("tribute-native-reward","PASS","native command delivers exact quoted gold or one worker")
  LekmodScenarioRecord("tribute-influence-change","PASS","native raw influence matches independent configured reward or baseline penalty")
  LekmodScenarioRecord("tribute-immediate-quest","PASS","supplied route quest retained only with Gunboat immediately after tribute")
  before=state(p);bully(p);phase="repeat"
 elseif phase=="repeat"then
  assert(LekmodScenarioJSON(state(p))==LekmodScenarioJSON(before),"ineligible repeated tribute changed state")
  LekmodScenarioRecord("tribute-cooldown-and-repeat","PASS","native cooldown rejects repeat without extra gold/worker/influence; state pinned for next-turn test")
  return true
 end
 return false
end
