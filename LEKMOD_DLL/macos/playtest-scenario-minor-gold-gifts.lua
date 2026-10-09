-- Native method surface: GameCore
-- Contact, branch access and treasury are supplied. Quoted influence and
-- delivered gifts use the normal native consumer and gold-gift message.
LekmodScenario={name="minor-gold-gifts",items={"gold-gift-inputs","gold-gift-policy","gold-gift-quotes","gold-gift-owner-controls","gold-gift-insufficient","gold-gift-payments","gold-gift-availability","gold-gift-persistence"}}
local phil=GameInfoTypes.POLICY_PHILANTHROPY
local withPolicy=LekmodScenarioParameters.policy=="philanthropy"
local phase,choice,adopted,recipient,amountIndex,before="init",nil,false,1,1,nil
local amounts={250,500,1000};local completed,blocked=0,0
GameEvents.PlayerAdoptPolicy.Add(function(owner,id)if owner==0 and id==phil then adopted=true end end)
local function flag(v)return v==true or v==1 end
local function minors()
 local result={};for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
  if m and m:IsAlive()and m:IsMinorCiv()then result[#result+1]=m end
 end;assert(#result==8);return result
end
local function f32(n)
 if n==0 then return 0 end;local m,e=math.frexp(n);return math.ldexp(math.floor(m*16777216+0.5),e-24)
end
local function expected(m,owner,gold)
 local n=math.floor(gold^GameDefines.GOLD_GIFT_FRIENDSHIP_EXPONENT)
 n=math.floor(n/GameDefines.GOLD_GIFT_FRIENDSHIP_DIVISOR)
 local fraction=math.min(f32(Game.GetElapsedGameTurns()/Game.GetEstimateEndTurn()),1)
 fraction=1-fraction*GameDefines.MINOR_CIV_GOLD_GIFT_GAME_MULTIPLIER/GameDefines.MINOR_CIV_GOLD_GIFT_GAME_DIVISOR
 n=math.floor(n*fraction)
 local modifier=Players[owner]:HasPolicy(phil)and GameInfo.Policies[phil].MinorGoldFriendshipMod or 0
 n=math.floor(n*(100+modifier)/100)
 n=math.floor(n*GameInfo.GameSpeeds[Game.GetGameSpeedType()].GoldGiftMod/100)
 assert(not m:IsMinorCivActiveQuestForPlayer(owner,MinorCivQuestTypes.MINOR_CIV_QUEST_INVEST))
 n=math.max(n,GameDefines.MINOR_CIV_GOLD_GIFT_MINIMUM_FRIENDSHIP_REWARD)
 local d=GameDefines.MINOR_CIV_GOLD_GIFT_VISIBLE_DIVISOR;n=math.floor(n/d)*d
 local personality=GameInfo.Minor_Civ_Personalities[m:GetMinorCivPersonalityType()]
 if personality.GoldGiftInfluenceModifierPercent~=100 then n=math.floor(n*personality.GoldGiftInfluenceModifierPercent/100);n=math.floor(n/d)*d end
 return n
end
local function relation(m,owner)
 return {raw100=Game.ReadMinorInfluenceForTest(m:GetID(),owner),rate100=m:GetFriendshipChangePerTurnTimes100(owner),policy=Players[owner]:HasPolicy(phil)}
end
function LekmodScenario.snapshot(p)
 local owners,rows={},{};for owner=0,2 do local v=Players[owner];owners[owner]={gold=v:GetGold(),policy=v:HasPolicy(phil),free=v:GetNumFreePolicies(),next_cost=v:GetNextPolicyCost()}end
 for _,m in ipairs(minors())do local quotes,relations={},{};for owner=0,2 do quotes[owner]={};relations[owner]=relation(m,owner);for _,amount in ipairs({1,250,500,1000})do quotes[owner][amount]=m:GetFriendshipFromGoldGift(owner,amount)end end;rows[m:GetID()]={personality=m:GetMinorCivPersonalityType(),relations=relations,quotes=quotes}end
 return {turn=Game.GetGameTurn(),elapsed=Game.GetElapsedGameTurns(),estimated_end=Game.GetEstimateEndTurn(),owners=owners,minors=rows}
end
local function audit(p,label)
 local first=LekmodScenario.snapshot(p)
 for _,m in ipairs(minors())do for owner=0,2 do
  assert(not Players[owner]:HasCreatedReligion())
  for _,amount in ipairs({1,250,500,1000})do assert(m:GetFriendshipFromGoldGift(owner,amount)==expected(m,owner,amount),"independent gold-gift quote differs")end
 end end
 assert(LekmodScenarioJSON(first)==LekmodScenarioJSON(LekmodScenario.snapshot(p)))
 LekmodScenarioEvent("native-gold-gift-quotes",{label=label,state=first})
end
local function send(p,m,amount,insufficient)
 local data=GameInfo.Minor_Civ_Personalities[m:GetMinorCivPersonalityType()]
 assert(not m:IsMinorCivActiveQuestForPlayer(0,MinorCivQuestTypes.MINOR_CIV_QUEST_GIVE_GOLD))
 local influences={};for owner=0,2 do influences[owner]=relation(m,owner).raw100 end
 before={minor=m:GetID(),amount=amount,gold=p:GetGold(),influences=influences,quote=expected(m,0,amount),no_gifts=flag(data.NoGifts),insufficient=insufficient}
 Game.DoMinorGiftGold(m:GetID(),amount)
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and p:IsHuman()and p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GOLDEN_HORDE)
 if phase=="init"then
  assert(GameInfo.Policies[phil].MinorGoldFriendshipMod==25 and not p:HasPolicy(phil))
  for owner=1,2 do assert(not Players[owner]:HasPolicy(phil))end
  for _,m in ipairs(minors())do Teams[p:GetTeam()]:Meet(m:GetTeam(),true);assert(not Teams[p:GetTeam()]:IsAtWar(m:GetTeam())and not m:IsMajorBlockedByAlliedWar(0))end
  p:SetPolicyBranchUnlocked(GameInfoTypes.POLICY_BRANCH_PATRONAGE,true,false);if not p:HasPolicy(GameInfoTypes.POLICY_PATRONAGE)then p:SetHasPolicy(GameInfoTypes.POLICY_PATRONAGE,true)end
  assert(#p:GetTradeRoutes()==0,"this gold-gift probe must not activate a trade-influence policy")
  if withPolicy then
   local count=0
   for row in GameInfo.Policy_PrereqPolicies{PolicyType="POLICY_PHILANTHROPY"}do
    assert(row.PrereqPolicy=="POLICY_MERCHANT_CONFEDERACY" and GameInfo.Policies[row.PrereqPolicy].MinorGoldFriendshipMod==0)
    p:SetHasPolicy(GameInfoTypes[row.PrereqPolicy],true);count=count+1
    LekmodScenarioEvent("fixture-setup",{operation="provided-policy-prerequisite",policy=row.PrereqPolicy,gold_gift_modifier=0,active_trade_routes=0})
   end
   assert(count==1)
  end
  audit(p,"before-policy");LekmodScenarioRecord("gold-gift-inputs","PASS","normal three-owner/eight-minor fixture; provided contact and equal Patronage prerequisites")
  if withPolicy then choice=LekmodScenarioPolicyChoice(p,phil);Network.SendUpdatePolicies(phil,true,true);phase="adopt"
  else LekmodScenarioRecord("gold-gift-policy","PASS","Philanthropy absent control");phase="prepare"end
 elseif phase=="adopt"then
  if not LekmodScenarioAwait("gift-policy",adopted and p:HasPolicy(phil))then return false end
  LekmodScenarioVerifyPolicyChoice(p,phil,choice);assert(not p:IsPolicyBlocked(phil));LekmodScenarioRecord("gold-gift-policy","PASS","normal native policy choice consumes one choice and enables25percent gift modifier");phase="prepare"
 elseif phase=="prepare"then
  audit(p,"selected-policy");LekmodScenarioRecord("gold-gift-quotes","PASS","96 owner/minor/amount quotes match independent power, float-progress, integer and personality rounding")
  LekmodScenarioRecord("gold-gift-owner-controls","PASS","nonowner quotes and repeated read-only snapshots remain unchanged by the human policy")
  p:ChangeGold(50-p:GetGold());local target
  for _,m in ipairs(minors())do if not flag(GameInfo.Minor_Civ_Personalities[m:GetMinorCivPersonalityType()].NoGifts)then target=m;break end end
  assert(target);LekmodScenarioEvent("fixture-setup",{operation="provided-insufficient-gift-budget",gold=50});send(p,target,250,true);phase="insufficient"
 elseif phase=="insufficient"then
  assert(p:GetGold()==before.gold and relation(Players[before.minor],0).raw100==before.influences[0],"unaffordable gift changed state")
  LekmodScenarioRecord("gold-gift-insufficient","PASS","normal250gold message cannot debit a50gold budget or grant influence")
  p:ChangeGold(50000-p:GetGold());LekmodScenarioEvent("fixture-setup",{operation="provided-funded-gift-budget",gold=50000});send(p,minors()[recipient],amounts[amountIndex],false);phase="deliver"
 elseif phase=="deliver"then
  local m=Players[before.minor];local delta=before.no_gifts and 0 or before.quote*100;local cost=before.no_gifts and 0 or before.amount
  if not LekmodScenarioAwait("gift-delivery",p:GetGold()==before.gold-cost and relation(m,0).raw100==before.influences[0]+delta)then return false end
  for owner=1,2 do assert(relation(m,owner).raw100==before.influences[owner])end
  LekmodScenarioEvent("native-gold-gift-delivery",{before=before,after_gold=p:GetGold(),after_influence100=relation(m,0).raw100})
  if before.no_gifts then blocked=blocked+1 else completed=completed+1 end
  amountIndex=amountIndex+1;if amountIndex>#amounts then amountIndex=1;recipient=recipient+1 end
  if recipient<=#minors()then send(p,minors()[recipient],amounts[amountIndex],false);return false end
  assert(completed>0 and completed+blocked==24)
  LekmodScenarioRecord("gold-gift-payments","PASS","all24standard amount/recipient messages resolve with exact treasury and influence; foreign-owner relationships unchanged")
  LekmodScenarioRecord("gold-gift-availability","PASS","observed available/NoGifts recipients obey their native branch; blocked="..blocked.." delivered="..completed)
  audit(p,"after-deliveries");LekmodScenarioRecord("gold-gift-persistence","PASS","gold, exact influence, policy and all quotes retained for exact replay")
  return true
 end
 return false
end
