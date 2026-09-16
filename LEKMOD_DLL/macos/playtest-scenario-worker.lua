-- Ordinary new-game founding; the worker and road technology are labeled
-- inputs. Farm, road and repair completion must follow normal worker actions.
LekmodScenario={name="worker",items={"worker-farm","worker-road","worker-repair","worker-restrictions"}}
local phase,unitID,plotIndex,beforeFood,farmFood,issuedTurn="init"
local farm,road=GameInfoTypes.BUILD_FARM,GameInfoTypes.BUILD_ROAD
local function action(unit,kind)
    UI.SelectUnit(unit)
    for i=0,#GameInfoActions do
        if GameInfoActions[i] and GameInfoActions[i].Type==kind then
            assert(Game.CanHandleAction(i),"worker action unavailable: "..kind)
            Game.HandleAction(i);return
        end
    end
    error("worker action missing: "..kind)
end
function LekmodScenario.snapshot(player)
    local plots,units={},{}
    for i=0,Map.GetNumPlots()-1 do
        local plot=Map.GetPlotByIndex(i)
        if plot:GetOwner()==player:GetID() and (plot:GetImprovementType()~=-1 or plot:GetRouteType()~=-1) then
            plots[i]={improvement=plot:GetImprovementType(),pillaged=plot:IsImprovementPillaged(),route=plot:GetRouteType(),route_pillaged=plot:IsRoutePillaged(),
                food=plot:CalculateYield(YieldTypes.YIELD_FOOD,true),production=plot:CalculateYield(YieldTypes.YIELD_PRODUCTION,true),gold=plot:CalculateYield(YieldTypes.YIELD_GOLD,true)}
        end
    end
    for unit in player:Units() do
        units[unit:GetID()]={type=unit:GetUnitType(),x=unit:GetX(),y=unit:GetY(),moves=unit:GetMoves()}
    end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),plots=plots,units=units}
end
function LekmodScenario.step(player)
    local city=player:GetCapitalCity()
    if not city then return "turn" end
    if phase=="init" then
        LekmodScenarioGrantTech(player,"TECH_THE_WHEEL")
        local plot
        for i=0,Map.GetNumPlots()-1 do
            local candidate=Map.GetPlotByIndex(i)
            if candidate:GetOwner()==player:GetID() and not candidate:IsCity() and not candidate:IsWater() and not candidate:IsMountain()
                and candidate:GetFeatureType()==-1 and candidate:GetResourceType(-1)==-1 and candidate:GetImprovementType()==-1 and candidate:GetNumUnits()==0
                and candidate:CanBuild(farm,player:GetID(),false,true) then
                plot,plotIndex=candidate,i;break
            end
        end
        assert(plot,"no bare owned plot for worker fixture")
        local unit=assert(player:InitUnit(GameInfoTypes.UNIT_WORKER,plot:GetX(),plot:GetY()))
        unitID=unit:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-worker",id=unitID,x=plot:GetX(),y=plot:GetY()})
        assert(unit:CanBuild(plot,farm),"selected plot cannot legally receive a farm")
        assert(not unit:CanBuild(city:Plot(),farm),"farm allowed on a city tile")
        local water
        for i=0,Map.GetNumPlots()-1 do local candidate=Map.GetPlotByIndex(i);if candidate:IsWater() then water=candidate;break end end
        assert(water and not unit:CanBuild(water,farm),"farm allowed on water")
        beforeFood=plot:CalculateYield(YieldTypes.YIELD_FOOD,true)
        action(unit,"BUILD_FARM");issuedTurn=Game.GetGameTurn();phase="farm";return "turn"
    elseif phase=="farm" then
        local plot=Map.GetPlotByIndex(plotIndex)
        if plot:GetImprovementType()~=GameInfoTypes.IMPROVEMENT_FARM then
            assert(Game.GetGameTurn()-issuedTurn<=6,"farm did not finish within six turns");return "turn"
        end
        farmFood=plot:CalculateYield(YieldTypes.YIELD_FOOD,true)
        assert(farmFood>beforeFood and not plot:IsImprovementPillaged(),"farm did not improve food yield")
        local unit=assert(player:GetUnitByID(unitID))
        assert(not unit:CanBuild(plot,farm),"duplicate farm remains eligible")
        LekmodScenarioRecord("worker-farm","PASS","path=normal-build-action food-before="..beforeFood.." food-after="..farmFood)
        LekmodScenarioRecord("worker-restrictions","PASS","city-farm=rejected water-farm=rejected duplicate-farm=rejected")
        phase="road-order"
    elseif phase=="road-order" then
        local unit=assert(player:GetUnitByID(unitID));local plot=Map.GetPlotByIndex(plotIndex)
        if unit:GetMoves()<=0 then return "turn" end
        assert(unit:CanBuild(plot,road),"road is not legal")
        action(unit,"BUILD_ROAD");issuedTurn=Game.GetGameTurn();phase="road";return "turn"
    elseif phase=="road" then
        local plot=Map.GetPlotByIndex(plotIndex)
        if plot:GetRouteType()~=GameInfoTypes.ROUTE_ROAD then
            assert(Game.GetGameTurn()-issuedTurn<=6,"road did not finish within six turns");return "turn"
        end
        assert(plot:GetImprovementType()==GameInfoTypes.IMPROVEMENT_FARM and not plot:IsRoutePillaged(),"road damaged/replaced the farm")
        LekmodScenarioRecord("worker-road","PASS","path=normal-build-action farm-retained=true")
        plot:SetImprovementPillaged(true)
        LekmodScenarioEvent("fixture-setup",{operation="provided-pillaged-farm",plot=plotIndex})
        assert(plot:IsImprovementPillaged() and plot:CalculateYield(YieldTypes.YIELD_FOOD,true)<farmFood,"pillaged input did not remove farm yield")
        phase="repair-order"
    elseif phase=="repair-order" then
        local unit=assert(player:GetUnitByID(unitID))
        if unit:GetMoves()<=0 then return "turn" end
        action(unit,"BUILD_REPAIR");issuedTurn=Game.GetGameTurn();phase="repair"
        return "turn"
    elseif phase=="repair" then
        local plot=Map.GetPlotByIndex(plotIndex)
        if plot:IsImprovementPillaged() then
            assert(Game.GetGameTurn()-issuedTurn<=6,"repair did not finish within six turns");return "turn"
        end
        assert(plot:GetImprovementType()==GameInfoTypes.IMPROVEMENT_FARM and plot:GetRouteType()==GameInfoTypes.ROUTE_ROAD,"repair changed improvement/route type")
        assert(plot:CalculateYield(YieldTypes.YIELD_FOOD,true)==farmFood,"repair failed to restore the farm's food")
        LekmodScenarioRecord("worker-repair","PASS","path=normal-repair-action farm-and-road=retained food="..farmFood)
        return true
    end
    return false
end
