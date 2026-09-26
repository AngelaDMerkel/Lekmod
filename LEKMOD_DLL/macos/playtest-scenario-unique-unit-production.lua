-- Own-civilization acquisition through unforced queues and native CityTrained.
-- Tech, resources, population, legal coastal cities, upkeep and cost-minus-one
-- hammers are fixture inputs. No target is supplied with InitUnit. Special
-- non-production definitions remain separately enumerated, never silently passed.
LekmodScenario={name="unique-unit-production",items={"unique-unit-production-scope","unique-unit-owner-production","unique-unit-production-identities"}}
local phase,targets,active,round,started="init",{},{},0,nil
local marker="LekmodMacProducedUnique"
local function eligible(c,id)return c:CanTrain(id,c:GetProductionUnit()==id and 1 or 0)end
local function cityFor(p,info)
 local sea=info.Domain=="DOMAIN_SEA";local size=math.max(1,info.MinAreaSize)
 for c in p:Cities()do if not sea or c:IsCoastal(size)then return c end end
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:IsCoastalLand(size)and p:CanFound(q:GetX(),q:GetY())then
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());assert(c:IsCoastal(size))
   LekmodScenarioEvent("fixture-setup",{operation="provided-legal-coastal-city",owner=p:GetID(),city=c:GetID(),unit=info.Type,x=c:GetX(),y=c:GetY()});return c
  end
 end
 error("no legal coastal site for "..info.Type)
end
-- Trade-unit eligibility requires both a spare slot and an actual possible
-- route. Three connected coastal cities leave alternatives when the AI starts
-- using a route between production rounds; no route outcome is assigned.
local tradeCities={}
local function waterArea(q)
 for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d);if a and a:IsWater()and not a:IsLake()then return a:GetArea()end end
