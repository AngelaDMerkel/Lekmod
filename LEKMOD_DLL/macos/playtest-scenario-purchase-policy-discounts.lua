-- Native method surface: GameCore
-- Branch access, a native free choice, religion, research and purchase budgets
-- are inputs. Target adoption and original purchase callbacks are real outcomes.
LekmodScenario={name="purchase-policy-discounts",items={"purchase-policy-baseline","purchase-policy-adopted","purchase-policy-choice-history","purchase-policy-price-effects","purchase-policy-exclusions","purchase-policy-foreign-control","purchase-policy-first-debit","purchase-policy-second-debit","purchase-policy-save-state"}}
local mode=assert(LekmodScenarioParameters.mode)
local policy=GameInfoTypes[mode=="mandate"and"POLICY_MANDATE_OF_HEAVEN"or"POLICY_SKYSCRAPERS"]
local branch=GameInfoTypes[mode=="mandate"and"POLICY_BRANCH_PIETY"or"POLICY_BRANCH_ORDER"]
local phase,before,choice,adopted,reply,event,pending="init"
local mandir,granary,library,warrior,missionary=GameInfoTypes.BUILDING_MANDIR,GameInfoTypes.BUILDING_GRANARY,GameInfoTypes.BUILDING_LIBRARY,GameInfoTypes.UNIT_WARRIOR,GameInfoTypes.UNIT_MISSIONARY
local function cap(owner)return assert(Players[owner]:GetCapitalCity())end
local function gold(c,b,active)
 if b.HurryCostModifier==-1 or b.GoldCost<0 then return -1 end
 local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()];local n
 if b.GoldCost>0 then n=math.floor(b.GoldCost*(100+b.HurryCostModifier)/100);n=math.floor(n*speed.ConstructPercent/100)
 else n=math.floor((c:GetBuildingProductionNeeded(b.ID)*GameDefines.GOLD_PURCHASE_GOLD_PER_PRODUCTION)^GameDefines.HURRY_GOLD_PRODUCTION_EXPONENT);n=math.floor(n*speed.HurryPercent/100);n=math.floor(n*(100+b.HurryCostModifier)/100)end
 if active and mode=="skyscrapers"then n=math.floor(n*50/100)end
 return math.floor(n/GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR)*GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR
end
local function faith(c,b,active)
 local n=math.floor(b.FaithCost*GameInfo.Eras[Teams[Players[c:GetOwner()]:GetTeam()]:GetCurrentEra()].FaithCostMultiplier/100)
 if active and mode=="mandate"and b.FaithCost>0 and(b.UnlockedByBelief==true or b.UnlockedByBelief==1)and b.Cost==-1 then n=math.floor(n*80/100)end
 n=math.floor(n*GameInfo.GameSpeeds[Game.GetGameSpeedType()].ConstructPercent/100)
 return math.floor(n/(2*GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR))*(2*GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR)
end
local function unitFaith(p,id,active)
 local info=GameInfo.Units[id];local n=math.floor(info.FaithCost*GameInfo.Eras[Teams[p:GetTeam()]:GetCurrentEra()].FaithCostMultiplier/100)
 if active and mode=="mandate"and id==missionary then n=math.floor(n*80/100)end
 n=math.floor(n*GameInfo.GameSpeeds[Game.GetGameSpeedType()].TrainPercent/100)
 return math.floor(n/GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR)*GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR
end
local function measure(c)
 local q={};for b in GameInfo.Buildings()do q[b.ID]={gold=c:GetBuildingPurchaseCost(b.ID),faith=c:GetBuildingFaithPurchaseCost(b.ID)}end
 return {buildings=q,warrior_gold=c:GetUnitPurchaseCost(warrior),warrior_faith=c:GetUnitFaithPurchaseCost(warrior,true),missionary_faith=c:GetUnitFaithPurchaseCost(missionary,true)}
end
local function check(p,active)
 local c=cap(0);local n=0
 for b in GameInfo.Buildings()do assert(c:GetBuildingPurchaseCost(b.ID)==gold(c,b,active),"building gold policy quote differs: "..b.Type);assert(c:GetBuildingFaithPurchaseCost(b.ID)==faith(c,b,active),"building faith policy quote differs: "..b.Type);n=n+1 end
 assert(n==258 and c:GetUnitFaithPurchaseCost(missionary,true)==unitFaith(p,missionary,active)and c:GetUnitFaithPurchaseCost(warrior,true)==unitFaith(p,warrior,active))
 LekmodScenarioEvent("native-purchase-policy-quotes",{mode=mode,active=active,owner=0,quotes=measure(c)})
