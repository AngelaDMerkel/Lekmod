-- Native method surface: GameCore
-- Research/prerequisite buildings, valid religion/enhancement, conversion, one
-- extra city and exact budgets are inputs. Price/rejection/purchase/replay are
-- native outcomes. No target building, price or purchase counter is assigned.
LekmodScenario={name="sanctified-national-purchases",items={"sanctified-configured-row","sanctified-no-belief-control","sanctified-native-enhancement","sanctified-one-city-price","sanctified-city-count-price","sanctified-city-religion-control","sanctified-foreign-owner-price","sanctified-budget-boundary","sanctified-native-purchase","sanctified-repeat-rejected"}}
local class=assert(LekmodScenarioParameters.class)
local phase,building,religion,extraID,price,reply,event,freeBefore,pendingTech="init"
local ideologyPending=false
local belief=GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS
local function cap(owner)return assert(Players[owner]:GetCapitalCity())end
local function has(list,id)for _,x in ipairs(list)do if x==id then return true end end;return false end
local function replacement(p,kind)
 local info=assert(GameInfo.BuildingClasses[kind]);local result=info.DefaultBuilding
 for row in GameInfo.Civilization_BuildingClassOverrides{CivilizationType=GameInfo.Civilizations[p:GetCivilizationType()].Type,BuildingClassType=kind}do result=row.BuildingType end
 return assert(GameInfoTypes[result],"building class has no valid owner replacement")
end
local function prereqs(p,c)
 local info=GameInfo.Buildings[building];if info.PrereqTech then LekmodScenarioGrantTech(p,info.PrereqTech)end
 for row in GameInfo.Building_TechAndPrereqs{BuildingType=info.Type}do LekmodScenarioGrantTech(p,row.TechType)end
 for row in GameInfo.Building_ClassesNeededInCity{BuildingType=info.Type}do local id=replacement(p,row.BuildingClassType);assert(id~=building);if c:GetNumBuilding(id)==0 then c:SetNumRealBuilding(id,1)end end
 for row in GameInfo.Building_PrereqBuildingClasses{BuildingType=info.Type}do local id=replacement(p,row.BuildingClassType);assert(id~=building);for owned in p:Cities()do if owned:GetNumBuilding(id)==0 then owned:SetNumRealBuilding(id,1)end end end
 LekmodScenarioEvent("fixture-setup",{operation="provided-national-prerequisites",owner=p:GetID(),building=info.Type,cities=p:GetNumCities()})
end
local function amount(p)
 local raw=300+75*p:GetNumCities();local era=Teams[p:GetTeam()]:GetCurrentEra()
 local n=math.floor(raw*GameInfo.Eras[era].FaithCostMultiplier/100);n=math.floor(n*GameInfo.GameSpeeds[Game.GetGameSpeedType()].ConstructPercent/100)
 if not p:IsHuman()then n=math.floor(n*GameInfo.HandicapInfos[Game.GetHandicapType()].AIConstructPercent/100)end
 return math.floor(n/(2*GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR))*(2*GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR)
end
local function canBuy(c,funds)return c:IsCanPurchase(funds,true,-1,building,-1,YieldTypes.YIELD_FAITH)end
local function convert(c)
 for row in GameInfo.Religions()do if row.ID~=religion and c:GetNumFollowers(row.ID)>0 then c:ConvertPercentFollowers(religion,row.ID,100)end end
 if c:GetNumFollowers(-1)>0 then c:ConvertPercentFollowers(religion,-1,100)end
 assert(c:GetReligiousMajority()==religion)
