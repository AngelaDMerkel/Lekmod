-- Native method surface: GameCore
-- Religion, enhancement, research, one policy choice, purchase budgets and unit
-- parking are inputs. Original purchase callbacks must perform all acquisitions.
LekmodScenario={name="faith-cost-modifiers",items={"faith-modifier-data","faith-religion-gates","faith-era-gate","faith-baseline-prices","faith-native-policy","faith-positive-exclusions","faith-founder-owner-control","faith-unit-purchases","faith-building-purchases","faith-prophet-price-sequence","faith-budget-debits"}}
local civ=assert(LekmodScenarioParameters.civ);local founderMode=assert(LekmodScenarioParameters.founder)
local config={mali={civ="CIVILIZATION_MALI",trait="TRAIT_MALI",faith=0,first=0},madagascar={civ="CIVILIZATION_MADAGASCAR",trait="TRAIT_MALAGASY",faith=-25,first=0},lithuania={civ="CIVILIZATION_LITHUANIA",trait="TRAIT_BALTIC",faith=0,first=-50}}
local founderOwner=civ=="lithuania"and 1 or 0
local cfg=assert(config[civ]);local founderName=({tithe="BELIEF_TITHE",zeal="BELIEF_MISSIONARY_ZEAL",messiah="BELIEF_MESSIAH"})[founderMode]
local founder=assert(GameInfoTypes[founderName]);local mandate=GameInfoTypes.POLICY_MANDATE_OF_HEAVEN
local phase,religion,before,choice,adopted,queue,index,pending,reply,event="init",nil,nil,nil,false,{},1,nil,nil,nil
local paidProphets=0
local function div(n,d)return n<0 and math.ceil(n/d)or math.floor(n/d)end
local function round(n,d)return div(n,d)*d end
local function cap(owner)return assert(Players[owner]:GetCapitalCity())end
local function modifiers(p)
 if p:GetID()==0 then return cfg.faith,cfg.first end;return 0,0
end
local function scale(p,n,kind)
 n=div(n*GameInfo.GameSpeeds[Game.GetGameSpeedType()][kind],100)
 if not p:IsHuman()then n=div(n*GameInfo.HandicapInfos[Game.GetHandicapType()][kind=="TrainPercent"and"AITrainPercent"or"AIConstructPercent"],100)end
 return n
end
local function prophet(p,count,minimum)
 local n=GameDefines.RELIGION_MIN_FAITH_FIRST_PROPHET+GameDefines.RELIGION_FAITH_DELTA_NEXT_PROPHET*count*(count+1)/2
 if p:GetID()==founderOwner then n=div(n*(100+GameInfo.Beliefs[founder].ProphetCostModifier),100)end
 local _,first=modifiers(p);if count==0 then n=div(n*(100+first),100)end
 if minimum then return round(scale(p,n,"TrainPercent"),GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR)end
 n=round(n,GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR);return round(scale(p,n,"TrainPercent"),GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR)
end
local function unitPrice(p,c,info,beliefs,active,count)
 if info.Special=="SPECIALUNIT_PEOPLE"then
  if info.Class=="UNITCLASS_PROPHET"and p:GetCurrentEra()>=GameInfoTypes.ERA_INDUSTRIAL then return prophet(p,count,false)end
  return 0
 end
 local n=div(info.FaithCost*GameInfo.Eras[Teams[p:GetTeam()]:GetCurrentEra()].FaithCostMultiplier,100)
 if info.SpreadReligion or info.RemoveHeresy then local faith=modifiers(p);n=div(n*(100+faith+(active and -20 or 0)),100)end
 n=scale(p,n,"TrainPercent")
 if beliefs and info.SpreadReligion and not info.FoundReligion and p:GetID()==founderOwner and c:GetReligiousMajority()==religion then n=div(n*(100+GameInfo.Beliefs[founder].MissionaryCostModifier),100)end
 return round(n,GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR)