end
local function purchase(p,unit,building,yield)
 local c=cap(0);local cost
 if unit then cost=unitFaith(p,unit,true);assert(c:GetUnitFaithPurchaseCost(unit,true)==cost)
 elseif yield==YieldTypes.YIELD_GOLD then cost=gold(c,GameInfo.Buildings[building],true);assert(c:GetBuildingPurchaseCost(building)==cost)
 else cost=faith(c,GameInfo.Buildings[building],true);assert(c:GetBuildingFaithPurchaseCost(building)==cost)end
 local old=yield==YieldTypes.YIELD_GOLD and p:GetGold()or p:GetFaith();assert(cost>1)
 if yield==YieldTypes.YIELD_GOLD then p:ChangeGold(cost-1-old)else p:ChangeFaith(cost-1-old)end
 assert(not c:IsCanPurchase(true,true,unit or -1,building or -1,-1,yield));if yield==YieldTypes.YIELD_GOLD then p:ChangeGold(1)else p:ChangeFaith(1)end
 assert(c:IsCanPurchase(true,true,unit or -1,building or -1,-1,yield))
 pending={unit=unit,building=building,yield=yield,cost=cost,gold=p:GetGold(),faith=p:GetFaith()};reply,event=nil,nil
 LekmodScenarioEvent("fixture-setup",{operation="provided-policy-purchase-budget",cost=cost,unit=unit,building=building,yield=yield})
 if unit then LuaEvents.LekmodScenarioFaithPurchase(c:GetID(),unit)
 elseif yield==YieldTypes.YIELD_GOLD then LuaEvents.LekmodScenarioBuildingPurchase(c:GetID(),building)
 else LuaEvents.LekmodScenarioFaithBuildingPurchase(c:GetID(),building)end
end
local function bought(p)
 if not LekmodScenarioAwait("policy-purchase",reply and event)then return false end
 assert(reply.kind=="purchase"and reply.id==(pending.unit or pending.building))
 assert(event.gold==(pending.yield==YieldTypes.YIELD_GOLD)and event.faith==(pending.yield==YieldTypes.YIELD_FAITH))
 assert(p:GetGold()==pending.gold-(event.gold and pending.cost or 0)and p:GetFaith()==pending.faith-(event.faith and pending.cost or 0))
 LekmodScenarioEvent("native-policy-discount-purchase",{cost=pending.cost,unit=pending.unit,building=pending.building,gold=event.gold,faith=event.faith});return true
