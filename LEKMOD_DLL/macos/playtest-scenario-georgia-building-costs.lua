-- Native method surface: GameCore
-- Religion/belief, conversion, funding and near-complete hammers are inputs.
-- Trait-derived quotes/rejections and ordinary production are outcomes; no
-- target building, cost, purchase result or owner trait is assigned.
LekmodScenario={name="georgia-building-costs",items={"georgia-religion-gate","georgia-cost-rows","georgia-production-quote","georgia-production-eligibility","georgia-gold-rejection","georgia-matched-religion","georgia-faith-rejection-control","georgia-native-building-production","georgia-building-repeat-control"}}
local kind=assert(LekmodScenarioParameters.building)
local values={BUILDING_CATHEDRAL=75,BUILDING_GURDWARA=135,BUILDING_MANDIR=135,BUILDING_MOSQUE=75,BUILDING_PAGODA=100,BUILDING_SYNAGOGUE=100,BUILDING_VIHARA=75}
local base=assert(values[kind]);local building=assert(GameInfoTypes[kind]);local phase,religion,follower,quote,started="init"
local built,checked=false,false
local function city(owner)return assert(Players[owner]:GetCapitalCity())end
local function purchase(c,y)return c:IsCanPurchase(true,true,-1,building,-1,y)end
local function available(list,id)for _,x in ipairs(list)do if x==id then return true end end;return false end
local function convert(c,to)
 for info in GameInfo.Religions()do if info.ID~=to and c:GetNumFollowers(info.ID)>0 then c:ConvertPercentFollowers(to,info.ID,100)end end
 if c:GetNumFollowers(-1)>0 then c:ConvertPercentFollowers(to,-1,100)end
 assert(c:GetReligiousMajority()==to)
