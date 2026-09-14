-- Supplies a recorded gold budget, then purchases a real trade unit, creates
-- an available route, and waits for ordinary gold settlement. No unit, route,
-- movement points or income outcome is granted.
LekmodScenario={name="trade",items={"gold-unit-purchase","trade-route","trade-yield","trade-income"}}
local phase,response,unitType,unitID,cost,beforeGold,beforeUsed,beforeRoutes,beforeTrade,x,y,kind,ledger="init"
local purchased={}
local function tradeGold(player)
    local total=0
    for city in player:Cities() do
        total=total+city:GetYieldRateTimes100(YieldTypes.YIELD_GOLD,false)-city:GetYieldRateTimes100(YieldTypes.YIELD_GOLD,true)
    end
    return total
end
LuaEvents.LekmodScenarioTradeResponse.Add(function(key,value) response={kind=key,value=value} end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
    if owner==Game.GetActivePlayer() and gold and not faith then purchased[id]=true end
end)
local function findRoute(player)
    for _,route in ipairs(player:GetTradeRoutes()) do
        if route.ToCity:GetX()==x and route.ToCity:GetY()==y and route.FromCity:GetID()==player:GetCapitalCity():GetID() then return route end
    end
end
function LekmodScenario.snapshot(player)
    local routes={}
    for index,route in ipairs(player:GetTradeRoutes()) do
        local row={}
        for key,value in pairs(route) do
            row[key]=(key=="FromCity" or key=="ToCity") and value:GetID() or value
        end
        routes[index]=row
    end
    return {turn=Game.GetGameTurn(),player=player:GetID(),gold=player:GetGold(),
        trade100=tradeGold(player),used=player:GetNumInternationalTradeRoutesUsed(),routes=routes}
