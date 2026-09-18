-- Population, Granary and near-growth stored food are labeled fixture inputs.
-- Ranchero selection and the growth/production outcome use normal gameplay.
LekmodScenario={name="mexico-ranchero",items={"ranchero-selection","ranchero-growth-during-training"}}
local phase,turn,before="init"
local ranchero=GameInfoTypes.UNIT_RANCHERO
local function count(player)
    local n=0;for unit in player:Units() do if unit:GetUnitType()==ranchero and not unit:IsDelayedDeath() then n=n+1 end end;return n
end
function LekmodScenario.snapshot(player)
    local city=assert(player:GetCapitalCity())
    return {turn=Game.GetGameTurn(),city=city:GetID(),population=city:GetPopulation(),food100=city:GetFoodTimes100(),food_rate100=city:FoodDifferenceTimes100(),focus=city:GetFocusType(),avoid=city:IsForcedAvoidGrowth(),food_production=city:IsFoodProduction(),production_unit=city:GetProductionUnit(),production100=city:GetProductionTimes100(),production_needed=city:GetProductionNeeded(),rancheros=count(player),granary=city:GetNumRealBuilding(GameInfoTypes.BUILDING_GRANARY)}
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity())
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MEXICO,"requires Mexico")
    if phase=="init" then
        city:SetPopulation(4,true)
        if city:GetNumRealBuilding(GameInfoTypes.BUILDING_GRANARY)==0 then city:SetNumRealBuilding(GameInfoTypes.BUILDING_GRANARY,1) end
        LekmodScenarioEvent("fixture-setup",{operation="provided-growth-population-and-granary",population=4,granary=1})
        Network.SendSetCityAIFocus(city:GetID(),CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD)
        Network.SendSetCityAvoidGrowth(city:GetID(),false)
        phase="order"
    elseif phase=="order" then
        if not LekmodScenarioAwait("ranchero-focus",city:GetFocusType()==CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD and not city:IsForcedAvoidGrowth()) then return false end
        assert(city:CanTrain(ranchero),"Ranchero training is unavailable")
        assert(not city:CanTrain(GameInfoTypes.UNIT_SETTLER),"Mexico may train the replaced base Settler")
        Game.CityPushOrder(city,OrderTypes.ORDER_TRAIN,ranchero,false,true,true)
        phase="queued"
    elseif phase=="queued" then
        if not LekmodScenarioAwait("ranchero-order",city:GetProductionUnit()==ranchero) then return false end
        assert(not city:IsFoodProduction(),"Ranchero is incorrectly marked as food production")
        assert(city:FoodDifferenceTimes100()>=100,"fixture lacks one food of ordinary surplus")
        assert(city:GetProductionTimes100()+city:GetCurrentProductionDifferenceTimes100(false,false)<city:GetProductionNeeded()*100,"fixture would complete the Ranchero before measuring training growth")
        city:SetFood(city:GrowthThreshold()-1)
        LekmodScenarioEvent("fixture-setup",{operation="provided-near-growth-food",food=city:GetFood(),threshold=city:GrowthThreshold()})
        before=LekmodScenario.snapshot(player);turn=Game.GetGameTurn()
        LekmodScenarioEvent("ranchero-before-turn",before)
        LekmodScenarioRecord("ranchero-selection","PASS","path=normal-city-production-order base-settler-rejected=true food-production=false")
        phase="growth";return "turn"
    elseif phase=="growth" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Game.GetGameTurn()==turn+1,"growth observation exceeded one ordinary turn")
        local s=LekmodScenario.snapshot(player)
        LekmodScenarioEvent("ranchero-after-turn",s)
        assert(s.population==before.population+1,"city did not grow while training Ranchero")
        assert(s.production_unit==ranchero and s.production100>before.production100 and s.rancheros==before.rancheros,"Ranchero did not remain under construction with normal production progress")
        assert(not s.food_production,"growth outcome became food production")
        LekmodScenarioRecord("ranchero-growth-during-training","PASS","path=ordinary-turn population=4-to-5 Ranchero-still-under-construction=true")
        return true
    end
    return false
end
