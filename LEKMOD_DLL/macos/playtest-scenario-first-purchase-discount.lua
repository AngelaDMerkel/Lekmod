-- Native method surface: GameCore
-- A Treasury, legal cities/religion and budgets are supplied. Original popup
-- callbacks perform purchases; normal owner turns consume/reset the discount.
-- No price, purchase counter, target unit or purchased building is assigned.
LekmodScenario={name="first-purchase-discount",items={"first-discount-baseline","first-discount-all-quotes","first-discount-city-scope","first-discount-first-debit","first-discount-shared-counter","first-discount-second-debit","first-discount-owner-reset","first-discount-reset-debit","first-discount-project-disabled","first-discount-spent-save"}}
local mode=assert(LekmodScenarioParameters.mode)
local pairsByMode={unit_gold={"unit_gold","building_faith"},unit_faith={"unit_faith","building_gold"},building_gold={"building_gold","unit_faith"},building_faith={"building_faith","unit_gold"}}
local pair=assert(pairsByMode[mode]);local phase,aID,bID,control,lastTurn,reply,event,pending="init"
local treasury=GameInfoTypes.BUILDING_MALI_NATIONAL_TREASURY
local warrior,missionary,granary,mandir=GameInfoTypes.UNIT_WARRIOR,GameInfoTypes.UNIT_MISSIONARY,GameInfoTypes.BUILDING_GRANARY,GameInfoTypes.BUILDING_MANDIR
local project=GameInfoTypes.PROJECT_MANHATTAN_PROJECT
local function a()return assert(Players[0]:GetCityByID(aID))end
local function b()return assert(Players[0]:GetCityByID(bID))end
local function descriptor(key)
 if key=="unit_gold"then return {unit=warrior,yield=YieldTypes.YIELD_GOLD}
 elseif key=="unit_faith"then return {unit=missionary,yield=YieldTypes.YIELD_FAITH}
 elseif key=="building_gold"then return {building=granary,yield=YieldTypes.YIELD_GOLD}
 elseif key=="building_faith"then return {building=mandir,yield=YieldTypes.YIELD_FAITH}
 else return {building=control,yield=YieldTypes.YIELD_GOLD}end
end
local function quote(c,key)
 local x=descriptor(key)
 if x.unit then return x.yield==YieldTypes.YIELD_GOLD and c:GetUnitPurchaseCost(x.unit)or c:GetUnitFaithPurchaseCost(x.unit,true)end
 return x.yield==YieldTypes.YIELD_GOLD and c:GetBuildingPurchaseCost(x.building)or c:GetBuildingFaithPurchaseCost(x.building)
end
local function eligible(c,key,funds)
 local x=descriptor(key);return c:IsCanPurchase(funds,true,x.unit or -1,x.building or -1,-1,x.yield)
end
local function goldRaw(production)
 local p=Players[0];assert(p:GetHurryModifier(GameInfoTypes.HURRY_GOLD)==0)
 return math.floor(math.floor((production*GameDefines.GOLD_PURCHASE_GOLD_PER_PRODUCTION)^GameDefines.HURRY_GOLD_PRODUCTION_EXPONENT)*GameInfo.GameSpeeds[Game.GetGameSpeedType()].HurryPercent/100)
end
local function expected(c,key,discount)
 local p=Players[0];local x=descriptor(key);local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()];local amount,divisor
 if x.yield==YieldTypes.YIELD_GOLD then
  local info=x.unit and GameInfo.Units[x.unit]or GameInfo.Buildings[x.building]
  amount=goldRaw(x.unit and c:GetUnitProductionNeeded(x.unit)or c:GetBuildingProductionNeeded(x.building));assert(info.HurryCostModifier~=-1);amount=math.floor(amount*(100+info.HurryCostModifier)/100)
  divisor=GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR
 else
  local info=x.unit and GameInfo.Units[x.unit]or GameInfo.Buildings[x.building]
  amount=math.floor(info.FaithCost*GameInfo.Eras[Teams[p:GetTeam()]:GetCurrentEra()].FaithCostMultiplier/100)
  amount=math.floor(amount*(x.unit and speed.TrainPercent or speed.ConstructPercent)/100)
  divisor=GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR*(x.unit and 1 or 2)
 end
 if discount then amount=math.floor(amount*75/100)end
 return math.floor(amount/divisor)*divisor
end
local function check(c,discount,label)
 local q={}
 for _,key in ipairs({"unit_gold","unit_faith","building_gold","building_faith"})do q[key]=quote(c,key);assert(q[key]==expected(c,key,discount),label.." quote differs: "..key)end
 local raw=goldRaw(c:GetProjectProductionNeeded(project));if discount then raw=math.floor(raw*75/100)end
 local wanted=math.floor(raw/GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR)*GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR
 assert(c:GetProjectPurchaseCost(project)==wanted and not c:IsCanPurchase(false,true,-1,-1,project,YieldTypes.YIELD_GOLD))
 q.project_gold=wanted;LekmodScenarioEvent("native-first-discount-quotes",{label=label,city=c:GetID(),discount=discount,quotes=q})
