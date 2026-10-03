-- Native method surface: GameCore
-- Religion/conversion, prerequisite research/free choices and initial influence
-- are inputs. Policy messages, quoted rates and ordinary settlements are native.
LekmodScenario={name="minor-influence-modifiers",items={"minor-modifier-data","minor-trait-baseline","minor-religion-owner-controls","minor-religion-transition","minor-policy-adoption","minor-policy-owner-control","minor-independent-rates","minor-ordinary-settlement","minor-fractional-persistence"}}
local policyMode=assert(LekmodScenarioParameters.policy)
local unityOwner=assert(LekmodScenarioParameters.founder)=="human"and 0 or 2
local phase,started,tick,branchEvent,policyEvent,choice="init",nil,0,false,nil,nil
local minors,before={},{}
local religionA,religionB
local branch=GameInfoTypes.POLICY_BRANCH_PATRONAGE
local opener=GameInfoTypes.POLICY_PATRONAGE
local merchant=GameInfoTypes.POLICY_MERCHANT_CONFEDERACY
local philanthropy=GameInfoTypes.POLICY_PHILANTHROPY
local function div(n,d)return n>=0 and math.floor(n/d)or math.ceil(n/d)end
local function has(list,id)for _,v in ipairs(list)do if v==id then return true end end;return false end
local function convert(c,id)
 c:ConvertPercentFollowers(id,-1,100);c:ConvertPercentFollowers(id,0,100)
 for r in GameInfo.Religions()do if r.ID>0 and r.ID~=id then c:ConvertPercentFollowers(id,r.ID,100)end end
 assert(c:GetReligiousMajority()==id)
end
local function beliefs(p)
 local found=p:GetReligionCreatedByPlayer();return found>0 and has(Game.GetBeliefsInReligion(found),GameInfoTypes.BELIEF_RELIGIOUS_UNITY)
end
local function measure(m,owner)
 local p=Players[owner]
 return {raw100=Game.ReadMinorInfluenceForTest(m:GetID(),owner),anchor=m:GetMinorCivFriendshipAnchorWithMajor(owner),rate100=m:GetFriendshipChangePerTurnTimes100(owner),personality=m:GetMinorCivPersonalityType(),minor_religion=m:GetCapitalCity():GetReligiousMajority(),founder_religion=p:GetReligionCreatedByPlayer(),major_religion=p:GetCapitalCity():GetReligiousMajority(),patronage=p:HasPolicy(opener),philanthropy=p:HasPolicy(philanthropy),unity=beliefs(p),protected=m:IsProtectedByMajor(owner),met=Teams[p:GetTeam()]:IsHasMet(m:GetTeam())}