end
function LekmodScenarioBeforeEndTurn(player,turn)
    if phase=="income" then
        ledger={turn=turn,gold=player:GetGold(),rate100=player:CalculateGoldRateTimes100(),trade100=tradeGold(player)}
        LekmodScenarioEvent("trade-ledger-before",ledger)
    end
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity(), "trade fixture needs a capital")
    if phase=="init" then
        unitType=player:GetTradeUnitType(DomainTypes.DOMAIN_LAND)
        local info=assert(GameInfo.Units[unitType], "fixture has no land trade unit type")
        LekmodScenarioEvent("trade-prerequisites",{unit=unitType,type=info.Type,prerequisite=info.PrereqTech,can_train=city:CanTrain(unitType)})
        if info.PrereqTech then LekmodScenarioGrantTech(player,info.PrereqTech) end
        if not city:CanTrain(unitType) then
            local building=assert(GameInfo.Buildings.BUILDING_CARAVANSARY)
            if building.PrereqTech then LekmodScenarioGrantTech(player,building.PrereqTech) end
            local before=city:GetNumRealBuilding(building.ID)
            if before==0 then
                city:SetNumRealBuilding(building.ID,1)
                LekmodScenarioEvent("fixture-setup",{operation="provided-range-building",building=building.ID,before=before,after=1})
            end
        end
        local range=player:GetTradeRouteRange(DomainTypes.DOMAIN_LAND,city)
        local revealed=0
        for index=0,Map.GetNumPlots()-1 do
            local plot=Map.GetPlotByIndex(index)
            if Map.PlotDistance(city:GetX(),city:GetY(),plot:GetX(),plot:GetY())<=range and not plot:IsRevealed(player:GetTeam()) then
                plot:SetRevealed(player:GetTeam(),true)
                revealed=revealed+1
            end
        end
        LekmodScenarioEvent("fixture-setup",{operation="revealed-trade-range",range=range,plots=revealed})
        phase="fund"
    elseif phase=="fund" then
        LekmodScenarioEvent("trade-eligibility",{can_train=city:CanTrain(unitType),tooltip=city:CanTrainTooltip(unitType)})
        assert(city:CanTrain(unitType), "fixture cannot train its land trade unit after prerequisite setup")
        cost=city:GetUnitPurchaseCost(unitType)
        local old=player:GetGold(); player:ChangeGold(cost+200)
        beforeGold=player:GetGold()
        LekmodScenarioEvent("fixture-setup",{operation="provided-gold",before=old,added=cost+200,after=beforeGold})
        assert(city:IsCanPurchase(true,true,unitType,-1,-1,YieldTypes.YIELD_GOLD), "trade unit purchase is not legal")
        response=nil; LuaEvents.LekmodScenarioGoldPurchase(city:GetID(),unitType); phase="purchase"
    elseif phase=="purchase" then
        if not response then return false end
        if not LekmodScenarioAwait("gold-spent",player:GetGold()==beforeGold-cost) then return false end
        assert(response.kind=="purchase", "unexpected purchase callback")
        for unit in player:Units() do
            if purchased[unit:GetID()] and unit:GetUnitType()==unitType then unitID=unit:GetID(); break end
        end
        assert(unitID, "purchased trade unit not observed")
        LekmodScenarioRecord("gold-unit-purchase","PASS","path=production-popup-callback unit="..unitID.." gold-spent="..cost)
        phase="route-ready"
    elseif phase=="route-ready" then
        local unit=assert(player:GetUnitByID(unitID), "purchased unit disappeared")
        if unit:MovesLeft()==0 then return "turn" end
        local options=player:GetPotentialInternationalTradeRouteDestinations(unit)
        for _,entry in ipairs(options) do
            local target=Map.GetPlot(entry.X,entry.Y):GetPlotCity()
            -- Aspyr does not expose TradeConnectionTypes as a Lua enum table.
            -- A returned legal connection to a different team is international.
            if target and target:GetTeam()~=player:GetTeam() then
                x,y,kind=entry.X,entry.Y,entry.TradeConnectionType; break
            end
        end
        assert(x, "fixture has no available international route")
        beforeUsed=player:GetNumInternationalTradeRoutesUsed()
        beforeRoutes=#player:GetTradeRoutes()
        beforeTrade=tradeGold(player)
        response=nil; LuaEvents.LekmodScenarioTradeRoute(unitID,x,y,kind); phase="route"
    elseif phase=="route" then
        if not response then return false end
        local route=findRoute(player)
        if not LekmodScenarioAwait("route-created",route~=nil) then return false end
        assert(#player:GetTradeRoutes()==beforeRoutes+1, "active route count did not increase")
        -- Used slots already include the unassigned purchased caravan. Creating
        -- its route consumes that unit rather than requiring another slot.
        assert(player:GetNumInternationalTradeRoutesUsed()==beforeUsed, "route creation changed occupied trade slots")
        -- Lekmod folds trade into city yields; the legacy Treasury trade getter
        -- deliberately returns zero to avoid counting it a second time.
        LekmodScenarioEvent("trade-yield-observed",{before100=beforeTrade,after100=tradeGold(player),route100=route.FromGPT,active_routes=#player:GetTradeRoutes(),used_slots=player:GetNumInternationalTradeRoutesUsed()})
        assert(route.FromGPT>0 and tradeGold(player)==beforeTrade+route.FromGPT, "new route's gold contribution did not apply")
        LekmodScenarioRecord("trade-route","PASS","path=real-popup-callback destination="..x..","..y)
        LekmodScenarioRecord("trade-yield","PASS","delta100="..route.FromGPT.." path=engine-accounting")
        phase="income"
    elseif phase=="income" then
        if not ledger or Game.GetGameTurn()==ledger.turn then return "turn" end
        assert(Game.GetGameTurn()==ledger.turn+1, "trade settlement skipped a turn")
        assert(findRoute(player), "trade route disappeared before settlement")
        local delta=player:GetGold()-ledger.gold
        LekmodScenarioEvent("trade-ledger-after",{turn=Game.GetGameTurn(),gold=player:GetGold(),delta=delta,expected_rate100=ledger.rate100})
        -- GetGold exposes whole gold; the engine retains hundredths internally.
        assert(math.abs(delta-ledger.rate100/100)<1.01, "treasury change differs from the recorded gold rate")
        LekmodScenarioRecord("trade-income","PASS","path=ordinary-turn-settlement delta="..delta.." rate100="..ledger.rate100)
        return true
    end
    return false
end
