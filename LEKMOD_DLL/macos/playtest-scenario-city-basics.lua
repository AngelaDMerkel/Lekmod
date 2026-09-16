LekmodScenario={name="city-basics",items={"additional-city","building-purchase","building-sale-cancel","building-sale","city-growth","city-starvation"}}
local phase,settlerID,cityID,x,y,count,building,cost,refund,gold,response,pop,turn="init"
local foundEvent,purchaseEvent=false,false
LuaEvents.LekmodScenarioCityResponse.Add(function(kind,id) response={kind=kind,id=id} end)
GameEvents.PlayerCityFounded.Add(function(owner,cx,cy)
    if owner==Game.GetActivePlayer() and cx==x and cy==y then foundEvent=true end
end)
GameEvents.CityConstructed.Add(function(owner,city,b,goldPurchase,faith)
    if owner==Game.GetActivePlayer() and city==cityID and b==building and goldPurchase and not faith then purchaseEvent=true end
end)
local function found(unit)
    UI.SelectUnit(unit)
    for i=0,#GameInfoActions do
        if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_FOUND" then
            assert(Game.CanHandleAction(i),"settlement action is unavailable")
            Game.HandleAction(i);return
        end
    end
    error("settlement action missing")
end
function LekmodScenario.snapshot(player)
    local cities={}
    for city in player:Cities() do
        local buildings={}
        for info in GameInfo.Buildings() do if city:GetNumRealBuilding(info.ID)>0 then buildings[info.ID]=city:GetNumRealBuilding(info.ID) end end
        cities[city:GetID()]={x=city:GetX(),y=city:GetY(),population=city:GetPopulation(),food100=city:GetFoodTimes100(),
            focus=city:GetFocusType(),puppet=city:IsPuppet(),occupied=city:IsOccupied(),buildings=buildings}
    end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),cities=cities}