end
local function buildingPrice(p,c,b,active)
 local n=b.FaithCost
 if n<=0 and c:GetReligiousMajority()==religion then
  for r in GameInfo.Beliefs_BuildingPurchaseFaithGold{BeliefType="BELIEF_SANCTIFIED_INNOVATIONS",BuildingClassType=b.BuildingClass,YieldType="YIELD_FAITH"}do n=r.Cost+r.IncrementalCostPerCity*p:GetNumCities()end
 end
 n=div(n*GameInfo.Eras[Teams[p:GetTeam()]:GetCurrentEra()].FaithCostMultiplier,100)
 if n>0 then local faith=modifiers(p);local policy=active and b.FaithCost>0 and b.UnlockedByBelief and b.Cost==-1 and -20 or 0;n=div(n*(100+faith+policy),100)end
 return round(scale(p,n,"ConstructPercent"),2*GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR)
end
local function matrix(p,c)
 local units,buildings={},{}
 for info in GameInfo.Units()do units[info.ID]={without=c:GetUnitFaithPurchaseCost(info.ID,false),with=c:GetUnitFaithPurchaseCost(info.ID,true)}end
 for info in GameInfo.Buildings()do buildings[info.ID]=c:GetBuildingFaithPurchaseCost(info.ID)end
 return {era=p:GetCurrentEra(),cities=p:GetNumCities(),units=units,buildings=buildings}
end
local function checkMatrix(active,label)
 local owners={};local comparisons=0
 for owner=0,1 do local p=Players[owner];local c=cap(owner);local actual=matrix(p,c);local policy=owner==0 and active;local count=owner==0 and paidProphets or 0
  for info in GameInfo.Units()do
   assert(actual.units[info.ID].without==unitPrice(p,c,info,false,policy,count),"unit no-belief price "..info.Type)
   assert(actual.units[info.ID].with==unitPrice(p,c,info,true,policy,count),"unit belief price "..info.Type);comparisons=comparisons+2
  end
  for info in GameInfo.Buildings()do assert(actual.buildings[info.ID]==buildingPrice(p,c,info,policy),"building price "..info.Type);comparisons=comparisons+1 end
  owners[owner]=actual
 end
 assert(Players[0]:GetMinimumFaithNextGreatProphet()==prophet(Players[0],paidProphets,true))
 LekmodScenarioEvent("native-faith-price-matrix",{label=label,civ=civ,founder=founderMode,founder_owner=founderOwner,policy=active,paid_prophets=paidProphets,speed=Game.GetGameSpeedType(),handicap=Game.GetHandicapType(),minimum_prophet=Players[0]:GetMinimumFaithNextGreatProphet(),comparisons=comparisons,owners=owners});return owners
end
local function unitFor(p,class)
 local name=GameInfo.UnitClasses[class].DefaultUnit
 for r in GameInfo.Civilization_UnitClassOverrides{CivilizationType=GameInfo.Civilizations[p:GetCivilizationType()].Type,UnitClassType=class}do name=r.UnitType end
 return assert(GameInfoTypes[name])
end
local function can(c,u,b,funds)return c:IsCanPurchase(funds,true,u or -1,b or -1,-1,YieldTypes.YIELD_FAITH)end
local function has(list,id)for _,v in ipairs(list)do if v==id then return true end end;return false end
local function park(p,u)
 local c=p:GetCapitalCity()
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if not q:IsCity()and not q:IsWater()and not q:IsMountain()and q:GetNumUnits()==0 and(q:GetOwner()==-1 or q:GetOwner()==0)and Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<=4 then
   u:SetXY(q:GetX(),q:GetY(),false,true,true);assert(u:GetPlot():GetPlotIndex()==i);LekmodScenarioEvent("fixture-setup",{operation="parked-purchased-unit",unit=u:GetID(),plot=i});return
  end
 end
 error("no nearby unit parking input")
