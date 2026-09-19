-- Supply legal cities, range/buildings and caravans; use normal unit trade
-- mission messages on the active human turn. Outcomes are read only.
LekmodScenario={name="kilwa-routes",items={"kilwa-first-route","kilwa-second-route","kilwa-internal-exclusion","kilwa-internal-gold","kilwa-owner-city-controls","kilwa-food-settlement"}}
local phase,capitalID,homeID,unitID,baseModifier,baseFood,started,foodLedger="init"
local foreign={};local requestIndex=1
local marker=GameInfoTypes.BUILDING_KILWA_TRAIT
local function cityState(c)
 return {name=c:GetName(),marker=c:GetNumRealBuilding(marker),food=c:GetFoodTimes100(),population=c:GetPopulation(),food_rate=c:GetYieldRateTimes100(YieldTypes.YIELD_FOOD),food_base=c:GetBaseYieldRate(YieldTypes.YIELD_FOOD),food_modifier=c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD),food_difference=c:FoodDifferenceTimes100(),gold_rate=c:GetYieldRateTimes100(YieldTypes.YIELD_GOLD)}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,1 do
  local p=Players[id];local cities,routes={},{}
  for c in p:Cities()do cities[c:GetID()]=cityState(c)end
  for i,r in ipairs(p:GetTradeRoutes())do routes[i]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),to_owner=r.ToID,kind=r.ConnectionType,domain=r.Domain,gold=r.FromGPT,to_food=r.ToFood,left=r.TurnsLeft}end
  owners[id]={cities=cities,routes=routes,gold=p:GetGold(),used=p:GetNumInternationalTradeRoutesUsed()}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function provideCity(owner,near,label)
 local p=Players[owner];local site
 for i=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(i)
  local distance=Map.PlotDistance(near:GetX(),near:GetY(),plot:GetX(),plot:GetY())
  if distance>=4 and distance<=8 and plot:GetArea()==near:Plot():GetArea()and plot:GetOwner()==-1 and plot:GetNumUnits()==0 and p:CanFound(plot:GetX(),plot:GetY())then site=plot;break end
 end
 assert(site,"no legal supplied city site for "..label);p:Found(site:GetX(),site:GetY());local city=assert(site:GetPlotCity())
 LekmodScenarioEvent("fixture-setup",{operation="provided-legal-city",label=label,owner=owner,id=city:GetID(),x=city:GetX(),y=city:GetY()})
 return city
end
local function beginRoute(player,origin,target,internal)
 local u=assert(player:InitUnit(player:GetTradeUnitType(DomainTypes.DOMAIN_LAND),origin:GetX(),origin:GetY()));unitID=u:GetID()
 LekmodScenarioEvent("fixture-setup",{operation="provided-caravan",id=unitID,origin=origin:GetID()})
 local option
 for _,r in ipairs(player:GetPotentialInternationalTradeRouteDestinations(u))do
  if r.X==target:GetX()and r.Y==target:GetY()and(not internal or r.Yields[YieldTypes.YIELD_FOOD+1].Theirs>0)then option=r;break end
 end
 assert(option,"requested external/internal food route is not available")
 assert(u:CanMakeTradeRouteAt(u:GetPlot(),target:GetX(),target:GetY(),option.TradeConnectionType),"route query and eligibility differ")
 LekmodScenarioEvent("kilwa-route-request",{index=requestIndex,origin=origin:GetID(),target=target:GetID(),target_owner=target:GetOwner(),kind=option.TradeConnectionType})
 assert(player:IsTurnActive() and not Game.IsProcessingMessages(),"unit trade mission requires normal active-turn readiness")
 UI.SelectUnit(u)
 assert(UI.GetHeadSelectedUnit() and UI.GetHeadSelectedUnit():GetID()==unitID,"trade mission selected the wrong unit")
 Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_ESTABLISH_TRADE_ROUTE,target:Plot():GetPlotIndex(),option.TradeConnectionType,0,false,nil)