end
local function response(kind,id)reply={kind=kind,id=id}end
LuaEvents.LekmodScenarioCityResponse.Add(response);LuaEvents.LekmodScenarioReligionResponse.Add(response)
GameEvents.PlayerAdoptPolicy.Add(function(owner,id)if owner==0 and id==policy then adopted=true end end)
GameEvents.CityConstructed.Add(function(owner,city,id,goldPaid,faithPaid)if owner==0 and pending and pending.building==id then assert(city==cap(0):GetID()and not event);event={gold=goldPaid,faith=faithPaid}end end)
GameEvents.CityTrained.Add(function(owner,city,id,goldPaid,faithPaid)if owner==0 and pending and pending.unit then local u=Players[owner]:GetUnitByID(id);if u and u:GetUnitType()==pending.unit then assert(city==cap(0):GetID()and not event);event={gold=goldPaid,faith=faithPaid}end end end)
function LekmodScenario.snapshot(p)
 local cities,units={},{}
 for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),religion=c:GetReligiousMajority(),mandir=c:GetNumRealBuilding(mandir),granary=c:GetNumRealBuilding(granary),library=c:GetNumRealBuilding(library),quotes=measure(c)}end
 for u in p:Units()do if u:GetUnitType()==missionary then units[u:GetID()]={x=u:GetX(),y=u:GetY(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),moves=u:GetMoves()}end end
 return {turn=Game.GetGameTurn(),mode=mode,policy=p:HasPolicy(policy),blocked=p:IsPolicyBlocked(policy),free=p:GetNumFreePolicies(),tenets=p:GetNumFreeTenets(),culture=p:GetJONSCulture(),next_cost=p:GetNextPolicyCost(),gold=p:GetGold(),faith=p:GetFaith(),cities=cities,units=units,foreign=measure(cap(1))}
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MALI and not Game.IsOption("GAMEOPTION_NO_RELIGION"))
 local c=cap(0)
 if phase=="init"then
  assert(not p:HasPolicy(GameInfoTypes.POLICY_MANDATE_OF_HEAVEN)and not p:HasPolicy(GameInfoTypes.POLICY_SKYSCRAPERS)and p:GetHurryModifier(GameInfoTypes.HURRY_GOLD)==0)
  assert(c:GetNumBuilding(GameInfoTypes.BUILDING_MALI_NATIONAL_TREASURY)==0 and c:GetNumBuilding(mandir)==0 and c:GetNumBuilding(granary)==0 and c:GetNumBuilding(library)==0)
  LekmodScenarioGrantTech(p,"TECH_WRITING");assert(not p:HasCreatedReligion()and Game.GetNumReligionsStillToFound()>0)
  local religion;local taken={};for id=0,GameDefines.MAX_CIV_PLAYERS-1 do local q=Players[id];if q and q:IsAlive()and q:HasCreatedReligion()then taken[q:GetReligionCreatedByPlayer()]=true end end
  for row in GameInfo.Religions()do if row.ID>0 and not taken[row.ID]then religion=row.ID;break end end
  local founder,follower=false,false
  for _,id in ipairs(Game.GetAvailableFounderBeliefs())do if id==GameInfoTypes.BELIEF_TITHE then founder=true end end
  for _,id in ipairs(Game.GetAvailableFollowerBeliefs())do if id==GameInfoTypes.BELIEF_MANDIRS then follower=true end end
  assert(founder and follower,"required fixture beliefs unavailable")
  Game.FoundReligion(0,assert(religion),nil,GameInfoTypes.BELIEF_TITHE,GameInfoTypes.BELIEF_MANDIRS,-1,-1,c);assert(p:GetReligionCreatedByPlayer()==religion and c:GetReligiousMajority()==religion)
  LekmodScenarioEvent("fixture-setup",{operation="provided-religion-for-policy-purchases",religion=religion,founder=GameInfoTypes.BELIEF_TITHE,follower=GameInfoTypes.BELIEF_MANDIRS})
  p:SetPolicyBranchUnlocked(branch,true,false);choice=LekmodScenarioPolicyChoice(p,policy);check(p,false)
  before={human=measure(c),foreign=measure(cap(1))};LekmodScenarioRecord("purchase-policy-baseline","PASS","baseline prices checked before target adoption; branch access and a preserved native choice are inputs")
  Network.SendUpdatePolicies(policy,true,true);phase="adopted"
 elseif phase=="adopted"then
  if not LekmodScenarioAwait("purchase-policy-adoption",adopted and p:HasPolicy(policy))then return false end
  LekmodScenarioVerifyPolicyChoice(p,policy,choice);assert(not p:IsPolicyBlocked(policy));check(p,true)
  LekmodScenarioRecord("purchase-policy-adopted","PASS","normal legal policy message emitted the native adoption event")
  LekmodScenarioRecord("purchase-policy-choice-history","PASS","native choice debit/culture/tenet accounting and positive next-policy cost preserved")
  local after=measure(c);assert(LekmodScenarioJSON(measure(cap(1)))==LekmodScenarioJSON(before.foreign))
  if mode=="mandate"then
   assert(after.buildings[mandir].faith<before.human.buildings[mandir].faith and after.missionary_faith<before.human.missionary_faith and after.warrior_faith==before.human.warrior_faith)
   assert(after.buildings[library].faith==before.human.buildings[library].faith and after.buildings[granary].gold==before.human.buildings[granary].gold)
  else assert(after.buildings[granary].gold<before.human.buildings[granary].gold and after.buildings[GameInfoTypes.BUILDING_ISRAEL_NATIONAL_COLLEGE].gold<before.human.buildings[GameInfoTypes.BUILDING_ISRAEL_NATIONAL_COLLEGE].gold and after.warrior_gold==before.human.warrior_gold and after.buildings[mandir].faith==before.human.buildings[mandir].faith)end
  LekmodScenarioRecord("purchase-policy-price-effects","PASS","all258 building quotes and religious-unit prices match the independent positive modifier oracle")
  LekmodScenarioRecord("purchase-policy-exclusions","PASS","unrelated currency, unit type and non-faith-native building costs remain unchanged")
  LekmodScenarioRecord("purchase-policy-foreign-control","PASS","other owner's complete quote matrix remains unchanged")
  if mode=="mandate"then purchase(p,nil,mandir,YieldTypes.YIELD_FAITH)else purchase(p,nil,granary,YieldTypes.YIELD_GOLD)end;phase="first"
 elseif phase=="first"then
  if not bought(p)then return false end;LekmodScenarioRecord("purchase-policy-first-debit","PASS","normal popup purchase spends the independent discounted amount; cost-1 rejected")
  if mode=="mandate"then purchase(p,missionary,nil,YieldTypes.YIELD_FAITH)else purchase(p,nil,library,YieldTypes.YIELD_GOLD)end;phase="second"
 elseif phase=="second"then
  if not bought(p)then return false end;check(p,true)
  LekmodScenarioRecord("purchase-policy-second-debit","PASS","second normal purchase also receives the policy discount and spends the exact independent amount")
  LekmodScenarioRecord("purchase-policy-save-state","PASS","policy/history, purchases, currency and complete quote state retained for exact replay");return true
 end
 return false
end
