-- Native method surface: GameCore
-- Contact, neutral military and policy prerequisites are inputs. The trait and
-- policy score terms, eligibility, tribute accounting and settlement are native.
LekmodScenario={name="horde-intimidation",items={"horde-trait-data","horde-owner-controls","horde-local-strength","horde-policy-choice","horde-additive-score","horde-tribute-accounting","horde-recency-control","horde-settlement-persistence"}}
local gunboat=GameInfoTypes.POLICY_GUNBOAT_DIPLOMACY
local withPolicy=LekmodScenarioParameters.policy=="gunboat"
local phase,target,choice,adopted,before,turn,settlementBefore="init",nil,nil,false,nil,nil,nil
local recent={}
GameEvents.PlayerAdoptPolicy.Add(function(owner,id)if owner==0 and id==gunboat then adopted=true end end)
local function flag(v)return v==true or v==1 end
local function minors()
 local result={};for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
  if m and m:IsAlive()and m:IsMinorCiv()then result[#result+1]=m end
 end;assert(#result==8);return result
end
local function factor(details,key,maximum,optional)
 local found
 for n=0,maximum do local text=Locale.ConvertTextKey("TXT_KEY_POP_CSTATE_BULLY_FACTOR_POSITIVE",n,key)
  if string.find(details,text,1,true)then assert(found==nil);found=n end
 end
 if found==nil and optional then return 0 end;assert(found~=nil,"missing native tooltip factor "..key);return found
end
local function relation(m,owner)
 local p=Players[owner];local detail=m:GetMajorBullyGoldDetails(owner)
 return {raw100=Game.ReadMinorInfluenceForTest(m:GetID(),owner),friendship=m:GetMinorCivFriendshipWithMajor(owner),rate100=m:GetFriendshipChangePerTurnTimes100(owner),anchor=m:GetMinorCivFriendshipAnchorWithMajor(owner),policy=p:HasPolicy(gunboat),global_score=factor(detail,"TXT_KEY_POP_CSTATE_BULLY_FACTOR_GLOBAL_MILITARY",75),local_score=factor(detail,"TXT_KEY_POP_CSTATE_BULLY_FACTOR_MILITARY_PRESENCE",150),trait_score=factor(detail,"TXT_KEY_POP_CSTATE_BULLY_FACTOR_TRAIT_MODIFIER",150,true),policy_score=factor(detail,"TXT_KEY_POP_CSTATE_BULLY_FACTOR_GUNBOAT_DIPLOMACY",150,true),score=assert(tonumber(string.match(detail,"%(([+%-]?%d+)%)"))),can_gold=m:CanMajorBullyGold(owner),details=detail}
end
local function audit(label)
 local rows={}
 for _,m in ipairs(minors())do local info=GameInfo.Minor_Civ_Personalities[m:GetMinorCivPersonalityType()];local owners={}
  for owner=0,2 do local p=Players[owner];local v=relation(m,owner);local positive=v.global_score+v.local_score
   local trait=owner==0 and 50 or 0;assert(v.trait_score==math.floor(positive*trait/100))
   assert(v.policy_score==math.floor(positive*(v.policy and 50 or 0)/100))
   assert(not Teams[p:GetTeam()]:IsAtWar(m:GetTeam()))
   local expected=positive+v.trait_score+v.policy_score-110+info.BullyScoreModifier
   if v.friendship<GameDefines.FRIENDSHIP_THRESHOLD_CAN_BULLY then expected=expected-300 end
   local bullied=recent[owner..":"..m:GetID()];if bullied then local age=Game.GetGameTurn()-bullied;expected=expected-(age<=10 and 300 or(age<=20 and 40 or 0))end
   if m:GetAlly()~=-1 and m:GetAlly()~=owner then expected=expected-10 end
   for major=0,GameDefines.MAX_MAJOR_CIVS-1 do if major~=owner and m:IsProtectedByMajor(major)then expected=expected-20;break end end
   if m:GetMinorCivTrait()==MinorCivTraitTypes.MINOR_CIV_TRAIT_MILITARISTIC then expected=expected-10 end
   assert(v.score==expected,"independent intimidation score differs")
   assert(v.can_gold==(expected>=0 and not flag(info.BlocksTribute)))
   v.recent_turn=bullied;v.expected=expected;owners[owner]=v
  end
  rows[m:GetID()]={personality=m:GetMinorCivPersonalityType(),personality_score=info.BullyScoreModifier,militaristic=m:GetMinorCivTrait()==MinorCivTraitTypes.MINOR_CIV_TRAIT_MILITARISTIC,ally=m:GetAlly(),owners=owners}
 end
 LekmodScenarioEvent("native-horde-score",{label=label,rows=rows});return rows
end
function LekmodScenario.snapshot(p)
 local rows,units={},{};for _,m in ipairs(minors())do local owners={};for owner=0,2 do owners[owner]=relation(m,owner)end;rows[m:GetID()]={personality=m:GetMinorCivPersonalityType(),owners=owners}end
 for u in p:Units()do units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}end
 return {turn=Game.GetGameTurn(),gold=p:GetGold(),policy=p:HasPolicy(gunboat),free=p:GetNumFreePolicies(),tenets=p:GetNumFreeTenets(),next_cost=p:GetNextPolicyCost(),minors=rows,units=units}
end
local function request(p)
 local m=Players[target];before={gold=p:GetGold(),raw100=Game.ReadMinorInfluenceForTest(target,0),quote=m:GetMinorCivBullyGoldAmount(0),eligible=m:CanMajorBullyGold(0)}
 Game.DoMinorBullyGold(0,target)
end
local function verifyDemand(p,label)
 local m=Players[target];local reward=p:HasPolicy(gunboat)and 5000 or GameDefines.MINOR_FRIENDSHIP_DROP_BULLY_GOLD_SUCCESS
 assert(p:GetGold()==before.gold+(before.eligible and before.quote or 0))
 assert(Game.ReadMinorInfluenceForTest(target,0)==before.raw100+(before.eligible and reward or 0))
 if before.eligible then recent["0:"..target]=Game.GetGameTurn()end
 LekmodScenarioEvent("native-horde-tribute",{label=label,minor=target,before=before,after_gold=p:GetGold(),after_influence100=Game.ReadMinorInfluenceForTest(target,0),reward100=reward})
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and p:IsHuman()and p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GOLDEN_HORDE)
 if phase=="init"then
  assert(GameInfo.Traits.TRAIT_HORDE.MinorBullyModifier==50 and GameInfo.Policies[gunboat].MinorBullyScoreModifier==50)
  for owner=0,2 do assert(not Players[owner]:HasPolicy(gunboat))end
  for _,m in ipairs(minors())do Teams[p:GetTeam()]:Meet(m:GetTeam(),true)end
  local baseline=audit("before-local-military");LekmodScenarioRecord("horde-trait-data","PASS","sole configured Horde50 modifier observed on native trait owner")
  LekmodScenarioRecord("horde-owner-controls","PASS","Swedish/Roman controls receive no Horde term across all8minors")
  local selected
  for _,m in ipairs(minors())do if not selected or m:GetMinorCivPersonalityType()=="MINOR_CIV_PERSONALITY_WEALTHY"then selected=m end end
  target=selected:GetID();local city=selected:GetCapitalCity();local plot
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local d=Map.PlotDistance(q:GetX(),q:GetY(),city:GetX(),city:GetY())
   if d>=2 and d<=4 and q:GetOwner()==-1 and q:GetNumUnits()==0 and not q:IsWater()and not q:IsMountain()then plot=q;break end
  end
  assert(plot);p:ChangeGold(5000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1);local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,plot:GetX(),plot:GetY()))
  LekmodScenarioEvent("fixture-setup",{operation="provided-neutral-military-and-upkeep",minor=target,unit=u:GetID(),x=plot:GetX(),y=plot:GetY()})
  local after=audit("after-local-military");assert(after[target].owners[0].local_score>baseline[target].owners[0].local_score and after[target].owners[0].can_gold)
  LekmodScenarioRecord("horde-local-strength","PASS","actual local military input raises native base strength and its exact50percent trait term")
  if withPolicy then
   p:SetPolicyBranchUnlocked(GameInfoTypes.POLICY_BRANCH_AUTOCRACY,true,false)
   for _,name in ipairs({"POLICY_MOBILIZATION","POLICY_FUTURISM","POLICY_INDUSTRIAL_ESPIONAGE","POLICY_POLICE_STATE","POLICY_THIRD_ALTERNATIVE"})do p:SetHasPolicy(GameInfoTypes[name],true)end
   choice=LekmodScenarioPolicyChoice(p,gunboat);Network.SendUpdatePolicies(gunboat,true,true);phase="adopt"
  else LekmodScenarioRecord("horde-policy-choice","PASS","Gunboat absent control");phase="demand"end
 elseif phase=="adopt"then
  if not LekmodScenarioAwait("horde-policy",adopted and p:HasPolicy(gunboat))then return false end
  LekmodScenarioVerifyPolicyChoice(p,gunboat,choice);assert(not p:IsPolicyBlocked(gunboat));LekmodScenarioRecord("horde-policy-choice","PASS","native Gunboat choice enables the additional50percent term");phase="demand"
 elseif phase=="demand"then
  audit("selected-policy");LekmodScenarioRecord("horde-additive-score","PASS","trait and policy terms add independently to base military scores; final eligibility includes personality and relationship factors")
  request(p);assert(before.eligible);phase="first"
 elseif phase=="first"then
  verifyDemand(p,"first");audit("recent-tribute");LekmodScenarioRecord("horde-tribute-accounting","PASS","eligible normal command grants quoted gold and exact configured influence")
  request(p);phase="repeat"
 elseif phase=="repeat"then
  verifyDemand(p,"repeat");settlementBefore=audit("after-repeat")
  LekmodScenarioRecord("horde-recency-control","PASS","repeat command follows actual score including-300 recency; rejection is not assumed for every modifier combination")
  turn=Game.GetGameTurn();phase="settle";return "turn"
 elseif phase=="settle"then
  if Game.GetGameTurn()==turn then return "turn"end;assert(Game.GetGameTurn()==turn+1)
  local after=audit("ordinary-turn")
  for minor,row in pairs(settlementBefore)do for owner=0,2 do local old=row.owners[owner];local expected=old.raw100+old.rate100;if old.raw100>=old.anchor*100 and expected<old.anchor*100 then expected=old.anchor*100 end;assert(after[minor].owners[owner].raw100==expected)end end
  LekmodScenarioEvent("native-horde-settlement",{before=settlementBefore,after=after})
  LekmodScenarioRecord("horde-settlement-persistence","PASS","24relationships settle their exact quoted influence over one ordinary turn; state retained for replay")
  return true
 end
 return false
end
