-- Legal coastal cities, origin buildings, reveal and trade units are supplied.
-- Rebase and routes use actual standard popup callbacks and engine accounting.
LekmodScenario={name="trade-internal",items={"trade-rebase-cancel","trade-rebase","internal-land-food","internal-sea-production","internal-route-restrictions"}}
local phase,a,b,land,sea,reply,target,kind,baseline,amount,yieldType,domain,routeCount="init"
LuaEvents.LekmodTradeHomeDone.Add(function(id) reply=id end)
LuaEvents.LekmodScenarioTradeResponse.Add(function(k,id) if k=="route" then reply=id end end)
local function seaArea(plot)
    for d=0,5 do local p=Map.PlotDirection(plot:GetX(),plot:GetY(),d)
        if p and p:IsWater() and not p:IsLake() then return p:GetArea() end
    end
end
local function tradeYield(city,y)
    return city:GetYieldRateTimes100(y,false)-city:GetYieldRateTimes100(y,true)
end
function LekmodScenario.snapshot(player)
    local routes,cities,units={},{},{}
    for index,row in ipairs(player:GetTradeRoutes()) do
        local r={};for key,value in pairs(row) do r[key]=(key=="FromCity" or key=="ToCity") and value:GetID() or value end;routes[index]=r
    end
    for c in player:Cities() do cities[c:GetID()]={food100=tradeYield(c,YieldTypes.YIELD_FOOD),production100=tradeYield(c,YieldTypes.YIELD_PRODUCTION),gold100=tradeYield(c,YieldTypes.YIELD_GOLD)} end
    for u in player:Units() do if u:IsTrade() then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()} end end
    return {turn=Game.GetGameTurn(),routes=routes,cities=cities,units=units,used=player:GetNumInternationalTradeRoutesUsed()}
end
local function startRoute(player,id,desiredYield,desiredDomain)
    local u=assert(player:GetUnitByID(id));if u:GetMoves()<=0 then return "turn" end
    local option
    for _,r in ipairs(player:GetPotentialInternationalTradeRouteDestinations(u)) do
        local c=Map.GetPlot(r.X,r.Y):GetPlotCity();local y=r.Yields[desiredYield+1]
        if c and c:GetOwner()==player:GetID() and y and y.Theirs>0 then option=r;target=c:GetID();amount=y.Theirs;break end
    end
    assert(option,"no legal internal route with requested yield/domain")
    yieldType,domain=desiredYield,desiredDomain;kind=option.TradeConnectionType
    baseline=tradeYield(player:GetCityByID(target),yieldType);routeCount=#player:GetTradeRoutes()
    assert(not u:CanMakeTradeRouteAt(u:GetPlot(),u:GetX(),u:GetY(),kind),"same-city trade route is legal")
    reply=nil;LuaEvents.LekmodScenarioTradeRoute(id,option.X,option.Y,kind)
    return false
