-- Theology, Temples, a legal extra city, religion founding and hammers are inputs.
-- Native production must enforce holy-city eligibility and issue its free rewards.
LekmodScenario={name="vatican-stpeters",items={"stpeters-holy-city-gate","stpeters-production","stpeters-free-cathedral","stpeters-free-prophet","stpeters-faith"}}
local phase,cityID,extraID,before,built,queued="init",nil,nil,nil,false,false
local building=GameInfoTypes.BUILDING_STPETERS
local cathedral=GameInfoTypes.BUILDING_CATHEDRAL
local prophets={}
local function faith(c)
 local p=Players[c:GetOwner()];local policy=0
 for info in GameInfo.Buildings()do policy=policy+c:GetNumBuilding(info.ID)*p:GetPolicyBuildingClassYieldChange(GameInfoTypes[info.BuildingClass],YieldTypes.YIELD_FAITH)end
 return c:GetBaseYieldRateFromBuildings(YieldTypes.YIELD_FAITH)-policy
end
function LekmodScenario.snapshot(player)
 local p=Players[1];local cities,units,policies={},{},{}
 for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),holy=c:IsHolyCityAnyReligion(),religion=c:GetReligiousMajority(),population=c:GetPopulation(),stpeters=c:GetNumRealBuilding(building),cathedral=c:GetNumBuilding(cathedral),real_cathedral=c:GetNumRealBuilding(cathedral),faith_buildings=faith(c),faith_rate=c:GetYieldRateTimes100(YieldTypes.YIELD_FAITH)}end
 for u in p:Units()do if not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),x=u:GetX(),y=u:GetY()}end end
 for info in GameInfo.Policies()do if p:HasPolicy(info.ID)then policies[info.Type]=true end end
 return {turn=Game.GetGameTurn(),religion=p:GetReligionCreatedByPlayer(),faith=p:GetFaith(),cities=cities,units=units,policies=policies}
end
GameEvents.CityConstructed.Add(function(owner,city,b,gold,faith)
 if owner==1 and b==building then assert(not gold and not faith);built=true;LekmodScenarioEvent("native-stpeters-production",{owner=owner,city=city})end
end)
GameEvents.UnitCreated.Add(function(owner,id)
 if owner==1 and phase=="production"then local u=Players[owner]:GetUnitByID(id)
  if u and u:GetUnitType()==GameInfoTypes.UNIT_PROPHET then prophets[id]=true;LekmodScenarioEvent("native-stpeters-prophet",{owner=owner,unit=id})end
 end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or phase~="production"or queued then return end
 local p=Players[owner];assert(not p:IsHuman()and p:IsTurnActive());local c=assert(p:GetCityByID(cityID))
 assert(c:CanConstruct(building));c:PushOrder(OrderTypes.ORDER_CONSTRUCT,building,-1,0,true,false,0)
 assert(c:GetProductionBuilding()==building);local cost=c:GetBuildingProductionNeeded(building);assert(cost>1)
 c:SetBuildingProduction(building,cost-1);queued=true
 LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-St-Peters",owner=owner,city=cityID,hammers=cost-1,cost=cost})
end)
function LekmodScenario.step(player)
 local p=Players[1];assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_VATICAN)
 local c=assert(p:GetCapitalCity());cityID=c:GetID()
 if phase=="init"then
  LekmodScenarioGrantTech(p,"TECH_THEOLOGY")
  local site
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then site=q;break end
  end
  assert(site);p:Found(site:GetX(),site:GetY());extraID=assert(site:GetPlotCity()):GetID()
  for owned in p:Cities()do owned:SetNumRealBuilding(GameInfoTypes.BUILDING_TEMPLE,1)end
  LekmodScenarioEvent("fixture-setup",{operation="provided-Temples-and-second-city",owner=1,city=extraID})
  assert(not c:IsHolyCityAnyReligion()and not c:CanConstruct(building),"ordinary capital bypassed holy-city requirement")
  local religion;for info in GameInfo.Religions()do if info.ID>0 then religion=info.ID;break end end
  assert(Game.GetNumReligionsStillToFound()>0 and not p:HasCreatedReligion())
  local founder,follower=GameInfoTypes.BELIEF_CHURCH_PROPERTY,GameInfoTypes.BELIEF_FEED_WORLD
  local function available(values,id)for _,v in ipairs(values)do if v==id then return true end end return false end
  assert(available(Game.GetAvailableFounderBeliefs(),founder)and available(Game.GetAvailableFollowerBeliefs(),follower))
  Game.FoundReligion(1,religion,nil,founder,follower,-1,-1,c)
  LekmodScenarioEvent("fixture-setup",{operation="provided-religion-founding",owner=1,religion=religion,founder=founder,follower=follower})
  assert(c:IsHolyCityForReligion(religion)and c:CanConstruct(building),"holy-city production unavailable")
  assert(not p:GetCityByID(extraID):CanConstruct(building),"nonholy control can construct St Peters")
  assert(c:GetNumBuilding(cathedral)==0 and c:GetNumBuilding(building)==0)
  before=faith(c);phase="production"
  LekmodScenarioRecord("stpeters-holy-city-gate","PASS","ordinary capital rejected; native founding enables holy city; nonholy control rejected")
  return "turn"
 elseif phase=="production"then
  if not built then return "turn"end
  assert(c:GetNumRealBuilding(building)==1 and not c:CanConstruct(building))
  LekmodScenarioRecord("stpeters-production","PASS","eligible unforced AI owner-turn queue/native CityConstructed; repeat rejected")
  assert(c:GetNumBuilding(cathedral)==1 and c:GetNumRealBuilding(cathedral)==0,"free Cathedral missing or assigned as real")
  assert(p:GetCityByID(extraID):GetNumBuilding(cathedral)==0,"free Cathedral leaked to nonholy control")
  LekmodScenarioRecord("stpeters-free-cathedral","PASS","one free Cathedral only in constructing city")
  local n=0;for _ in pairs(prophets)do n=n+1 end;assert(n==1,"expected exactly one native free Prophet creation")
  LekmodScenarioRecord("stpeters-free-prophet","PASS","one real UnitCreated Prophet event; survival/use not required")
  local extraFaith=0;for row in GameInfo.Building_YieldChanges{BuildingType="BUILDING_CATHEDRAL",YieldType="YIELD_FAITH"}do extraFaith=extraFaith+row.Yield end
  LekmodScenarioEvent("stpeters-faith-comparison",{before=before,after=faith(c),expected=8+extraFaith})
  assert(faith(c)==before+8+extraFaith,"St Peters plus free Cathedral faith differs after policy adjustment")
  LekmodScenarioRecord("stpeters-faith","PASS","building faith +8 plus free Cathedral contribution; observed policy contributions subtracted")
  return true
 end
 return false
end