end
function LekmodScenario.step(player)
    if phase=="init" then
        local capital=assert(player:GetCapitalCity())
        local best,plot=999,nil
        for i=0,Map.GetNumPlots()-1 do
            local candidate=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(capital:GetX(),capital:GetY(),candidate:GetX(),candidate:GetY())
            if distance>=4 and distance<=9 and distance<best and candidate:GetArea()==capital:Plot():GetArea()
                and candidate:GetOwner()==-1 and candidate:GetNumUnits()==0 and not candidate:IsWater() and not candidate:IsMountain()
                and player:CanFound(candidate:GetX(),candidate:GetY()) then plot,best=candidate,distance end
        end
        assert(plot,"no legal second-city plot on the capital's landmass")
        x,y=plot:GetX(),plot:GetY();count=player:GetNumCities()
        local unit=assert(player:InitUnit(GameInfoTypes.UNIT_SETTLER,x,y));settlerID=unit:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-settler",id=settlerID,x=x,y=y})
        assert(unit:CanFound(plot),"settler cannot legally found at input location")
        found(unit);phase="founded"
    elseif phase=="founded" then
        local city=Map.GetPlot(x,y):GetPlotCity()
        if not LekmodScenarioAwait("second-city",city~=nil and city:GetOwner()==player:GetID() and player:GetNumCities()==count+1 and foundEvent) then return false end
        local settler=player:GetUnitByID(settlerID)
        assert(not settler or settler:IsDead() or settler:IsDelayedDeath(),"founding did not consume settler")
        cityID=city:GetID()
        LekmodScenarioRecord("additional-city","PASS","path=normal-found-action city="..cityID)
        local cheapest=math.huge
        for info in GameInfo.Buildings() do
            local class=GameInfo.BuildingClasses[info.BuildingClass]
            if class and class.MaxGlobalInstances<=0 and class.MaxPlayerInstances<=0 and class.MaxTeamInstances<=0
                and info.Cost>0 and city:GetNumRealBuilding(info.ID)==0 and city:IsCanPurchase(false,true,-1,info.ID,-1,YieldTypes.YIELD_GOLD) then
                local price=city:GetBuildingPurchaseCost(info.ID)
                if price>0 and price<cheapest then building,cheapest=info.ID,price end
            end
        end
        assert(building,"new city has no suitable purchasable building")
        cost=city:GetBuildingPurchaseCost(building)
        LekmodScenarioEvent("building-purchase-choice",{building=building,type=GameInfo.Buildings[building].Type,cost=cost})
        assert(cost>0,"building has invalid purchase cost")
        if player:GetGold()<cost then
            local amount=cost-player:GetGold()+100;player:ChangeGold(amount)
            LekmodScenarioEvent("fixture-setup",{operation="provided-gold",added=amount})
        end
        gold=player:GetGold();response=nil
        LuaEvents.LekmodScenarioBuildingPurchase(cityID,building);phase="purchased"
    elseif phase=="purchased" then
        if not response then return false end
        local city=assert(player:GetCityByID(cityID))
        if not LekmodScenarioAwait("building-purchased",city:GetNumRealBuilding(building)==1 and player:GetGold()==gold-cost and purchaseEvent) then return false end
        assert(response.kind=="purchase" and response.id==building,"wrong purchase response")
        LekmodScenarioRecord("building-purchase","PASS","path=ProductionPopup-callback gold="..cost.." building="..building)
        assert(city:IsBuildingSellable(building),"purchased building is not sellable")
        assert(not player:GetCapitalCity():IsBuildingSellable(GameInfoTypes.BUILDING_PALACE),"palace is sellable")
        refund=city:GetSellBuildingRefund(building);gold=player:GetGold();response=nil
        LuaEvents.LekmodScenarioCitySale(cityID,building);phase="sold"
    elseif phase=="sold" then
        if not response then return false end
        local city=assert(player:GetCityByID(cityID))
        assert(response.kind=="sale" and city:GetNumRealBuilding(building)==0 and player:GetGold()==gold+refund,"sale/refund mismatch")
        LekmodScenarioRecord("building-sale","PASS","path=CityView-confirmation refund="..refund.." palace-sale=rejected")
        Network.SendSetCityAIFocus(cityID,CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD)
        Network.SendSetCityAvoidGrowth(cityID,false);phase="growth-input"
    elseif phase=="growth-input" then
        local city=assert(player:GetCityByID(cityID))
        if not LekmodScenarioAwait("growth-focus",city:GetFocusType()==CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD and not city:IsForcedAvoidGrowth()) then return false end
        if city:FoodDifferenceTimes100()<=0 then
            local before=city:GetPopulation();city:SetPopulation(1,true)
            LekmodScenarioEvent("fixture-setup",{operation="provided-growth-population",city=cityID,before=before,after=1})
        end
        LekmodScenarioEvent("growth-food-state",{population=city:GetPopulation(),food100=city:GetYieldRateTimes100(YieldTypes.YIELD_FOOD),
            difference100=city:FoodDifferenceTimes100(),happiness=player:GetExcessHappiness(),production_unit=city:GetProductionUnit()})
        assert(city:FoodDifferenceTimes100()>0,"growth fixture has no food surplus")
        local before=city:GetFood();local food=city:GrowthThreshold()-1;city:SetFood(food)
        LekmodScenarioEvent("fixture-setup",{operation="provided-near-growth-food",city=cityID,before=before,after=food})
        pop=city:GetPopulation();turn=Game.GetGameTurn();phase="grown";return "turn"
    elseif phase=="grown" then
        if Game.GetGameTurn()==turn then return "turn" end
        local city=assert(player:GetCityByID(cityID))
        if city:GetPopulation()==pop then
            assert(Game.GetGameTurn()-turn<=8,"ordinary food turns did not grow the city")
            return "turn"
        end
        assert(city:GetPopulation()==pop+1,"growth changed more than one population")
        LekmodScenarioRecord("city-growth","PASS","path=ordinary-turn before="..pop.." after="..city:GetPopulation().." turns="..Game.GetGameTurn()-turn)
        city:SetPopulation(20,true);city:SetFood(0)
        LekmodScenarioEvent("fixture-setup",{operation="provided-starvation-boundary",city=cityID,population=20,food=0})
        assert(city:FoodDifferenceTimes100()<0,"starvation fixture has no food deficit")
        turn=Game.GetGameTurn();phase="starved";return "turn"
    elseif phase=="starved" then
        if Game.GetGameTurn()==turn then return "turn" end
        local city=assert(player:GetCityByID(cityID))
        assert(city:GetPopulation()==19,"ordinary starvation turn did not remove one population")
        LekmodScenarioRecord("city-starvation","PASS","path=ordinary-turn population=20-to-19")
        return true
    end
    return false
end
