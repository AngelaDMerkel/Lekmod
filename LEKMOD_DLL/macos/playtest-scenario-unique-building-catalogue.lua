-- Civilization-specific production catalogue. Research, valid city sites,
-- prerequisite buildings/resources and near-complete hammers are labeled inputs.
-- Targets must come from eligible, unforced queues and real CityConstructed events.
-- Purchase-only, holy-city and occupied-city definitions are outside this phase.
LekmodScenario={name="unique-building-catalogue",items={"unique-building-catalogue-scope","unique-building-catalogue-production","unique-building-catalogue-repeat-rejection"}}
local phase,targets,active,constructed,round,started="init",{}, {},{},0,nil
local ys={YieldTypes.YIELD_FOOD,YieldTypes.YIELD_PRODUCTION,YieldTypes.YIELD_GOLD,YieldTypes.YIELD_SCIENCE,YieldTypes.YIELD_CULTURE,YieldTypes.YIELD_FAITH}
local function replacement(p,class)
 for row in GameInfo.Civilization_BuildingClassOverrides{CivilizationType=GameInfo.Civilizations[p:GetCivilizationType()].Type,BuildingClassType=class}do return row.BuildingType and GameInfoTypes[row.BuildingType]end
 return GameInfoTypes[GameInfo.BuildingClasses[class].DefaultBuilding]
end
local function siteOK(c,info)
 return(not info.Water or c:IsCoastal(10))and(not info.FreshWater or c:Plot():IsFreshWater())
end
local function chooseCity(p,info)
 for c in p:Cities()do if c:GetNumBuilding(info.ID)==0 and siteOK(c,info)then return c end end
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and(not info.Water or q:IsCoastalLand(10))and(not info.FreshWater or q:IsFreshWater())and p:CanFound(q:GetX(),q:GetY())then
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());assert(siteOK(c,info))
   LekmodScenarioEvent("fixture-setup",{operation="provided-eligible-building-city",owner=p:GetID(),city=c:GetID(),building=info.Type,x=c:GetX(),y=c:GetY()});return c
  end
 end
 error("no legal city site for "..info.Type)
end
local function prerequisite(p,c,class,target)
 local id=assert(replacement(p,class),"prerequisite class has no owner building");assert(id~=target,"self-referential building prerequisite")
 if c:GetNumBuilding(id)==0 then
  c:SetNumRealBuilding(id,1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-prerequisite-building",owner=p:GetID(),city=c:GetID(),building=id})
 end
end
local function resource(p,kind,building)
 local info=assert(GameInfo.Resources[kind])
 for _,field in ipairs({"TechReveal","TechCityTrade"})do if info[field]then LekmodScenarioGrantTech(p,info[field])end end
 -- setResourceType alone does not establish an existing city's resource link.
 -- Supply the resource before ordinary founding and let that engine path link it.
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:GetResourceType(-1)==-1 and(not building.Water or q:IsCoastalLand(10))and(not building.FreshWater or q:IsFreshWater())and q:CanHaveResource(info.ID,false)and p:CanFound(q:GetX(),q:GetY())then
   q:SetResourceType(info.ID,1)
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity())
   LekmodScenarioEvent("fixture-setup",{operation="provided-resource-before-legal-city-founding",owner=p:GetID(),city=c:GetID(),resource=kind,x=q:GetX(),y=q:GetY(),locally_connected=c:IsHasResourceLocal(info.ID,false)})
   assert(c:IsHasResourceLocal(info.ID,false),"normal city founding did not connect supplied resource")
   return c
  end
 end
 error("no legal resource/city input for "..kind)
end
local function eligible(c,building)
 -- CanConstruct's continuation argument is an integer in the native Lua binding.
 return c:CanConstruct(building,c:GetProductionBuilding()==building and 1 or 0)