end
local function expected(m,owner,v)
 local p=Players[owner];assert(p:GetNumCities()==1,"majority oracle requires one controlled major city");local personality=assert(GameInfo.Minor_Civ_Personalities[v.personality])
 local same=v.founder_religion>0 and v.founder_religion==v.minor_religion
 local baseAnchor=GameDefines.MINOR_FRIENDSHIP_ANCHOR_DEFAULT+(owner==1 and 5 or 0)+(v.patronage and 20 or 0)
 assert(not v.protected and not Teams[p:GetTeam()]:IsAtWar(m:GetTeam())and #p:GetTradeRoutes()==0,"unreviewed pledge/war/trade influence input")
 local anchor=baseAnchor+(same and v.unity and 45 or 0)
 local trait=owner==0 and 100 or 0;local religion=0
 if same then religion=div(GameDefines.MINOR_FRIENDSHIP_RATE_MOD_SHARED_RELIGION*personality.SharedReligionDecayRecoveryModifierPercent,100)
 elseif v.minor_religion>0 and v.major_religion>0 and v.minor_religion~=v.major_religion then religion=personality.DifferentReligionDecayRecoveryModifierPercent end
 local change=0
 if v.raw100>anchor*100 then
  local drop=personality.FriendshipDropPerTurn~=0 and personality.FriendshipDropPerTurn or GameDefines.MINOR_FRIENDSHIP_DROP_PER_TURN
  local mod=math.max(0,100+(v.philanthropy and -25 or 0)-div(trait,2)-div(religion,2)-(same and v.unity and 25 or 0))
  mod=div(mod*personality.FriendshipDecayModifierPercent,100);change=div(drop*mod,100)
 elseif v.raw100<anchor*100 then
  local mod=math.max(0,100+trait+religion+(same and v.unity and 100 or 0))
  mod=div(mod*personality.FriendshipRecoveryModifierPercent,100);change=div(GameDefines.MINOR_FRIENDSHIP_NEGATIVE_INCREASE_PER_TURN*mod,100)
 end
 return anchor,div(change*GameInfo.GameSpeeds[Game.GetGameSpeedType()].GoldGiftMod,100)
end
local function audit(label)
 local states={}
 for _,id in ipairs(minors)do local m=Players[id];states[id]={}
  for owner=0,2 do local v=measure(m,owner);local anchor,rate=expected(m,owner,v)
   assert(v.anchor==anchor and v.rate100==rate,label.." independent rate/anchor differs: minor"..id.." owner"..owner.." "..LekmodScenarioJSON(v).." wanted="..anchor.."/"..rate)
   states[id][owner]=v
  end
 end
 LekmodScenarioEvent("native-minor-modifier-quotes",{label=label,founder=unityOwner,policy=policyMode,states=states});return states
end
function LekmodScenario.snapshot(player)
 local states,owners={},{}
 for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
  if m and m:IsAlive()and m:IsMinorCiv()then states[id]={};for owner=0,2 do states[id][owner]=measure(m,owner)end end
 end
 for owner=0,2 do local p=Players[owner];owners[owner]={civilization=p:GetCivilizationType(),religion=p:GetReligionCreatedByPlayer(),patronage=p:HasPolicy(opener),merchant=p:HasPolicy(merchant),philanthropy=p:HasPolicy(philanthropy),free=p:GetNumFreePolicies(),culture=p:GetJONSCulture(),next_cost=p:GetNextPolicyCost()}end
 return {turn=Game.GetGameTurn(),founder=unityOwner,policy=policyMode,minors=states,owners=owners}
end
GameEvents.PlayerPolicyBranchUnlocked.Add(function(owner,id)if owner==0 and id==branch then branchEvent=true end end)
GameEvents.PlayerAdoptPolicy.Add(function(owner,id)if owner==0 then policyEvent=id end end)
local function policyChoice(p,id)
 choice=LekmodScenarioPolicyChoice(p,id);policyEvent=nil;Network.SendUpdatePolicies(id,true,true)
end
local function beginObservation()
 for i,id in ipairs(minors)do local m=Players[id]
  for owner=0,2 do local v=measure(m,owner);assert(v.raw100%100==0,"initial influence needs exact integer input")
   local offset=({20,-20,0})[(i+owner-1)%3+1];local target=v.anchor+offset
   m:ChangeMinorCivFriendshipWithMajor(owner,target-v.raw100/100)
   assert(Game.ReadMinorInfluenceForTest(id,owner)==target*100)
   LekmodScenarioEvent("fixture-setup",{operation="provided-influence-regime",minor=id,owner=owner,anchor=v.anchor,offset=offset,raw100=target*100})
  end
 end
 before=audit("before-turns");started=Game.GetGameTurn();phase="observe";return "turn"
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and p:IsHuman()and p:GetID()==0)
 assert(Players[0]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GREECE and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_TONGA and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init"then
  assert(Game.IsOption(GameOptionTypes.GAMEOPTION_ALWAYS_PEACE)and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION))
  for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id];if m and m:IsAlive()and m:IsMinorCiv()then assert(m:GetCapitalCity());minors[#minors+1]=id end end;assert(#minors==3)
  assert(GameInfo.Traits.TRAIT_CITY_STATE_FRIENDSHIP.CityStateFriendshipModifier==100 and GameInfo.Traits.TRAIT_ISLANDS.MinorFriendshipMinimum==5)
  local u=GameInfo.Beliefs.BELIEF_RELIGIOUS_UNITY;assert(u.CityStateMinimumInfluence==45 and u.CityStateFollowingReligionDecayMod==50 and u.CityStateFollowingReligionRecoveryMod==100)
  assert(GameInfo.Policies[opener].MinorFriendshipMinimum==20 and GameInfo.Policies[philanthropy].MinorFriendshipDecayMod==-25)
  for owner=0,2 do assert(Players[owner]:GetNumCities()==1 and not Players[owner]:HasCreatedReligion()and not Players[owner]:HasPolicy(opener)and not Players[owner]:HasPolicy(philanthropy))end
  started=Game.GetGameTurn();phase="rest"
 elseif phase=="rest"then
  local ready=true
  for _,id in ipairs(minors)do local m=Players[id];local v=measure(m,1);assert(v.anchor==5);if v.raw100~=500 then ready=false end end
  if not ready then assert(Game.GetGameTurn()-started<2,"Tonga did not reach its normal initial anchor within two rounds");return "turn"end
  audit("trait-baseline");LekmodScenarioRecord("minor-modifier-data","PASS","all configured trait/policy/belief constants and three genuine minor personalities are pinned")
  LekmodScenarioRecord("minor-trait-baseline","PASS","unmodified Greek/Roman anchor0 and Tonga5 match before religion/policy inputs")
  local ids={};for r in GameInfo.Religions()do if r.ID>0 then ids[#ids+1]=r.ID end end;religionA,religionB=ids[1],ids[2]
  assert(Game.GetNumReligionsStillToFound()>=2)
  Game.FoundReligion(0,religionA,nil,GameInfoTypes.BELIEF_TITHE,GameInfoTypes.BELIEF_MANDIRS,-1,-1,p:GetCapitalCity())
  Game.EnhanceReligion(0,religionA,GameInfoTypes.BELIEF_HOLY_WARRIORS,unityOwner==0 and GameInfoTypes.BELIEF_RELIGIOUS_UNITY or GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS)
  Game.FoundReligion(2,religionB,nil,GameInfoTypes.BELIEF_CHURCH_PROPERTY,GameInfoTypes.BELIEF_PAGODAS,-1,-1,Players[2]:GetCapitalCity())
  Game.EnhanceReligion(2,religionB,GameInfoTypes.BELIEF_MOSQUES,unityOwner==2 and GameInfoTypes.BELIEF_RELIGIOUS_UNITY or GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS)
  Network.SendFoundPantheon(0,GameInfoTypes.BELIEF_WORK_ETHIC);Network.SendFoundPantheon(2,GameInfoTypes.BELIEF_JESUIT_EDUCATION)
  convert(Players[1]:GetCapitalCity(),religionA)
  for i,id in ipairs(minors)do local c=Players[id]:GetCapitalCity();c:SetPopulation(8,true);convert(c,i==2 and religionB or religionA)end
  LekmodScenarioEvent("fixture-setup",{operation="provided-religions-conversions-and-reformations",unity_owner=unityOwner,a=religionA,b=religionB,tonga_follower_only=true});phase="religion"
 elseif phase=="religion"then
  if not LekmodScenarioAwait("modifier-reformations",has(Game.GetBeliefsInReligion(religionA),GameInfoTypes.BELIEF_WORK_ETHIC)and has(Game.GetBeliefsInReligion(religionB),GameInfoTypes.BELIEF_JESUIT_EDUCATION))then return false end
  audit("religion-matching-controls");LekmodScenarioRecord("minor-religion-owner-controls","PASS","45anchor and50/100rate factors belong to the matching religion founder; nonfounder Tonga following it gets only trait5")
  local c=Players[minors[3]]:GetCapitalCity();convert(c,religionB);audit("religion-changed");convert(c,religionA);audit("religion-restored")
  LekmodScenarioRecord("minor-religion-transition","PASS","conversion to the other religion changes matching founder effects and returning restores them without stacking")
  if policyMode=="none"then
   LekmodScenarioRecord("minor-policy-adoption","PASS","no-policy control retains locked Patronage and absent Philanthropy")
   LekmodScenarioRecord("minor-policy-owner-control","PASS","all three owners remain unmodified by policy")
   return beginObservation()
  end
  LekmodScenarioGrantTech(p,"TECH_PHILOSOPHY");assert(not p:IsPolicyBranchUnlocked(branch)and p:GetNumFreePolicies()==0 and p:GetNextPolicyCost()>0)
  p:SetNumFreePolicies(1);assert(p:CanUnlockPolicyBranch(branch));choice={culture=p:GetJONSCulture(),free=1}
  LekmodScenarioEvent("fixture-setup",{operation="provided-Patronage-research-and-choice",culture=choice.culture,free=1});Network.SendUpdatePolicies(branch,false,true);phase="branch"
 elseif phase=="branch"then
  if not LekmodScenarioAwait("native-Patronage",branchEvent and p:IsPolicyBranchUnlocked(branch)and p:HasPolicy(opener))then return false end
  assert(p:GetNumFreePolicies()==0 and p:GetJONSCulture()==choice.culture and p:GetNextPolicyCost()>0 and not p:CanUnlockPolicyBranch(branch))
  audit("after-Patronage")
  if policyMode=="philanthropy"then policyChoice(p,merchant);phase="merchant";return false end
  phase="policies-done"
 elseif phase=="merchant"then
  if not LekmodScenarioAwait("native-MerchantConfederacy",policyEvent==merchant and p:HasPolicy(merchant))then return false end
  LekmodScenarioVerifyPolicyChoice(p,merchant,choice);audit("merchant-no-trade-control");policyChoice(p,philanthropy);phase="philanthropy"
 elseif phase=="philanthropy"then
  if not LekmodScenarioAwait("native-Philanthropy",policyEvent==philanthropy and p:HasPolicy(philanthropy))then return false end
  LekmodScenarioVerifyPolicyChoice(p,philanthropy,choice);audit("after-Philanthropy");phase="policies-done"
 elseif phase=="policies-done"then
  for owner=1,2 do assert(not Players[owner]:HasPolicy(opener)and not Players[owner]:HasPolicy(philanthropy))end
  LekmodScenarioRecord("minor-policy-adoption","PASS","normal branch/policy messages consumed each choice once, emitted native events and preserve positive policy costs")
  LekmodScenarioRecord("minor-policy-owner-control","PASS","human20anchor and optional-25decay modifiers leave other owners' policy state unchanged; no trade-route shift supplied")
  return beginObservation()
 elseif phase=="observe"then
  if Game.GetGameTurn()==started+tick then return "turn"end;assert(Game.GetGameTurn()==started+tick+1);tick=tick+1
  local after=audit("owner-turn-"..tick)
  for _,id in ipairs(minors)do for owner=0,2 do local a,b=before[id][owner],after[id][owner];local expectedRaw=a.raw100+a.rate100
   if a.raw100>=a.anchor*100 and expectedRaw<a.anchor*100 then expectedRaw=a.anchor*100 end
   assert(b.raw100==expectedRaw,"unexplained influence change beyond the independently verified rate")
  end end
  LekmodScenarioEvent("native-minor-modifier-settlement",{founder=unityOwner,policy=policyMode,tick=tick,turn=Game.GetGameTurn(),before=before,after=after});before=after
  if tick<3 then return "turn"end
  LekmodScenarioRecord("minor-independent-rates","PASS","nine simultaneous relationships match independent signed/truncated trait, religion, policy, personality and speed arithmetic")
  LekmodScenarioRecord("minor-ordinary-settlement","PASS","all nine exact influence balances settled their predicted deltas for three ordinary minor turns")
  LekmodScenarioRecord("minor-fractional-persistence","PASS","exact influence hundredths, anchors, rates, ownership/religion/policy state retained for replay")
  return true
 end
 return false
end