end
function LekmodScenarioBeforeEndTurn(player,turn)
 if phase=="settlement"then
  local c=player:GetCityByID(capitalID);foodLedger={turn=turn,food=c:GetFoodTimes100(),difference=c:FoodDifferenceTimes100(),population=c:GetPopulation(),threshold=c:GrowthThreshold()*100}
  assert(foodLedger.difference>0 and foodLedger.food+foodLedger.difference<foodLedger.threshold,"fixture would starve or grow; use a simple food-store boundary")
  LekmodScenarioEvent("kilwa-food-before",foodLedger)
 end
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_KILWA,"human Kilwa required")
 local other=Players[1];assert(other:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"Roman control slot1 required")
 local capital=player:GetCapitalCity()
 if phase=="init" and not capital then
  for u in player:Units()do
   if GameInfo.Units[u:GetUnitType()].Found and u:CanFound(u:GetPlot())then
    UI.SelectUnit(u)
    for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_FOUND"then
     assert(Game.CanHandleAction(i),"normal initial Found action unavailable")
     LekmodScenarioEvent("normal-initial-found",{unit=u:GetID(),x=u:GetX(),y=u:GetY()})
     Game.HandleAction(i);phase="founding";return false
    end end
   end
  end
  error("no legal starting Settler for the capital")
 end
 if phase=="founding"then
  if not LekmodScenarioAwait("kilwa-capital-founded",capital~=nil)then return false end
  phase="init"
 end
 assert(capital,"Kilwa capital missing after normal founding")
 if phase=="init"then
  assert(#player:GetTradeRoutes()==0,"fresh route fixture required");capitalID=capital:GetID()
  assert(not Teams[player:GetTeam()]:IsAtWar(other:GetTeam()),"fixture must begin at peace")
  if not Teams[player:GetTeam()]:IsHasMet(other:GetTeam())then Teams[player:GetTeam()]:Meet(other:GetTeam(),false);LekmodScenarioEvent("fixture-setup",{operation="provided-contact",other=1})end
  homeID=provideCity(0,capital,"internal-destination"):GetID()
  foreign[1]=provideCity(1,capital,"external-destination-one"):GetID();foreign[2]=provideCity(1,capital,"external-destination-two"):GetID()
  for _,name in ipairs({"BUILDING_GRANARY","BUILDING_CARAVANSARY"})do
   if capital:GetNumBuilding(GameInfoTypes[name])==0 then capital:SetNumRealBuilding(GameInfoTypes[name],1);LekmodScenarioEvent("fixture-setup",{operation="provided-origin-building",city=capitalID,type=name})end
  end
  for c in player:Cities()do Game.CityPushOrder(c,OrderTypes.ORDER_MAINTAIN,GameInfoTypes.PROCESS_WEALTH,false,true,true)end
  local range=player:GetTradeRouteRange(DomainTypes.DOMAIN_LAND,capital);local revealed=0
  for i=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(i)
   if Map.PlotDistance(capital:GetX(),capital:GetY(),plot:GetX(),plot:GetY())<=range and not plot:IsRevealed(player:GetTeam())then plot:SetRevealed(player:GetTeam(),true);revealed=revealed+1 end
  end
  LekmodScenarioEvent("fixture-setup",{operation="revealed-origin-trade-range",plots=revealed,range=range})
  assert(player:GetNumInternationalTradeRoutesAvailable()-player:GetNumInternationalTradeRoutesUsed()>=3,"three free trade slots required")
  phase="ready";return false
 elseif phase=="ready"then
  assert(capital:GetNumRealBuilding(marker)==0,"initial Kilwa marker must be zero")
  baseModifier=capital:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD);baseFood=capital:GetBaseYieldRate(YieldTypes.YIELD_FOOD)
  LekmodScenarioEvent("kilwa-before-routes",cityState(capital));phase="request"
 elseif phase=="request"then
  local target=requestIndex<=2 and other:GetCityByID(foreign[requestIndex])or player:GetCityByID(homeID)
  beginRoute(player,capital,target,requestIndex==3);phase="created"
 elseif phase=="created"then
  local routes=player:GetTradeRoutes()
  if not LekmodScenarioAwait("kilwa-route-created",#routes==requestIndex)then return false end
  local expected=math.min(requestIndex,2)
  LekmodScenarioEvent("kilwa-created-route-state",{index=requestIndex,expected_marker=expected,state=cityState(capital)})
  -- Delayed unit death emits the ordinary prekill callback; give normal engine
  -- updates time to finish, without calling the product callback ourselves.
  if not LekmodScenarioAwait("kilwa-route-marker",capital:GetNumRealBuilding(marker)==expected)then return false end
  assert(capital:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD)==baseModifier+5*expected,"food modifier does not match 5 percent per external route")
  assert(capital:GetBaseYieldRate(YieldTypes.YIELD_FOOD)==baseFood,"route setup changed base food unexpectedly")
  assert(capital:GetYieldRateTimes100(YieldTypes.YIELD_FOOD)==baseFood*(baseModifier+5*expected),"actual gross food does not match the route modifier")
  LekmodScenarioEvent("kilwa-after-route",{index=requestIndex,state=cityState(capital)})
  if requestIndex<3 then
   LekmodScenarioRecord(requestIndex==1 and"kilwa-first-route"or"kilwa-second-route","PASS","normal-synchronized-mission route; marker="..expected.." food-modifier="..(baseModifier+5*expected))
   requestIndex=requestIndex+1;phase="request"
  else
   local internal
   for _,r in ipairs(routes)do if r.ToID==0 and r.ToCity:GetID()==homeID then internal=r;break end end
   assert(internal and internal.ToFood>0 and internal.FromGPT==400,"internal route lacks Kilwa's four gold or its food cargo")
   LekmodScenarioRecord("kilwa-internal-exclusion","PASS","third route is internal; external marker remains2")
   LekmodScenarioRecord("kilwa-internal-gold","PASS","internal food route origin gold400hundredths; no gold outcome assigned")
   for c in player:Cities()do if c:GetID()~=capitalID then assert(c:GetNumRealBuilding(marker)==0,"Kilwa city without outgoing foreign routes gained a marker")end end
   for c in other:Cities()do assert(c:GetNumRealBuilding(marker)==0,"Roman recipient gained Kilwa marker")end
   LekmodScenarioRecord("kilwa-owner-city-controls","PASS","secondary Kilwa city and all Roman cities retain zero markers")
   started=Game.GetGameTurn();phase="settlement";return "turn"
  end
 elseif phase=="settlement"then
  if not foodLedger or Game.GetGameTurn()==foodLedger.turn then return "turn"end
  assert(Game.GetGameTurn()==foodLedger.turn+1 and capital:GetPopulation()==foodLedger.population,"food settlement skipped a turn or grew")
  local actual=capital:GetFoodTimes100()-foodLedger.food
  LekmodScenarioEvent("kilwa-food-after",{actual=actual,expected=foodLedger.difference,state=cityState(capital)})
  assert(actual==foodLedger.difference,"ordinary food storage change differs from boosted native food difference")
  assert(capital:GetNumRealBuilding(marker)==2,"repeated owner-turn callback stacked or lost route markers")
  LekmodScenarioRecord("kilwa-food-settlement","PASS","one ordinary turn; actualfooddelta100="..actual.." markerremains2")
  return true
 end
 return false
end