end
local function inheritedOrder(c,t)
 local inherited=c:GetProductionBuilding()==t.building
 if inherited then
  assert(c:CanConstruct(t.building,1),"inherited production is no longer eligible")
  LekmodScenarioEvent("catalogue-inherited-production",{owner=t.owner,city=t.city,building=t.kind})
 end
 return inherited
end
local function prepare(p,info)
 if info.PrereqTech then LekmodScenarioGrantTech(p,info.PrereqTech)end
 for row in GameInfo.Building_ResourceQuantityRequirements{BuildingType=info.Type}do
  local resource=GameInfoTypes[row.ResourceType];local amount=math.max(0,row.Cost-p:GetNumResourceAvailable(resource,true))
  if amount>0 then p:ChangeNumResourceTotal(resource,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-building-strategic-resource",owner=p:GetID(),building=info.Type,resource=row.ResourceType,amount=amount})end
 end
 local c=chooseCity(p,info)
 for row in GameInfo.Building_ClassesNeededInCity{BuildingType=info.Type}do prerequisite(p,c,row.BuildingClassType,info.ID)end
 for row in GameInfo.Building_PrereqBuildingClasses{BuildingType=info.Type}do
  for owned in p:Cities()do prerequisite(p,owned,row.BuildingClassType,info.ID)end
 end
 if not eligible(c,info.ID)then
  for row in GameInfo.Building_LocalResourceAnds{BuildingType=info.Type}do error("review new local-AND resource requirement: "..row.ResourceType)end
  for row in GameInfo.Building_LocalResourceOrs{BuildingType=info.Type}do c=resource(p,row.ResourceType,info);break end
  for row in GameInfo.Building_ClassesNeededInCity{BuildingType=info.Type}do prerequisite(p,c,row.BuildingClassType,info.ID)end
  for row in GameInfo.Building_PrereqBuildingClasses{BuildingType=info.Type}do for owned in p:Cities()do prerequisite(p,owned,row.BuildingClassType,info.ID)end end
 end
 assert(eligible(c,info.ID),"ineligible "..info.Type..": "..tostring(c:CanConstructTooltip(info.ID)))
 assert(c:GetNumRealBuilding(info.ID)==0,"target already present")
 return {owner=p:GetID(),city=c:GetID(),building=info.ID,kind=info.Type,queued=false,done=false}
end
GameEvents.CityConstructed.Add(function(owner,city,building,gold,faith)
 local key=owner..":"..city..":"..building
 for _,t in ipairs(targets)do if t.owner==owner and t.city==city and t.building==building then
  assert(not gold and not faith,"catalogue target purchased");constructed[key]=true
  LekmodScenarioEvent("native-catalogue-building",{owner=owner,city=city,building=building,turn=Game.GetGameTurn()})
 end end
end)
local function nearComplete(t,c)
 local cost=c:GetBuildingProductionNeeded(t.building);assert(cost>1,"target requires separate zero-cost coverage")
 c:SetBuildingProduction(t.building,cost-1);t.queued=true
 LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-building",owner=t.owner,city=t.city,building=t.kind,cost=cost,hammers=cost-1})
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if phase~="building"or owner==Game.GetActivePlayer()then return end
 local t=active[owner]
 if t and not t.queued then
  local p=Players[owner];assert(not p:IsHuman()and p:IsTurnActive());local c=assert(p:GetCityByID(t.city));assert(eligible(c,t.building))
  if not inheritedOrder(c,t)then c:PushOrder(OrderTypes.ORDER_CONSTRUCT,t.building,-1,0,true,false,0)end
  assert(c:GetProductionBuilding()==t.building,"AI order changed")
  nearComplete(t,c)
 end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
  if p and p:IsAlive()then
   local cities,policies={},{}
   for c in p:Cities()do
    local buildings,total,base,pop,mod,rates={},{},{},{},{},{}
    for info in GameInfo.Buildings()do
     local n=c:GetNumRealBuilding(info.ID);if n>0 then buildings[info.ID]=n end
     local all=c:GetNumBuilding(info.ID);if all>0 then total[info.ID]=all end
    end
    for _,y in ipairs(ys)do base[y]=c:GetBaseYieldRateFromBuildings(y);pop[y]=c:GetYieldPerPopTimes100(y);mod[y]=c:GetBaseYieldRateModifier(y);rates[y]=c:GetYieldRateTimes100(y)end
    cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),buildings=buildings,total_buildings=total,base=base,perpop100=pop,modifier=mod,rates100=rates}
   end
   for info in GameInfo.Policies()do if p:HasPolicy(info.ID)then policies[info.Type]=true end end
   owners[owner]={civilization=p:GetCivilizationType(),cities=cities,policies=policies,gold=p:GetGold(),faith=p:GetFaith()}
  end
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  local deferred={}
  for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
   if p and p:IsAlive()then
    for row in GameInfo.Civilization_BuildingClassOverrides{CivilizationType=GameInfo.Civilizations[p:GetCivilizationType()].Type}do
     if row.BuildingType and row.BuildingType~=GameInfo.BuildingClasses[row.BuildingClassType].DefaultBuilding then
      local info=assert(GameInfo.Buildings[row.BuildingType])
      if info.Cost<0 or info.HolyCity or info.NoOccupiedUnhappiness then deferred[#deferred+1]={owner=owner,building=info.Type,reason=info.Cost<0 and"purchase-only"or(info.HolyCity and"holy-city"or"occupied-city")}
      else targets[#targets+1]=prepare(p,info)end
     end
    end
   end
  end
  assert(#targets>0,"no eligible production targets in this group")
  LekmodScenarioEvent("building-catalogue-scope",{targets=targets,deferred=deferred})
  LekmodScenarioRecord("unique-building-catalogue-scope","PASS","eligible production targets="..#targets.." explicitly deferred purchase/holy-city/occupied-city definitions="..#deferred)
  phase="next-round"
 elseif phase=="next-round"then
  active={};local count=0
  for _,t in ipairs(targets)do if not t.done and not active[t.owner]then active[t.owner]=t;count=count+1 end end
  if count==0 then
   LekmodScenarioRecord("unique-building-catalogue-production","PASS","all "..#targets.." declared targets completed via real CityConstructed and normal owner turns")
   LekmodScenarioRecord("unique-building-catalogue-repeat-rejection","PASS","every completed target rejects duplicate construction")
   return true
  end
  round=round+1;started=Game.GetGameTurn()
  local t=active[player:GetID()]
  if t then local c=assert(player:GetCityByID(t.city));assert(eligible(c,t.building));if not inheritedOrder(c,t)then Game.CityPushOrder(c,OrderTypes.ORDER_CONSTRUCT,t.building,false,true,true)end;phase="human-queued"
  else phase="building";return "turn"end
 elseif phase=="human-queued"then
  local t=active[player:GetID()];local c=assert(player:GetCityByID(t.city))
  if not LekmodScenarioAwait("catalogue-human-order-"..round,c:GetProductionBuilding()==t.building)then return false end
  nearComplete(t,c);phase="building";return "turn"
 elseif phase=="building"then
  local complete=true
  for _,t in pairs(active)do
   local c=assert(Players[t.owner]:GetCityByID(t.city));local key=t.owner..":"..t.city..":"..t.building
   if constructed[key]and c:GetNumRealBuilding(t.building)==1 then
    if not t.done then
     assert(not c:CanConstruct(t.building),"completed building remains eligible")
     t.done=true;LekmodScenarioRecord("constructed-"..t.kind,"PASS","native CityConstructed/count=1/duplicate rejected owner="..t.owner)
    end
   else complete=false end
  end
  if complete then phase="next-round";return false end
  assert(Game.GetGameTurn()-started<3,"production round exceeded ordinary turn bound")
  return "turn"
 end
 return false
end
