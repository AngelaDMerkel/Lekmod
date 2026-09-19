-- Provided research, caravan, visibility and near-complete production are inputs.
-- Normal construction and a synchronized international land route are outcomes.
LekmodScenario={name="nabatea-tomb",items={"tomb-prerequisites-controls","tomb-normal-construction","tomb-yields-horses","tomb-six-route-quotes","tomb-land-route-bonuses"}}
local phase="init"
local tomb=GameInfoTypes.BUILDING_MC_KOKH
local caravanserai=GameInfoTypes.BUILDING_CARAVANSARY
local horse=GameInfoTypes.RESOURCE_HORSE
local originID,targetID,unitID,before,quote,turn
local built=false
GameEvents.CityConstructed.Add(function(owner,city,building,gold,faith)
 if owner==Game.GetActivePlayer()and city==originID and building==tomb then
  assert(not gold and not faith,"Tomb must complete through production")
  built=true;LekmodScenarioEvent("native-Tomb-constructed",{owner=owner,city=city,building=building,turn=Game.GetGameTurn()})
 end
end)
local function cityState(c)
 return {tomb=c:GetNumRealBuilding(tomb),base=c:GetNumRealBuilding(caravanserai),building_food=c:GetBaseYieldRateFromBuildings(YieldTypes.YIELD_FOOD),building_gold=c:GetBaseYieldRateFromBuildings(YieldTypes.YIELD_GOLD),gross_food=c:GetYieldRateTimes100(YieldTypes.YIELD_FOOD),population=c:GetPopulation(),food=c:GetFoodTimes100()}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,1 do local p=Players[id];local cities,routes={},{}
  for c in p:Cities()do cities[c:GetID()]=cityState(c)end
  for i,r in ipairs(p:GetTradeRoutes())do routes[i]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),to_owner=r.ToID,food=p:GetTradeConnectionTotalValue(r.FromCity,r.ToCity,r.ConnectionType,true,YieldTypes.YIELD_FOOD,r.Domain,true),gold=r.FromGPT,kind=r.ConnectionType,domain=r.Domain,left=r.TurnsLeft}end
  owners[id]={cities=cities,routes=routes,horses=p:GetNumResourceTotal(horse,true)}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function routeQuote(player)
 local u=assert(player:GetUnitByID(unitID));local target=assert(Players[1]:GetCityByID(targetID))
 for _,r in ipairs(player:GetPotentialInternationalTradeRouteDestinations(u))do
  if r.X==target:GetX()and r.Y==target:GetY()and r.TradeConnectionType==(GameInfoTypes.TRADE_CONNECTION_INTERNATIONAL or 0) then
   local origin=assert(player:GetCityByID(originID))
   return {food=r.Yields[YieldTypes.YIELD_FOOD+1].Mine,gold=r.Yields[YieldTypes.YIELD_GOLD+1].Mine,kind=r.TradeConnectionType,building_food=player:GetTradeConnectionYourBuildingValue(origin,target,r.TradeConnectionType,true,YieldTypes.YIELD_FOOD,DomainTypes.DOMAIN_LAND),building_gold=player:GetTradeConnectionYourBuildingValue(origin,target,r.TradeConnectionType,true,YieldTypes.YIELD_GOLD,DomainTypes.DOMAIN_LAND)}
  end
 end
 error("controlled foreign land route not available")
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_NABATEA and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 local city=originID and player:GetCityByID(originID)
 if phase=="init"then
  assert(#player:GetTradeRoutes()==0,"requires no active human route")
  for c in player:Cities()do if not c:IsCapital()then city=c;originID=c:GetID();break end end
  assert(city,"requires additional city from preserved farm fixture")
  local techs=Teams[player:GetTeam()]:GetTeamTechs()
  assert(not techs:HasTech(GameInfoTypes.TECH_HORSEBACK_RIDING)and city:GetNumRealBuilding(tomb)==0)
  assert(not city:CanConstruct(tomb),"Tomb constructible before Horseback Riding")
  LekmodScenarioGrantTech(player,"TECH_HORSEBACK_RIDING");LekmodScenarioGrantTech(Players[1],"TECH_HORSEBACK_RIDING")
  if not Teams[player:GetTeam()]:IsHasMet(Players[1]:GetTeam())then Teams[player:GetTeam()]:Meet(Players[1]:GetTeam(),false)end
  local target=assert(Players[1]:GetCapitalCity());targetID=target:GetID()
  for i=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(i)
   if Map.PlotDistance(city:GetX(),city:GetY(),plot:GetX(),plot:GetY())<=15 then plot:SetRevealed(player:GetTeam(),true)end
  end
  local u=assert(player:InitUnit(player:GetTradeUnitType(DomainTypes.DOMAIN_LAND),city:GetX(),city:GetY()));unitID=u:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-caravan-contact-range-visibility",unit=unitID,city=originID,target=targetID,radius=15})
  Network.SendSetCityAvoidGrowth(city:GetID(),true)
  phase="order";return false
 elseif phase=="order"then
  if not LekmodScenarioAwait("Tomb-avoid-growth",city:IsForcedAvoidGrowth())then return false end
  local roman=assert(Players[1]:GetCityByID(targetID))
  assert(city:CanConstruct(tomb)and not city:CanConstruct(caravanserai),"Nabataean replacement restrictions differ")
  assert(not roman:CanConstruct(tomb)and roman:CanConstruct(caravanserai),"Roman replacement control differs")
  LekmodScenarioRecord("tomb-prerequisites-controls","PASS","Horseback Riding gate, Nabataean replacement, Roman standard-building control")
  before={city=cityState(city),horses=player:GetNumResourceTotal(horse,true),roman_horses=Players[1]:GetNumResourceTotal(horse,true)}
  quote=routeQuote(player);LekmodScenarioEvent("tomb-before-construction",{state=before,route=quote})
  Game.CityPushOrder(city,OrderTypes.ORDER_CONSTRUCT,tomb,false,true,true);phase="queued";return false
 elseif phase=="queued"then
  if not LekmodScenarioAwait("Tomb-order",city:GetProductionBuilding()==tomb)then return false end
  local cost=city:GetBuildingProductionNeeded(tomb);city:SetBuildingProduction(tomb,cost-1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-Tomb",production=cost-1,cost=cost})
  turn=Game.GetGameTurn();phase="built";return "turn"
 elseif phase=="built"then
  if Game.GetGameTurn()==turn then return "turn"end
  assert(Game.GetGameTurn()==turn+1 and built and city:GetNumRealBuilding(tomb)==1,"normal production did not construct Tomb")
  LekmodScenarioRecord("tomb-normal-construction","PASS","ordinary turn and real CityConstructed; final hammer earned")
  local s=cityState(city)
  LekmodScenarioEvent("tomb-after-construction",{city=s,horses=player:GetNumResourceTotal(horse,true),roman_horses=Players[1]:GetNumResourceTotal(horse,true)})
  assert(s.building_food==before.city.building_food+2 and s.building_gold==before.city.building_gold+3,"Tomb flat yields differ from data")
  assert(player:GetNumResourceTotal(horse,true)==before.horses+2 and Players[1]:GetNumResourceTotal(horse,true)==before.roman_horses,"Tomb horse reward/owner control differs")
  LekmodScenarioRecord("tomb-yields-horses","PASS","building food+2 gold+3 horses+2; Roman horses unchanged")
  local after=routeQuote(player)
  LekmodScenarioEvent("tomb-land-route-quotes",{before=quote,after=after})
  assert(s.population==before.city.population,"controlled Tomb city grew")
  assert(after.food==quote.food+100 and after.building_food==quote.building_food+100 and after.building_gold==quote.building_gold+200,"international land route building contribution differs")
  local target=assert(Players[1]:GetCityByID(targetID));local rows={}
  for kind=0,2 do for _,domain in ipairs({DomainTypes.DOMAIN_LAND,DomainTypes.DOMAIN_SEA})do
   local food=player:GetTradeConnectionYourBuildingValue(city,target,kind,true,YieldTypes.YIELD_FOOD,domain)
   local gold=player:GetTradeConnectionYourBuildingValue(city,target,kind,true,YieldTypes.YIELD_GOLD,domain)
   local expectedFood=(kind==1 and domain==DomainTypes.DOMAIN_SEA)and 50 or 100
   local expectedGold=(kind==0 and domain==DomainTypes.DOMAIN_LAND)and 200 or 0
   local control=Players[1]:GetTradeConnectionYourBuildingValue(target,city,kind,true,YieldTypes.YIELD_FOOD,domain)
   rows[#rows+1]={kind=kind,domain=domain,food=food,gold=gold,expected_food=expectedFood,expected_gold=expectedGold,roman_control_food=control}
   assert(food==expectedFood and gold==expectedGold and control==0,"Tomb building trade-query matrix differs from shipped data")
  end end
  LekmodScenarioEvent("tomb-six-route-building-quotes",rows)
  LekmodScenarioRecord("tomb-six-route-quotes","PASS","native building contribution queries only; six type/domain cases and Roman-origin controls; sea food internal=0.5")
  quote=after;before.city=s
  local u=assert(player:GetUnitByID(unitID));local target=assert(Players[1]:GetCityByID(targetID))
  assert(u:CanMakeTradeRouteAt(u:GetPlot(),target:GetX(),target:GetY(),quote.kind))
  UI.SelectUnit(u)
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_ESTABLISH_TRADE_ROUTE,target:Plot():GetPlotIndex(),quote.kind,0,false,nil)
  phase="route";return false
 elseif phase=="route"then
  local routes=player:GetTradeRoutes()
  if not LekmodScenarioAwait("Tomb-land-route",#routes==1)then return false end
  local r=routes[1]
  assert(r.FromCity:GetID()==originID and r.ToID==1 and r.ToCity:GetID()==targetID)
  local food=player:GetTradeConnectionTotalValue(r.FromCity,r.ToCity,r.ConnectionType,true,YieldTypes.YIELD_FOOD,r.Domain,true)
  LekmodScenarioEvent("tomb-active-route-quote-comparison",{food=food,gold=r.FromGPT,quote=quote,city=cityState(city)})
  assert(food==quote.food and r.FromGPT==quote.gold,"active route calculation differs from legal quote")
  assert(city:GetYieldRateTimes100(YieldTypes.YIELD_FOOD)==before.city.gross_food+100,"active route did not add one food to origin city")
  LekmodScenarioEvent("tomb-route-result",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("tomb-land-route-bonuses","PASS","normal synchronized international land mission; exact quoted food/gold; origin gross food+1")
  return true
 end
 return false
end