end
LuaEvents.LekmodScenarioCityResponse.Add(function(kind,id)reply={kind=kind,id=id}end)
GameEvents.CityConstructed.Add(function(owner,city,b,gold,faith)
 if owner==0 and b==building then assert(not event and city==cap(0):GetID()and not gold and faith);event={city=city,building=b,gold=gold,faith=faith};LekmodScenarioEvent("native-Sanctified-purchase",event)end
end)
function LekmodScenario.snapshot(p)
 local owners={};local target=replacement(p,class)
 for owner=0,1 do local q=Players[owner];local cities={}
  for c in q:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),majority=c:GetReligiousMajority(),holy=q:GetReligionCreatedByPlayer()>0 and c:IsHolyCityForReligion(q:GetReligionCreatedByPlayer())or false,target=c:GetNumRealBuilding(target),faith_quote=c:GetBuildingFaithPurchaseCost(target),gold_quote=c:GetBuildingPurchaseCost(target),faith_eligible=c:IsCanPurchase(false,true,-1,target,-1,YieldTypes.YIELD_FAITH)}end
  owners[owner]={civ=q:GetCivilizationType(),cities=cities,count=q:GetNumCities(),faith=q:GetFaith(),gold=q:GetGold(),religion=q:GetReligionCreatedByPlayer(),era=Teams[q:GetTeam()]:GetCurrentEra(),free_techs=q:GetNumFreeTechs(),free_policies=q:GetNumFreePolicies(),free_tenets=q:GetNumFreeTenets(),culture=q:GetJONSCulture(),next_policy_cost=q:GetNextPolicyCost()}
 end
 local known={};for row in GameInfo.Technologies()do if Teams[p:GetTeam()]:IsHasTech(row.ID)then known[row.ID]=true end end
 return {turn=Game.GetGameTurn(),class=class,owners=owners,human_beliefs=Game.GetBeliefsInReligion(p:GetReligionCreatedByPlayer()),known=known}
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MALI and not Game.IsOption("GAMEOPTION_NO_RELIGION"))
 local c=cap(0)
 if ideologyPending then
  if not LekmodScenarioAwait("normal-required-ideology",p:GetLateGamePolicyTree()==GameInfoTypes.POLICY_BRANCH_FREEDOM)then return false end
  ideologyPending=false
 end
 if p:GetEndTurnBlockingType()==EndTurnBlockingTypes.ENDTURN_BLOCKING_CHOOSE_IDEOLOGY then
  assert(p:GetLateGamePolicyTree()==-1);ideologyPending=true
  Network.SendIdeologyChoice(p:GetID(),GameInfoTypes.POLICY_BRANCH_FREEDOM)
  LekmodScenarioEvent("fixture-setup",{operation="normal-required-ideology-choice",branch=GameInfoTypes.POLICY_BRANCH_FREEDOM});return false
 end
 if phase=="init"then
  assert(p:GetNumCities()==1 and Players[1]:GetNumCities()==1 and not p:HasCreatedReligion())
  local count=0;local found=false
  for row in GameInfo.Beliefs_BuildingPurchaseFaithGold()do assert(row.BeliefType=="BELIEF_SANCTIFIED_INNOVATIONS"and row.YieldType=="YIELD_FAITH"and row.Cost==300 and row.IncrementalCostPerCity==75);count=count+1;if row.BuildingClassType==class then found=true end end
  assert(count==11 and found);building=replacement(p,class);local info=GameInfo.Buildings[building]
  assert(info.FaithCost==0 and c:GetNumBuilding(building)==0 and c:GetNumBuilding(GameInfoTypes.BUILDING_MALI_NATIONAL_TREASURY)==0)
  assert(not p:HasPolicy(GameInfoTypes.POLICY_MANDATE_OF_HEAVEN))
  local taken={};for owner=0,GameDefines.MAX_CIV_PLAYERS-1 do local q=Players[owner];if q and q:IsAlive()and q:HasCreatedReligion()then taken[q:GetReligionCreatedByPlayer()]=true end end
  for row in GameInfo.Religions()do if row.ID>0 and not taken[row.ID]then religion=row.ID;break end end
  assert(religion and Game.GetNumReligionsStillToFound()>0 and has(Game.GetAvailableFounderBeliefs(),GameInfoTypes.BELIEF_TITHE)and has(Game.GetAvailableFollowerBeliefs(),GameInfoTypes.BELIEF_MANDIRS))
  Game.FoundReligion(0,religion,nil,GameInfoTypes.BELIEF_TITHE,GameInfoTypes.BELIEF_MANDIRS,-1,-1,c);assert(p:GetReligionCreatedByPlayer()==religion);convert(c)
  prereqs(p,c);assert(c:CanConstruct(building),"ordinary prerequisites not met: "..tostring(c:CanConstructTooltip(building)))
  assert(c:GetBuildingFaithPurchaseCost(building)==0 and not canBuy(c,false))
  LekmodScenarioRecord("sanctified-configured-row","PASS","all11configured faith-only rows match300+75per city; target uses owner's actual class replacement")
  LekmodScenarioRecord("sanctified-no-belief-control","PASS","ordinary prerequisites and a majority religion alone do not enable the zero-base faith price")
  assert(has(Game.GetAvailableFollowerBeliefs(),GameInfoTypes.BELIEF_HOLY_WARRIORS)and has(Game.GetAvailableEnhancerBeliefs(),belief))
  Game.EnhanceReligion(0,religion,GameInfoTypes.BELIEF_HOLY_WARRIORS,belief);phase="enhanced"
 elseif phase=="enhanced"then
  if not LekmodScenarioAwait("Sanctified-enhancement",has(Game.GetBeliefsInReligion(religion),belief))then return false end
  assert(c:GetBuildingFaithPurchaseCost(building)==amount(p)and canBuy(c,false)and c:GetBuildingPurchaseCost(building)==-1)
  LekmodScenarioEvent("native-Sanctified-price",{owner=0,count=p:GetNumCities(),raw=375,expected=amount(p),actual=c:GetBuildingFaithPurchaseCost(building),era=Teams[p:GetTeam()]:GetCurrentEra(),building=GameInfo.Buildings[building].Type})
  LekmodScenarioRecord("sanctified-native-enhancement","PASS","valid native enhancement adds the requested enhancer; gold remains unavailable")
  LekmodScenarioRecord("sanctified-one-city-price","PASS","faith quote applies exact raw375 then era/speed/visible rounding")
  local site
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then site=q;break end end
  assert(site);p:Found(site:GetX(),site:GetY());local extra=assert(site:GetPlotCity());extraID=extra:GetID();assert(p:GetNumCities()==2)
  assert(c:GetBuildingFaithPurchaseCost(building)==amount(p));LekmodScenarioEvent("native-Sanctified-price",{owner=0,count=2,raw=450,expected=amount(p),actual=c:GetBuildingFaithPurchaseCost(building),era=Teams[p:GetTeam()]:GetCurrentEra(),building=GameInfo.Buildings[building].Type})
  LekmodScenarioRecord("sanctified-city-count-price","PASS","actual extra city reprices the original city using raw450, including the unconverted city")
  assert(extra:GetReligiousMajority()<=0 and extra:GetBuildingFaithPurchaseCost(building)==0 and not canBuy(extra,false))
  convert(extra);prereqs(p,c);prereqs(p,extra)
  assert(extra:GetBuildingFaithPurchaseCost(building)==amount(p)and canBuy(c,false))
  if GameInfo.Buildings[building].HolyCity==true or GameInfo.Buildings[building].HolyCity==1 then assert(not canBuy(extra,false))end
  LekmodScenarioRecord("sanctified-city-religion-control","PASS","unconverted city has no raw faith price; conversion enables quote while holy-city restriction is preserved where configured")
  assert(cap(1):GetBuildingFaithPurchaseCost(building)==0);convert(cap(1))
  assert(Players[1]:GetNumCities()==1 and cap(1):GetBuildingFaithPurchaseCost(building)==amount(Players[1]))
  LekmodScenarioEvent("native-Sanctified-price",{owner=1,count=1,raw=375,expected=amount(Players[1]),actual=cap(1):GetBuildingFaithPurchaseCost(building),era=Teams[Players[1]:GetTeam()]:GetCurrentEra(),building=GameInfo.Buildings[building].Type})
  LekmodScenarioRecord("sanctified-foreign-owner-price","PASS","shared religion computes the foreign owner's one-city price, not the founder's two-city count")
  price=amount(p);assert(price>1);p:ChangeFaith(price-1-p:GetFaith());assert(not canBuy(c,true));p:ChangeFaith(1);assert(canBuy(c,true))
  LekmodScenarioRecord("sanctified-budget-boundary","PASS","one below independent quote rejected; exact faith amount accepted")
  freeBefore=p:GetNumFreeTechs();reply,event=nil,nil;LuaEvents.LekmodScenarioFaithBuildingPurchase(c:GetID(),building);phase="purchase"
 elseif phase=="purchase"then
  if not LekmodScenarioAwait("Sanctified-purchase",reply and event)then return false end
  assert(reply.kind=="purchase"and reply.id==building and c:GetNumRealBuilding(building)==1 and p:GetFaith()==0)
  assert(p:GetNumFreeTechs()==freeBefore+GameInfo.Buildings[building].FreeTechs)
  LekmodScenarioRecord("sanctified-native-purchase","PASS","original popup callback emits native faith purchase and spends exact independent price="..price)
  for owned in p:Cities()do assert(not canBuy(owned,false))end
  LekmodScenarioRecord("sanctified-repeat-rejected","PASS","national-building repeat rejected throughout owner empire; exact state will reload")
  if p:GetNumFreeTechs()>freeBefore then
   for tech in GameInfo.Technologies()do if p:CanResearchForFree(tech.ID)then pendingTech=tech.ID;Network.SendResearch(tech.ID,p:GetNumFreeTechs(),-1,false);break end end
   assert(pendingTech,"free technology reward has no legal choice");phase="free-tech";return false
  end
  return true
 elseif phase=="free-tech"then
  if not LekmodScenarioAwait("Oxford-free-tech-choice",Teams[p:GetTeam()]:IsHasTech(pendingTech)and p:GetNumFreeTechs()==freeBefore)then return false end
  LekmodScenarioEvent("native-free-tech-choice",{technology=pendingTech,remaining=p:GetNumFreeTechs()});return true
 end
 return false
end