end
local function verifyRoute(player,id)
    if reply~=id then return false end
    local c=player:GetCityByID(target);local found
    for _,r in ipairs(player:GetTradeRoutes()) do if r.ToID==player:GetID() and r.ToCity:GetID()==target and r.ConnectionType==kind and r.Domain==domain then found=r;break end end
    if not LekmodScenarioAwait("internal-route-created",found~=nil and #player:GetTradeRoutes()==routeCount+1) then return false end
    LekmodScenarioEvent("internal-route-yield",{domain=domain,kind=kind,target=target,yield=yieldType,before100=baseline,after100=tradeYield(c,yieldType),quoted100=amount})
    assert(tradeYield(c,yieldType)==baseline+amount,"internal route's quoted yield did not reach its destination")
    assert(found.TurnsLeft>0,"new route countdown is not positive")
    local available
    for _,r in ipairs(player:GetTradeRoutesAvailable()) do
        if r.FromCity:GetID()==found.FromCity:GetID() and r.ToCity:GetID()==found.ToCity:GetID()
            and r.Domain==found.Domain and r.ConnectionType==found.ConnectionType then available=r;break end
    end
    assert(available and available.TurnsLeft==found.TurnsLeft,"active and available route lists disagree on countdown")
    LekmodScenarioEvent("trade-countdown",{domain=found.Domain,turns=found.TurnsLeft,from=found.FromCity:GetID(),to=found.ToCity:GetID()})
    return true
end
function LekmodScenario.step(player)
    local capital=assert(player:GetCapitalCity())
    if phase=="init" then
        local first,second
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if p:GetOwner()==-1 and p:GetNumUnits()==0 and player:CanFound(p:GetX(),p:GetY()) and seaArea(p)
                and Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())<=8 then
                player:Found(p:GetX(),p:GetY());first=p:GetPlotCity();break
            end
        end
        assert(first and first:IsCoastal(10),"no first legal coastal city")
        local water=seaArea(first:Plot())
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if p:GetOwner()==-1 and p:GetNumUnits()==0 and player:CanFound(p:GetX(),p:GetY()) and seaArea(p)==water
                and Map.PlotDistance(first:GetX(),first:GetY(),p:GetX(),p:GetY())<=12 then
                player:Found(p:GetX(),p:GetY());second=p:GetPlotCity();break
            end
        end
        assert(second and second:IsCoastal(10),"no second legal city on the same sea")
        a,b=first:GetID(),second:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-legal-coastal-cities",first=a,second=b,first_x=first:GetX(),first_y=first:GetY(),second_x=second:GetX(),second_y=second:GetY()})
        for _,c in ipairs({capital,first,second}) do
            for _,building in ipairs({"BUILDING_GRANARY","BUILDING_WORKSHOP","BUILDING_CARAVANSARY","BUILDING_HARBOR"}) do
                if c:GetNumBuilding(GameInfoTypes[building])==0 and (building~="BUILDING_HARBOR" or c:IsCoastal(10)) then
                    c:SetNumRealBuilding(GameInfoTypes[building],1);LekmodScenarioEvent("fixture-setup",{operation="provided-trade-origin-building",city=c:GetID(),building=building})
                end
            end
            Game.CityPushOrder(c,OrderTypes.ORDER_MAINTAIN,GameInfoTypes.PROCESS_WEALTH,false,true,true)
        end
        local revealed=0
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if Map.PlotDistance(first:GetX(),first:GetY(),p:GetX(),p:GetY())<=player:GetTradeRouteRange(DomainTypes.DOMAIN_SEA,first) and not p:IsRevealed(player:GetTeam()) then p:SetRevealed(player:GetTeam(),true);revealed=revealed+1 end
        end
        LekmodScenarioEvent("fixture-setup",{operation="revealed-trade-range",plots=revealed})
        assert(player:GetNumInternationalTradeRoutesAvailable()-player:GetNumInternationalTradeRoutesUsed()>=2,"fixture lacks two free trade slots")
        local u=assert(player:InitUnit(player:GetTradeUnitType(DomainTypes.DOMAIN_LAND),capital:GetX(),capital:GetY()));land=u:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-land-trade-unit",id=land})
        local eligible=false
        for _,home in ipairs(player:GetPotentialTradeUnitNewHomeCity(u)) do
            assert(home.X~=capital:GetX() or home.Y~=capital:GetY(),"current home appears as a rebase destination")
            if home.X==first:GetX() and home.Y==first:GetY() then eligible=true end
        end
        assert(eligible,"coastal city is not a legal caravan home")
        reply=nil;LuaEvents.LekmodTradeHome(land,first:GetX(),first:GetY());phase="rebased"
    elseif phase=="rebased" then
        local u=assert(player:GetUnitByID(land));local c=player:GetCityByID(a)
        if not LekmodScenarioAwait("trade-rebased",reply==land and u:GetX()==c:GetX() and u:GetY()==c:GetY()) then return false end
        LekmodScenarioRecord("trade-rebase","PASS","path=actual-home-popup-confirmation")
        phase="land-route"
    elseif phase=="land-route" then
        local result=startRoute(player,land,YieldTypes.YIELD_FOOD,DomainTypes.DOMAIN_LAND)
        if result=="turn" then return result end;phase="land-created"
    elseif phase=="land-created" then
        if not verifyRoute(player,land) then return false end
        LekmodScenarioRecord("internal-land-food","PASS","path=actual-route-popup yield100="..amount)
        local c=player:GetCityByID(a);local u=assert(player:InitUnit(player:GetTradeUnitType(DomainTypes.DOMAIN_SEA),c:GetX(),c:GetY()));sea=u:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-sea-trade-unit",id=sea,city=a});phase="sea-route"
    elseif phase=="sea-route" then
        local result=startRoute(player,sea,YieldTypes.YIELD_PRODUCTION,DomainTypes.DOMAIN_SEA)
        if result=="turn" then return result end;phase="sea-created"
    elseif phase=="sea-created" then
        if not verifyRoute(player,sea) then return false end
        LekmodScenarioRecord("internal-sea-production","PASS","path=actual-route-popup yield100="..amount)
        LekmodScenarioRecord("internal-route-restrictions","PASS","same-city-route-and-current-home=rejected")
        return true
    end
    return false
end