end
GameEvents.PlayerAdoptPolicy.Add(function(owner,id)if owner==0 and id==mandate then adopted=true end end)
LuaEvents.LekmodScenarioReligionResponse.Add(function(kind,id)reply={kind=kind,id=id}end)
LuaEvents.LekmodScenarioCityResponse.Add(function(kind,id)reply={kind=kind,id=id}end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
 if owner==0 and pending and pending.unit and city==cap(0):GetID()then local u=Players[0]:GetUnitByID(id);if u and u:GetUnitType()==pending.unit then assert(not event);event={id=id,gold=gold,faith=faith}end end
end)
GameEvents.CityConstructed.Add(function(owner,city,id,gold,faith)
 if owner==0 and pending and pending.building==id and city==cap(0):GetID()then assert(not event);event={id=id,gold=gold,faith=faith}end
end)
function LekmodScenario.snapshot(p)
 local owners={}
 for owner=0,1 do local o=Players[owner];local c=cap(owner);local units={}
  for u in o:Units()do local info=GameInfo.Units[u:GetUnitType()];if info.SpreadReligion or info.RemoveHeresy then units[u:GetID()]={type=u:GetUnitType(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),x=u:GetX(),y=u:GetY()}end end
  owners[owner]={civ=o:GetCivilizationType(),faith=o:GetFaith(),gold=o:GetGold(),religion=o:GetReligionCreatedByPlayer(),majority=c:GetReligiousMajority(),mandate=o:HasPolicy(mandate),free=o:GetNumFreePolicies(),tenets=o:GetNumFreeTenets(),next_policy=o:GetNextPolicyCost(),minimum_prophet=o:GetMinimumFaithNextGreatProphet(),quotes=matrix(o,c),units=units,mandir=c:GetNumRealBuilding(GameInfoTypes.BUILDING_MANDIR),rova=c:GetNumRealBuilding(GameInfoTypes.BUILDING_ROVA)}
 end
 return {civ=civ,founder=founderMode,founder_owner=founderOwner,turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 local c=cap(0);assert(not Game.IsGameMultiPlayer()and p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes[cfg.civ]and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and p:GetTeam()~=Players[1]:GetTeam())
 local missionary=unitFor(p,"UNITCLASS_MISSIONARY");local inquisitor=unitFor(p,"UNITCLASS_INQUISITOR");local prophetUnit=unitFor(p,"UNITCLASS_PROPHET")
 if phase=="init"then
  assert(not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION))
  assert(not p:HasCreatedReligion()and not p:HasPolicy(mandate)and p:GetNumCities()==1)
  if civ~="mali"then assert(GameInfo.Traits[cfg.trait].FaithCostModifier==cfg.faith and GameInfo.Traits[cfg.trait].FirstProphetCostMod==cfg.first)end
  assert(GameInfo.Policies[mandate].FaithCostModifier==-20)
  for b in GameInfo.Buildings()do if b.FirstPurchaseDiscount and b.FirstPurchaseDiscount~=0 then assert(c:GetNumBuilding(b.ID)==0)end end
  assert(not can(c,missionary,nil,false)and not can(c,inquisitor,nil,false));assert(c:GetUnitFaithPurchaseCost(prophetUnit,true)==0)
  LekmodScenarioRecord("faith-modifier-data","PASS","policy-20, Madagascar-25/all faith buildings, Lithuania-50/first Prophet and configured founder modifiers identified; no Treasury discount")
  local taken={};for owner=0,GameDefines.MAX_CIV_PLAYERS-1 do local o=Players[owner];if o and o:IsAlive()and o:HasCreatedReligion()then taken[o:GetReligionCreatedByPlayer()]=true end end
  for row in GameInfo.Religions()do if row.ID>0 and not taken[row.ID]then religion=row.ID;break end end
  assert(religion and has(Game.GetAvailableFounderBeliefs(),founder)and has(Game.GetAvailableFollowerBeliefs(),GameInfoTypes.BELIEF_MANDIRS))
  Game.FoundReligion(founderOwner,religion,nil,founder,GameInfoTypes.BELIEF_MANDIRS,-1,-1,cap(founderOwner));assert(Players[founderOwner]:GetReligionCreatedByPlayer()==religion)
  if founderOwner~=0 then c:ConvertPercentFollowers(religion,-1,100);assert(not p:HasCreatedReligion())end
  assert(c:GetReligiousMajority()==religion and not can(c,inquisitor,nil,false))
  assert(has(Game.GetAvailableFollowerBeliefs(),GameInfoTypes.BELIEF_HOLY_WARRIORS)and has(Game.GetAvailableEnhancerBeliefs(),GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS))
  Game.EnhanceReligion(founderOwner,religion,GameInfoTypes.BELIEF_HOLY_WARRIORS,GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS);phase="enhanced"
 elseif phase=="enhanced"then
  if not LekmodScenarioAwait("faith-enhancement",has(Game.GetBeliefsInReligion(religion),GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS))then return false end
  assert(can(c,inquisitor,nil,false));cap(1):ConvertPercentFollowers(religion,-1,100);assert(cap(1):GetReligiousMajority()==religion)
  LekmodScenarioRecord("faith-religion-gates","PASS","religious units rejected without religion; Inquisitor becomes eligible only after native enhancement; foreign city conversion is an explicit control input")
  assert(c:GetUnitFaithPurchaseCost(prophetUnit,true)==0 and not can(c,prophetUnit,nil,false));LekmodScenarioGrantTech(p,"TECH_INDUSTRIALIZATION");assert(p:GetCurrentEra()>=GameInfoTypes.ERA_INDUSTRIAL and c:GetUnitFaithPurchaseCost(prophetUnit,true)==prophet(p,0,false)and can(c,prophetUnit,nil,false))
  LekmodScenarioRecord("faith-era-gate","PASS","Prophet manual faith purchase has no pre-Industrial quote; required research enables the independent first-price formula")
  p:SetPolicyBranchUnlocked(GameInfoTypes.POLICY_BRANCH_PIETY,true,false);choice=LekmodScenarioPolicyChoice(p,mandate);before=checkMatrix(false,"before-policy")
  LekmodScenarioRecord("faith-baseline-prices","PASS","all unit belief-on/off and building faith quotes match source-derived integer arithmetic for both owners before policy")
  Network.SendUpdatePolicies(mandate,true,true);phase="policy"
 elseif phase=="policy"then
  if not LekmodScenarioAwait("faith-policy",adopted and p:HasPolicy(mandate))then return false end
  LekmodScenarioVerifyPolicyChoice(p,mandate,choice);local after=checkMatrix(true,"after-policy");assert(LekmodScenarioJSON(after[1])==LekmodScenarioJSON(before[1]))
  assert(after[0].units[inquisitor].with<before[0].units[inquisitor].with and after[0].units[prophetUnit].with==before[0].units[prophetUnit].with)
  assert(after[0].buildings[GameInfoTypes.BUILDING_WORKSHOP]==before[0].buildings[GameInfoTypes.BUILDING_WORKSHOP]and after[0].buildings[GameInfoTypes.BUILDING_NATIONAL_COLLEGE]==before[0].buildings[GameInfoTypes.BUILDING_NATIONAL_COLLEGE])
  assert(not can(c,GameInfoTypes.UNIT_MAURYA_MISSIONARY,nil,false)and not can(c,GameInfoTypes.UNIT_DALAILAMA,nil,false))
  LekmodScenarioRecord("faith-native-policy","PASS","native adoption consumes one valid choice and preserves culture/free-policy/tenet history")
  LekmodScenarioRecord("faith-positive-exclusions","PASS","additive religious discounts apply; ordinary units/GPs, non-faith-native building policy exceptions and positive Sanctified costs are independently checked")
  LekmodScenarioRecord("faith-founder-owner-control","PASS","belief-on/off missionary-only founder discount and Prophet belief costs match; foreign owner matrix unchanged by policy and foreign replacements cannot be bought")
  queue={{unit=missionary},{unit=inquisitor},{building=GameInfoTypes.BUILDING_MANDIR},{unit=prophetUnit},{unit=prophetUnit}}
  if civ=="madagascar"then LekmodScenarioGrantTech(p,"TECH_MASONRY");queue[#queue+1]={building=GameInfoTypes.BUILDING_ROVA}end
  phase="buy"
 elseif phase=="buy"then
  local item=queue[index]
  if not item then
   checkMatrix(true,"after-purchases");assert(paidProphets==2)
   LekmodScenarioRecord("faith-unit-purchases","PASS","original callbacks bought own Missionary and Inquisitor replacement; actual religion/spread state and debits verified")
   LekmodScenarioRecord("faith-building-purchases","PASS","actual Mandir purchase uses combined policy/trait rate; Madagascar Rova uses trait-only rate")
   LekmodScenarioRecord("faith-prophet-price-sequence","PASS","two actual Prophet purchases consume escalating prices; first-only trait expires, founder discount persists, policy/religious-unit trait do not apply; threshold and purchase rounding checked separately")
   LekmodScenarioRecord("faith-budget-debits","PASS","every cost-minus-one budget rejects, exact budget accepts, native purchase events/debits verified; no final unit/building/price/counter assigned")
   return true
  end
  local cost=item.unit and unitPrice(p,c,GameInfo.Units[item.unit],true,true,paidProphets)or buildingPrice(p,c,GameInfo.Buildings[item.building],true)
  assert(cost>1 and can(c,item.unit,item.building,false));p:ChangeFaith(cost-1-p:GetFaith());assert(not can(c,item.unit,item.building,true));p:ChangeFaith(1);assert(can(c,item.unit,item.building,true))
  pending={unit=item.unit,building=item.building,cost=cost,gold=p:GetGold(),faith=p:GetFaith()};reply,event=nil,nil
  LekmodScenarioEvent("fixture-setup",{operation="provided-exact-faith-budget",index=index,unit=item.unit,building=item.building,cost=cost})
  if item.unit then LuaEvents.LekmodScenarioFaithPurchase(c:GetID(),item.unit)else LuaEvents.LekmodScenarioFaithBuildingPurchase(c:GetID(),item.building)end;phase="bought"
 elseif phase=="bought"then
  if not LekmodScenarioAwait("faith-purchase-result",reply and event)then return false end
  assert(reply.kind=="purchase"and reply.id==(pending.unit or pending.building)and not event.gold and event.faith and p:GetGold()==pending.gold and p:GetFaith()==pending.faith-pending.cost)
  local detail={civ=civ,founder=founderMode,index=index,unit=pending.unit,building=pending.building,cost=pending.cost,result=event.id}
  if pending.unit then
   local u=assert(p:GetUnitByID(event.id));local info=GameInfo.Units[pending.unit];local expectedReligion=info.FoundReligion and p:GetReligionCreatedByPlayer()or religion;assert(u:GetReligion()==expectedReligion)
   local spreads=info.ReligionSpreads;if (info.SpreadReligion or info.RemoveHeresy)and not info.FoundReligion and founderOwner==0 then spreads=spreads+GameInfo.Beliefs[founder].MissionaryExtraSpreads end
   if expectedReligion>0 then assert(u:GetSpreadsLeft()==spreads)end;detail.spreads=u:GetSpreadsLeft();detail.religion=u:GetReligion()
   if info.Class=="UNITCLASS_PROPHET"then paidProphets=paidProphets+1;assert(c:GetUnitFaithPurchaseCost(prophetUnit,true)==prophet(p,paidProphets,false)and p:GetMinimumFaithNextGreatProphet()==prophet(p,paidProphets,true));detail.next_prophet=c:GetUnitFaithPurchaseCost(prophetUnit,true);detail.minimum_prophet=p:GetMinimumFaithNextGreatProphet()end
   park(p,u)
  else assert(c:GetNumRealBuilding(pending.building)==1)end
  LekmodScenarioEvent("native-faith-modifier-purchase",detail);index=index+1;phase="buy"
 end
 return false
end