end
local function tradeCity(p,info)
 if not tradeCities[p:GetID()]then
  LekmodScenarioGrantTech(p,"TECH_ENGINEERING");LekmodScenarioGrantTech(p,"TECH_COMPASS")
  local first=cityFor(p,{Type=info.Type,Domain="DOMAIN_SEA",MinAreaSize=6})
  local cities={first};local water=assert(waterArea(first:Plot()))
  for n=1,2 do
   local candidates={}
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
    local distance=Map.PlotDistance(first:GetX(),first:GetY(),q:GetX(),q:GetY())
    if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:GetArea()==first:Plot():GetArea()and q:IsCoastalLand(6)and waterArea(q)==water and distance<=12 and p:CanFound(q:GetX(),q:GetY())then candidates[#candidates+1]={plot=q,distance=distance}end
   end
   table.sort(candidates,function(a,b)if a.distance~=b.distance then return a.distance<b.distance end;return a.plot:GetPlotIndex()<b.plot:GetPlotIndex()end)
   local q=assert(candidates[1],"no legal nearby trade destination").plot
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());cities[#cities+1]=c
   LekmodScenarioEvent("fixture-setup",{operation="provided-legal-trade-destination",owner=p:GetID(),city=c:GetID(),x=c:GetX(),y=c:GetY()})
  end
  for _,c in ipairs(cities)do
   for _,kind in ipairs({"BUILDING_GRANARY","BUILDING_WORKSHOP","BUILDING_CARAVANSARY","BUILDING_HARBOR"})do
    if c:GetNumBuilding(GameInfoTypes[kind])==0 then c:SetNumRealBuilding(GameInfoTypes[kind],1);LekmodScenarioEvent("fixture-setup",{operation="provided-trade-origin-building",owner=p:GetID(),city=c:GetID(),building=kind})end
   end
  end
  local revealed=0
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if Map.PlotDistance(first:GetX(),first:GetY(),q:GetX(),q:GetY())<=p:GetTradeRouteRange(DomainTypes.DOMAIN_SEA,first)and not q:IsRevealed(p:GetTeam())then q:SetRevealed(p:GetTeam(),true);revealed=revealed+1 end
  end
  LekmodScenarioEvent("fixture-setup",{operation="revealed-trade-range",owner=p:GetID(),plots=revealed})
  tradeCities[p:GetID()]=first:GetID()
 end
 if p:GetNumInternationalTradeRoutesAvailable()-p:GetNumInternationalTradeRoutesUsed()<=0 then LekmodScenarioGrantTech(p,"TECH_BANKING")end
 local c=assert(p:GetCityByID(tradeCities[p:GetID()]));local routes={}
 for _,r in ipairs(p:GetTradeRoutesAvailable())do if r.Domain==GameInfoTypes[info.Domain]then routes[#routes+1]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),owner=r.ToID,domain=r.Domain}end end
 LekmodScenarioEvent("trade-production-prerequisites",{owner=p:GetID(),unit=info.Type,available_slots=p:GetNumInternationalTradeRoutesAvailable(),used_slots=p:GetNumInternationalTradeRoutesUsed(),routes=routes})
 assert(#routes>0,"no native route in the target domain")
 return c
end
local function state(u)
 local promotions={};for info in GameInfo.UnitPromotions()do if u:IsHasPromotion(info.ID)then promotions[info.ID]=true end end
 return {type=u:GetUnitType(),owner=u:GetOwner(),domain=u:GetDomainType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage(),experience=u:GetExperience(),base_combat=u:GetBaseCombatStrength(),promotions=promotions,script=u:GetScriptData()}
end
local function prepare(t)
 local p=Players[t.owner];local info=GameInfo.Units[t.kind]
 -- AI callbacks follow its normal economic actions. Supply prerequisites here,
 -- on the actual owner's turn, so unrelated AI purchases cannot spend them first.
 if info.AnyIdeologyUnlock==true or info.AnyIdeologyUnlock==1 or info.AnyIdeologyUnlock=="true"then
  if p:GetLateGamePolicyTree()==-1 then
   assert(not p:GetCapitalCity():CanTrain(t.unit),"ideology gate unexpectedly open")
   p:SetPolicyBranchUnlocked(GameInfoTypes.POLICY_BRANCH_FREEDOM,true,false)
   assert(p:GetLateGamePolicyTree()==GameInfoTypes.POLICY_BRANCH_FREEDOM)
   LekmodScenarioEvent("fixture-setup",{operation="provided-required-ideology",owner=t.owner,unit=t.kind,ideology="POLICY_BRANCH_FREEDOM"})
  end
 end
 if info.PrereqTech then LekmodScenarioGrantTech(p,info.PrereqTech)end
 for row in GameInfo.Unit_ResourceQuantityRequirements{UnitType=info.Type}do
  local id=GameInfoTypes[row.ResourceType];local amount=math.max(0,row.Cost-p:GetNumResourceAvailable(id,true))
  if amount>0 then p:ChangeNumResourceTotal(id,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-unit-strategic-resource",owner=t.owner,unit=t.kind,resource=row.ResourceType,amount=amount})end
 end
 local c=info.Trade and tradeCity(p,info)or cityFor(p,info);t.city=c:GetID()
 local population=math.max(info.PopulationReq or 0,(info.Found or info.FoundAbroad)and GameDefines.CITY_MIN_SIZE_FOR_SETTLERS or 0)
 if c:GetPopulation()<population then c:SetPopulation(population,true);LekmodScenarioEvent("fixture-setup",{operation="provided-settler-population",owner=t.owner,city=t.city,population=population})end
 -- Fail visibly on any further unreviewed prerequisite or fixture state.
 assert(eligible(c,t.unit),"ineligible "..t.kind..": "..tostring(c:CanTrainTooltip(t.unit)))
 LekmodScenarioEvent("unit-production-eligible",{owner=t.owner,civilization=GameInfo.Civilizations[p:GetCivilizationType()].Type,city=t.city,unit=t.kind,inherited=c:GetProductionUnit()==t.unit})
end
local function nearComplete(t,c)
 local cost=c:GetUnitProductionNeeded(t.unit);assert(cost>1,"review native production cost: "..t.kind)
 c:SetUnitProduction(t.unit,cost-1);t.queued=true
 LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-unit",owner=t.owner,city=t.city,unit=t.kind,cost=cost,hammers=cost-1})
end
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
 local t=active[owner];if not t or t.done or t.city~=city then return end
 local p=Players[owner];local u=p:GetUnitByID(id);if not u or u:GetUnitType()~=t.unit then return end
 assert(t.queued and not gold and not faith,"target did not come from ordinary production")
 assert(not t.trained,"duplicate target completion")
 local expectedStrength=GameInfo.Units[t.kind].Combat
 -- Colorado's real UnitCreated handler adds 2 per rounded five happiness.
 -- Its base strength intentionally differs from the static database Combat.
 if t.kind=="UNIT_COLORADO"then expectedStrength=expectedStrength+2*math.max(0,math.floor(p:GetExcessHappiness()/5+0.5))end
 assert(u:GetOwner()==owner and u:GetBaseCombatStrength()==expectedStrength,"produced identity/strength differs for "..t.kind.." actual="..u:GetBaseCombatStrength().." expected="..expectedStrength)
 local expected=GameInfoTypes[GameInfo.Units[t.kind].Domain]
 if GameInfo.Units[t.kind].Domain=="DOMAIN_HOVER"then expected=u:GetPlot():IsWater()and DomainTypes.DOMAIN_SEA or DomainTypes.DOMAIN_LAND end
 assert(u:GetDomainType()==expected and not u:IsDead()and not u:IsDelayedDeath(),"produced unit domain/liveness differs")
 u:SetScriptData(marker);t.trained=id
 LekmodScenarioEvent("native-unique-unit-produced",{owner=owner,city=city,unit=t.kind,id=id,gold=gold,faith=faith,turn=Game.GetGameTurn(),expected_base_combat=expectedStrength,birth=state(u)})
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if phase~="producing"or owner==Game.GetActivePlayer()then return end
 local t=active[owner];if not t or t.queued then return end
 local p=Players[owner];assert(not p:IsHuman()and p:IsTurnActive());prepare(t);local c=assert(p:GetCityByID(t.city))
 if c:GetProductionUnit()~=t.unit then c:PushOrder(OrderTypes.ORDER_TRAIN,t.unit,-1,0,true,false,0)end
 assert(c:GetProductionUnit()==t.unit,"AI order changed");nearComplete(t,c)
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
  if p and p:IsAlive()then
   local cities,units,techs,routes={},{},{},{}
   for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),production_unit=c:GetProductionUnit(),production=c:GetProduction()}end
   for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
   for info in GameInfo.Technologies()do if Teams[p:GetTeam()]:GetTeamTechs():HasTech(info.ID)then techs[info.ID]=true end end
   for index,row in ipairs(p:GetTradeRoutes())do
    local r={};for key,value in pairs(row)do r[key]=(key=="FromCity"or key=="ToCity")and value:GetID()or value end;routes[index]=r
   end
   owners[owner]={trade_routes=routes,trade_slots=p:GetNumInternationalTradeRoutesAvailable(),used_trade_slots=p:GetNumInternationalTradeRoutesUsed(),civilization=p:GetCivilizationType(),gold=p:GetGold(),faith=p:GetFaith(),cities=cities,units=units,techs=techs}
  end
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  local deferred={}
  for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
   if p and p:IsAlive()then
    p:ChangeGold(10000);LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-budget",owner=owner,added=10000})
    for row in GameInfo.Civilization_UnitClassOverrides{CivilizationType=GameInfo.Civilizations[p:GetCivilizationType()].Type}do
     if row.UnitType and row.UnitType~=GameInfo.UnitClasses[row.UnitClassType].DefaultUnit then
      local info=assert(GameInfo.Units[row.UnitType]);assert(info.Class==row.UnitClassType)
      if info.Cost<0 or info.PurchaseOnly then deferred[#deferred+1]={owner=owner,unit=info.Type,reason=info.PurchaseOnly and"purchase-only"or"non-production"}
      else targets[#targets+1]={owner=owner,unit=info.ID,kind=info.Type,tech_cost=info.PrereqTech and GameInfo.Technologies[info.PrereqTech].Cost or 0,done=false,queued=false}end
     end
    end
   end
  end
  table.sort(targets,function(a,b)if a.owner~=b.owner then return a.owner<b.owner end;if a.tech_cost~=b.tech_cost then return a.tech_cost<b.tech_cost end;return a.kind<b.kind end)
  assert(#targets>0);LekmodScenarioEvent("unique-unit-production-scope",{targets=targets,deferred=deferred})
  LekmodScenarioRecord("unique-unit-production-scope","PASS","production targets="..#targets.." separately deferred="..#deferred)
  phase="next-round"
 elseif phase=="next-round"then
  active={};local count=0
  for _,t in ipairs(targets)do if not t.done and not active[t.owner]then active[t.owner]=t;count=count+1 end end
  if count==0 then
   LekmodScenarioRecord("unique-unit-owner-production","PASS","all "..#targets.." targets completed through real unforced owner queues and non-purchase CityTrained")
   LekmodScenarioRecord("unique-unit-production-identities","PASS","all targets had correct owner/type/domain/base strength at native birth; later AI activity is separate")
   return true
  end
  round=round+1;started=Game.GetGameTurn();local t=active[player:GetID()]
  if t then
   prepare(t);local c=assert(player:GetCityByID(t.city));if c:GetProductionUnit()~=t.unit then Game.CityPushOrder(c,OrderTypes.ORDER_TRAIN,t.unit,false,true,true)end;phase="human-queued"
  else phase="producing";return "turn"end
 elseif phase=="human-queued"then
  local t=active[player:GetID()];local c=assert(player:GetCityByID(t.city))
  if not LekmodScenarioAwait("unique-unit-human-order-"..round,c:GetProductionUnit()==t.unit)then return false end
  nearComplete(t,c);phase="producing";return "turn"
 elseif phase=="producing"then
  local complete=true
  for _,t in pairs(active)do
   if t.trained then
    if not t.done then t.done=true;LekmodScenarioRecord("produced-"..t.kind,"PASS","native non-purchase CityTrained owner="..t.owner.." city="..t.city.." id="..t.trained)end
   else complete=false end
  end
  if complete then phase="next-round";return false end
  assert(Game.GetGameTurn()-started<3,"production round exceeded ordinary turn bound");return "turn"
 end
 return false
end