end
local function buy(c,key,discount)
 local p=Players[0];local x=descriptor(key);local cost=expected(c,key,discount);assert(cost>1 and quote(c,key)==cost and eligible(c,key,false))
 local old=x.yield==YieldTypes.YIELD_GOLD and p:GetGold()or p:GetFaith()
 if x.yield==YieldTypes.YIELD_GOLD then p:ChangeGold(cost-1-old)else p:ChangeFaith(cost-1-old)end
 assert(not eligible(c,key,true));if x.yield==YieldTypes.YIELD_GOLD then p:ChangeGold(1)else p:ChangeFaith(1)end;assert(eligible(c,key,true))
 pending={city=c:GetID(),key=key,cost=cost,unit=x.unit,building=x.building,yield=x.yield,gold=p:GetGold(),faith=p:GetFaith()};reply,event=nil,nil
 LekmodScenarioEvent("fixture-setup",{operation="provided-exact-purchase-budget",city=c:GetID(),key=key,cost=cost})
 if x.unit then
  if x.yield==YieldTypes.YIELD_GOLD then LuaEvents.LekmodScenarioGoldPurchase(c:GetID(),x.unit)else LuaEvents.LekmodScenarioFaithPurchase(c:GetID(),x.unit)end
 else
  if x.yield==YieldTypes.YIELD_GOLD then LuaEvents.LekmodScenarioBuildingPurchase(c:GetID(),x.building)else LuaEvents.LekmodScenarioFaithBuildingPurchase(c:GetID(),x.building)end
 end
end
local function response(kind,id)reply={kind=kind,id=id}end
LuaEvents.LekmodScenarioTradeResponse.Add(response);LuaEvents.LekmodScenarioReligionResponse.Add(response);LuaEvents.LekmodScenarioCityResponse.Add(response)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
 if owner==0 and pending and pending.unit and city==pending.city then local u=Players[owner]:GetUnitByID(id);if u and u:GetUnitType()==pending.unit then assert(not event);event={id=id,gold=gold,faith=faith}end end
end)
GameEvents.CityConstructed.Add(function(owner,city,id,gold,faith)
 if owner==0 and pending and pending.building==id and city==pending.city then assert(not event);event={id=id,gold=gold,faith=faith}end
end)
local function purchased()
 if not LekmodScenarioAwait("first-discount-purchase",reply and event)then return false end
 local p=Players[0];assert(reply.kind=="purchase"and reply.id==(pending.unit or pending.building))
 assert(event.gold==(pending.yield==YieldTypes.YIELD_GOLD)and event.faith==(pending.yield==YieldTypes.YIELD_FAITH))
 assert(p:GetGold()==pending.gold-(event.gold and pending.cost or 0)and p:GetFaith()==pending.faith-(event.faith and pending.cost or 0),"purchase debit differs from independent quote")
 if pending.building then assert(p:GetCityByID(pending.city):GetNumRealBuilding(pending.building)==1)else assert(p:GetUnitByID(event.id))end
 LekmodScenarioEvent("native-first-discount-purchase",{city=pending.city,key=pending.key,cost=pending.cost,gold=event.gold,faith=event.faith,result=event.id});return true
end
local function city(p)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then p:Found(q:GetX(),q:GetY());return assert(q:GetPlotCity())end
 end
 error("no legal input city")
