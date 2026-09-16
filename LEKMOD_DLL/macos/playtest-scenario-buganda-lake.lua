-- Real worker construction and native freshwater queries. Technology and the
-- worker are supplied inputs; no improvement or freshwater state is assigned.
LekmodScenario={name="buganda-lake",items={"buganda-lake-build","buganda-lake-freshwater","buganda-lake-restrictions"}}
local phase,unitID,plotIndex,issuedTurn="init"
local dry={}
local build=GameInfoTypes.BUILD_BUGANDA_LAKE
function LekmodScenario.snapshot(player)
    local plots={}
    for i=0,Map.GetNumPlots()-1 do
        local p=Map.GetPlotByIndex(i)
        if p:GetImprovementType()==GameInfoTypes.IMPROVEMENT_BUGANDA_LAKE then
            local adjacent={}
            for d=0,5 do local a=Map.PlotDirection(p:GetX(),p:GetY(),d)
                if a then adjacent[d]={x=a:GetX(),y=a:GetY(),fresh=a:IsFreshWater()} end
            end
            plots[i]={fresh=p:IsFreshWater(),water=p:IsWater(),pillaged=p:IsImprovementPillaged(),
                food=p:CalculateYield(YieldTypes.YIELD_FOOD,true),gold=p:CalculateYield(YieldTypes.YIELD_GOLD,true),adjacent=adjacent}
        end
    end
    return {turn=Game.GetGameTurn(),civ=player:GetCivilizationType(),plots=plots}
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_BUGANDA,"choose Buganda in normal setup")
    local city=player:GetCapitalCity()
    if not city then return "turn" end
    if phase=="init" then
        LekmodScenarioGrantTech(player,"TECH_CIVIL_SERVICE")
        local plot
        -- A river start can have no dry adjacent tile. Supply a second legal
        -- city beside naturally dry ground; retain the map's terrain/water.
        local function dryBare(p)
            return p and not p:IsWater() and not p:IsMountain() and not p:IsHills() and not p:IsFreshWater()
                and p:GetNumUnits()==0 and p:GetFeatureType()==-1 and p:GetResourceType(-1)==-1 and p:GetImprovementType()==-1
        end
        for i=0,Map.GetNumPlots()-1 do
            local p=Map.GetPlotByIndex(i)
            if p:GetOwner()==player:GetID() and dryBare(p)
                and p:CanBuild(build,player:GetID(),false,true) then plot,plotIndex=p,i;break end
        end
        if not plot then
            for i=0,Map.GetNumPlots()-1 do
                local site=Map.GetPlotByIndex(i)
                local distance=Map.PlotDistance(city:GetX(),city:GetY(),site:GetX(),site:GetY())
                if site:GetArea()==city:Plot():GetArea() and distance>=4 and distance<=10 and site:GetOwner()==-1
                    and site:GetNumUnits()==0 and player:CanFound(site:GetX(),site:GetY()) then
                    local chosen
                    for d=0,5 do local p=Map.PlotDirection(site:GetX(),site:GetY(),d)
                        if dryBare(p) and p:GetOwner()==-1 then chosen=p;break end
                    end
                    if chosen then
                        player:Found(site:GetX(),site:GetY())
                        LekmodScenarioEvent("fixture-setup",{operation="provided-legal-secondary-city",x=site:GetX(),y=site:GetY()})
                        assert(chosen:CanBuild(build,player:GetID(),false,true),"provided city's dry tile is not buildable")
                        plot,plotIndex=chosen,chosen:GetPlotIndex();break
                    end
                end
            end
        end
        assert(plot,"no naturally dry bare legal lake plot in this setup")
        for d=0,5 do local a=Map.PlotDirection(plot:GetX(),plot:GetY(),d)
            if a and not a:IsWater() and not a:IsMountain() and not a:IsFreshWater() then dry[#dry+1]={x=a:GetX(),y=a:GetY()} end
        end
        assert(#dry>0,"no dry neighbor to test freshwater gain")
        local unit=assert(player:InitUnit(GameInfoTypes.UNIT_WORKER,plot:GetX(),plot:GetY()));unitID=unit:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-worker",id=unitID,x=plot:GetX(),y=plot:GetY(),dry_neighbors=#dry})
        assert(unit:CanBuild(plot,build),"worker cannot build the chosen lake")
        assert(not unit:CanBuild(city:Plot(),build),"lake allowed on city")
        UI.SelectUnit(unit)
        local found=false
        for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="BUILD_BUGANDA_LAKE" then
            assert(Game.CanHandleAction(i),"normal lake build action unavailable");Game.HandleAction(i);found=true;break
        end end
        assert(found,"lake build action missing");issuedTurn=Game.GetGameTurn();phase="built";return "turn"
    elseif phase=="built" then
        local plot=Map.GetPlotByIndex(plotIndex)
        if plot:GetImprovementType()~=GameInfoTypes.IMPROVEMENT_BUGANDA_LAKE then
            assert(Game.GetGameTurn()-issuedTurn<=12,"lake did not complete in twelve turns");return "turn"
        end
        LekmodScenarioRecord("buganda-lake-build","PASS","path=normal-worker-build-action turns="..Game.GetGameTurn()-issuedTurn)
        LekmodScenarioEvent("lake-state",LekmodScenario.snapshot(player))
        assert(not plot:IsWater() and not plot:IsImprovementPillaged(),"completed lake is not intact land")
        for _,p in ipairs(dry) do assert(Map.GetPlot(p.x,p.y):IsFreshWater(),"lake failed to supply adjacent freshwater") end
        assert(plot:IsFreshWater(),"completed lake tile itself is not freshwater")
        LekmodScenarioRecord("buganda-lake-freshwater","PASS","own-tile-and-dry-neighbors=true")
        local unit=assert(player:GetUnitByID(unitID))
        assert(not unit:CanBuild(plot,GameInfoTypes.BUILD_FARM),"permanent lake can be replaced by a farm")
        assert(not unit:CanBuild(plot,build),"duplicate lake allowed")
        -- Units may pillage their owner's ordinary improvements, so this
        -- rejection does not depend on peace with a foreign owner.
        local attacker=assert(player:InitUnit(GameInfoTypes.UNIT_WARRIOR,plot:GetX(),plot:GetY()))
        LekmodScenarioEvent("fixture-setup",{operation="provided-own-unit-for-pillage-query",owner=player:GetID(),id=attacker:GetID()})
        assert(not attacker:CanPillage(plot),"permanent lake is pillageable")
        LekmodScenarioRecord("buganda-lake-restrictions","PASS","city-and-replacement-and-duplicate-and-pillage=rejected")
        return true
    end
    return false
end