end
GameEvents.CityConstructed.Add(function(owner,id,b,gold,faith)
 if owner==0 and b==building then assert(id==city(0):GetID()and not built and not gold and not faith);built=true;LekmodScenarioEvent("native-Georgia-religious-building",{owner=owner,city=id,building=b,gold=gold,faith=faith})end
end)
function LekmodScenario.snapshot(p)
 local owners={}
 for id=0,1 do local q=Players[id];local cities={}
  for c in q:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),majority=c:GetReligiousMajority(),building=c:GetNumRealBuilding(building),production=c:GetBuildingProductionNeeded(building),can_construct=c:CanConstruct(building),can_gold=purchase(c,YieldTypes.YIELD_GOLD),can_faith=purchase(c,YieldTypes.YIELD_FAITH)}end
  owners[id]={civilization=q:GetCivilizationType(),religion=q:GetReligionCreatedByPlayer(),gold=q:GetGold(),faith=q:GetFaith(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),no_religion=Game.IsOption("GAMEOPTION_NO_RELIGION"),building=kind,speed=Game.GetGameSpeedType(),start_era=Game.GetStartEra(),owners=owners}
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GEORGIA)
 if not checked then
  checked=true;LekmodScenarioEvent("Georgia-fixture-configuration",{human=p:GetCivilizationType(),foreign=Players[1]:GetCivilizationType(),no_religion=Game.IsOption("GAMEOPTION_NO_RELIGION")})
 end
 assert(Players[1]:GetCivilizationType()~=GameInfoTypes.CIVILIZATION_GEORGIA,"foreign control must lack Georgia trait")
 assert(not Game.IsOption("GAMEOPTION_NO_RELIGION"),"fixture has No Religion enabled")
 if not p:GetCapitalCity()or not Players[1]:GetCapitalCity()then return "turn"end
 local c,other=city(0),city(1)
 if phase=="init"then
  local count=0
  for r in GameInfo.Trait_BuildingCostOverride{TraitType="TRAIT_ECCLESIASTICAL_ARCHITECTURE"}do
   assert(values[r.BuildingType]);local expected=r.YieldType=="YIELD_PRODUCTION"and values[r.BuildingType]or -1
   assert((r.YieldType=="YIELD_PRODUCTION"or r.YieldType=="YIELD_GOLD"or r.YieldType=="YIELD_FAITH")and r.Cost==expected);count=count+1
  end
  assert(count==21 and GameInfo.Buildings[building].Cost==-1 and c:GetNumBuilding(building)==0 and other:GetNumBuilding(building)==0)
  LekmodScenarioRecord("georgia-cost-rows","PASS","all21 configured production/gold/faith override values match the source-defined seven-building catalogue")
  quote=math.floor(base*GameDefines.BUILDING_PRODUCTION_PERCENT/100);quote=math.floor(quote*GameInfo.GameSpeeds[Game.GetGameSpeedType()].ConstructPercent/100);quote=math.max(1,math.floor(quote*GameInfo.Eras[Game.GetStartEra()].ConstructPercent/100))
  assert(c:GetBuildingProductionNeeded(building)==quote and p:GetBuildingProductionNeeded(building)==quote and other:GetBuildingProductionNeeded(building)==1)
  LekmodScenarioEvent("native-Georgia-building-quote",{building=kind,base=base,expected=quote,actual=c:GetBuildingProductionNeeded(building),foreign=other:GetBuildingProductionNeeded(building)})
  LekmodScenarioRecord("georgia-production-quote","PASS","positive override replaces base-1 and scales with sequential integer rounding; foreign quote retains the sentinel clamp")
  assert(c:GetReligiousMajority()<=0 and other:GetReligiousMajority()<=0 and not c:CanConstruct(building)and not other:CanConstruct(building))
  LekmodScenarioRecord("georgia-religion-gate","PASS","without a world-religion majority/belief, even Georgia rejects construction despite its positive quote")
  for owner=0,1 do Players[owner]:ChangeGold(10000)end
  assert(not p:HasCreatedReligion()and Game.GetNumReligionsStillToFound()>0)
  for row in GameInfo.Belief_BuildingClassFaithPurchase{BuildingClassType=GameInfo.Buildings[building].BuildingClass}do
   local id=GameInfoTypes[row.BeliefType];if available(Game.GetAvailableFollowerBeliefs(),id)then follower=id;break end
  end
  assert(follower,"target building belief is not available")
  local taken={};for owner=0,GameDefines.MAX_CIV_PLAYERS-1 do local q=Players[owner];if q and q:IsAlive()and q:HasCreatedReligion()then taken[q:GetReligionCreatedByPlayer()]=true end end
  for info in GameInfo.Religions()do if info.ID>0 and not taken[info.ID]then religion=info.ID;break end end
  local founder=GameInfoTypes.BELIEF_TITHE;assert(religion and available(Game.GetAvailableFounderBeliefs(),founder))
  Game.FoundReligion(0,religion,nil,founder,follower,-1,-1,c);assert(p:GetReligionCreatedByPlayer()==religion)
  convert(c,religion);convert(other,religion)
  LekmodScenarioEvent("fixture-setup",{operation="provided-matching-religion-and-belief",religion=religion,founder=founder,follower=follower,building=kind})
  for owner=0,1 do local q=Players[owner];local cost=city(owner):GetBuildingFaithPurchaseCost(building);assert(cost>0);q:ChangeFaith(math.max(0,cost+10-q:GetFaith()))end
  phase="faith"
 elseif phase=="faith"then
  assert(c:GetReligiousMajority()==religion and other:GetReligiousMajority()==religion and available(Game.GetBeliefsInReligion(religion),follower))
  assert(c:GetNumBuilding(building)==0 and other:GetNumBuilding(building)==0)
  assert(p:GetFaith()>=c:GetBuildingFaithPurchaseCost(building)and Players[1]:GetFaith()>=other:GetBuildingFaithPurchaseCost(building))
  LekmodScenarioRecord("georgia-matched-religion","PASS","both capitals follow the same religion containing the exact target building belief; both are funded")
  assert(c:CanConstruct(building)and not other:CanConstruct(building),"matched religion did not enable only Georgian production")
  LekmodScenarioRecord("georgia-production-eligibility","PASS","with the required majority and building belief, only Georgia can normally produce the target")
  local goldQuote=c:GetBuildingPurchaseCost(building);assert(goldQuote>=0 and p:GetGold()>=goldQuote and not purchase(c,YieldTypes.YIELD_GOLD));local ordinary
  for info in GameInfo.Buildings()do if info.Cost>0 and c:IsCanPurchase(true,true,-1,info.ID,-1,YieldTypes.YIELD_GOLD)then ordinary=info.Type;break end end
  assert(ordinary,"no ordinary gold-purchase control")
  LekmodScenarioRecord("georgia-gold-rejection","PASS","funded, religion-matched and production-eligible target rejects gold; unrelated gold purchase remains legal: "..ordinary)
  assert(not purchase(c,YieldTypes.YIELD_FAITH)and purchase(other,YieldTypes.YIELD_FAITH),"trait faith rejection lacks matched positive foreign control")
  LekmodScenarioRecord("georgia-faith-rejection-control","PASS","Georgia rejects faith while the matching foreign city can purchase the same building")
  assert(c:CanConstruct(building));Game.CityPushOrder(c,OrderTypes.ORDER_CONSTRUCT,building,false,true,true);phase="queued"
 elseif phase=="queued"then
  if not LekmodScenarioAwait("Georgia-religious-building-order",c:GetProductionBuilding()==building)then return false end
  assert(quote>1 and c:GetBuildingProductionNeeded(building)==quote);c:SetBuildingProduction(building,quote-1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-Georgia-production",building=kind,cost=quote,hammers=quote-1});started=Game.GetGameTurn();phase="production";return "turn"
 elseif phase=="production"then
  if not built then assert(Game.GetGameTurn()-started<3,"normal production exceeded bounded turns");return "turn"end
  assert(c:GetNumRealBuilding(building)==1)
  LekmodScenarioRecord("georgia-native-building-production","PASS","unforced normal human queue completes and emits non-purchase CityConstructed")
  assert(not c:CanConstruct(building)and not purchase(c,YieldTypes.YIELD_GOLD)and not purchase(c,YieldTypes.YIELD_FAITH))
  LekmodScenarioRecord("georgia-building-repeat-control","PASS","completed building cannot be constructed or purchased again; exact replay follows");return true
 end
 return false
end