end
function LekmodScenario.snapshot(p)
 local cities,units={},{}
 for c in p:Cities()do local q={};for _,key in ipairs({"unit_gold","unit_faith","building_gold","building_faith"})do q[key]=quote(c,key)end
  cities[c:GetID()]={x=c:GetX(),y=c:GetY(),religion=c:GetReligiousMajority(),treasury=c:GetNumRealBuilding(treasury),granary=c:GetNumRealBuilding(granary),mandir=c:GetNumRealBuilding(mandir),quotes=q,project=c:GetProjectPurchaseCost(project)}
 end
 for u in p:Units()do if u:GetUnitType()==warrior or u:GetUnitType()==missionary then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft()}end end
 return {turn=Game.GetGameTurn(),mode=mode,gold=p:GetGold(),faith=p:GetFaith(),cities=cities,units=units}
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MALI and not Game.IsOption("GAMEOPTION_NO_RELIGION"))
 if phase=="init"then
  assert(not p:HasPolicy(GameInfoTypes.POLICY_MANDATE_OF_HEAVEN)and not p:HasPolicy(GameInfoTypes.POLICY_SKYSCRAPERS))
  assert(GameInfo.Buildings[treasury].FirstPurchaseDiscount==25 and GameDefines.PROJECT_PURCHASING_DISABLED==1)
  for policy in GameInfo.Policies()do if p:HasPolicy(policy.ID)and not p:IsPolicyBlocked(policy.ID)then assert(policy.UnitPurchaseCostModifier==0 and policy.BuildingPurchaseCostModifier==0 and policy.FaithCostModifier==0,"purchase-modifying policy must be separate")end end
  LekmodScenarioGrantTech(p,"TECH_POTTERY");local ca,cb=city(p),city(p);aID,bID=ca:GetID(),cb:GetID()
  assert(ca:GetNumBuilding(granary)==0 and ca:GetNumBuilding(mandir)==0 and cb:GetNumBuilding(granary)==0)
  assert(not p:HasCreatedReligion()and Game.GetNumReligionsStillToFound()>0)
  local taken={};for owner=0,GameDefines.MAX_CIV_PLAYERS-1 do local q=Players[owner];if q and q:IsAlive()and q:HasCreatedReligion()then taken[q:GetReligionCreatedByPlayer()]=true end end
  local religion;for info in GameInfo.Religions()do if info.ID>0 and not taken[info.ID]then religion=info.ID;break end end
  local founder,follower=false,false
  for _,id in ipairs(Game.GetAvailableFounderBeliefs())do if id==GameInfoTypes.BELIEF_TITHE then founder=true end end
  for _,id in ipairs(Game.GetAvailableFollowerBeliefs())do if id==GameInfoTypes.BELIEF_MANDIRS then follower=true end end
  assert(religion and founder and follower,"fixture requires available Tithe/Mandirs")
  Game.FoundReligion(0,religion,nil,GameInfoTypes.BELIEF_TITHE,GameInfoTypes.BELIEF_MANDIRS,-1,-1,p:GetCapitalCity())
  assert(p:GetReligionCreatedByPlayer()==religion)
  ca:ConvertPercentFollowers(religion,-1,100);cb:ConvertPercentFollowers(religion,-1,100);assert(ca:GetReligiousMajority()==religion and cb:GetReligiousMajority()==religion)
  check(ca,false,"before-Treasury");check(cb,false,"control-baseline")
  for info in GameInfo.Buildings()do if info.ID~=granary and info.ID~=mandir and info.ID~=treasury and info.Cost>0 and info.HurryCostModifier~=-1 and cb:IsCanPurchase(false,true,-1,info.ID,-1,YieldTypes.YIELD_GOLD)then control=info.ID;break end end
  assert(control,"no legal unrelated control-city purchase");ca:SetNumRealBuilding(treasury,1);assert(ca:GetNumActiveBuilding(treasury)==1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-Treasury-and-religion-cities",city=aID,control=bID,religion=religion,discount=25})
  check(ca,true,"first-purchase-ready");check(cb,false,"unmodified-control")
  LekmodScenarioRecord("first-discount-baseline","PASS","independent full prices before provided Treasury; correct25percent modifier afterward")
  LekmodScenarioRecord("first-discount-all-quotes","PASS","unit/building gold/faith and disabled-project quote use discount before visible rounding")
  buy(cb,"control",false);phase="control"
 elseif phase=="control"then
  if not purchased()then return false end;check(a(),true,"after-control-city-purchase")
  LekmodScenarioRecord("first-discount-city-scope","PASS","real purchase in another city leaves this city's first discount available")
  buy(a(),pair[1],true);phase="first"
 elseif phase=="first"then
  if not purchased()then return false end;check(a(),false,"after-first-purchase")
  LekmodScenarioRecord("first-discount-first-debit","PASS","original popup callback/native event spends exactly the discounted quote")
  LekmodScenarioRecord("first-discount-shared-counter","PASS","one purchase removes discount from all four currency/type quote paths")
  buy(a(),pair[2],false);phase="second"
 elseif phase=="second"then
  if not purchased()then return false end;check(a(),false,"after-second-purchase")
  LekmodScenarioRecord("first-discount-second-debit","PASS","different currency/type purchase in the same turn spends the undiscounted quote")
  p:ChangeGold(1000);lastTurn=Game.GetGameTurn();phase="round";return "turn"
 elseif phase=="round"then
  if Game.GetGameTurn()==lastTurn then return "turn"end;assert(Game.GetGameTurn()==lastTurn+1);check(a(),true,"after-normal-owner-round")
  LekmodScenarioRecord("first-discount-owner-reset","PASS","ordinary city/owner turn restores the first-purchase discount without setting its counter")
  local third=a():GetNumBuilding(granary)==0 and"building_gold"or"building_faith";buy(a(),third,true);phase="third"
 elseif phase=="third"then
  if not purchased()then return false end;check(a(),false,"spent-after-reset")
  LekmodScenarioRecord("first-discount-reset-debit","PASS","normal purchase after reset spends the discounted quote and consumes it again")
  LekmodScenarioRecord("first-discount-project-disabled","PASS","project quote responds to the same state, but configured project purchase remains rejected")
  LekmodScenarioRecord("first-discount-spent-save","PASS","spent-discount prices and actual purchases retained for exact replay in the same turn");return true
 end
 return false
end
