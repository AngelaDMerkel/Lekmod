-- Research, compatible resource plots and near-complete production are explicit
-- inputs. Actual construction must apply the Hacienda's plot bonuses/upkeep.
LekmodScenario={name="mexico-hacienda",items={"hacienda-construction","hacienda-resource-classes","hacienda-no-maintenance"}}
local phase,selected,before,maintenance,turn="init",nil,{},nil,nil
local building=GameInfoTypes.BUILDING_HACIENDA
local constructed=false
local classes={"RESOURCECLASS_BONUS","RESOURCECLASS_LUXURY","RESOURCECLASS_RUSH","RESOURCECLASS_MODERN"}
local extra={RESOURCECLASS_BONUS=YieldTypes.YIELD_GOLD,RESOURCECLASS_LUXURY=YieldTypes.YIELD_PRODUCTION,RESOURCECLASS_RUSH=YieldTypes.YIELD_FOOD,RESOURCECLASS_MODERN=YieldTypes.YIELD_FOOD}
local function yields(plot)
    local result={};for y in GameInfo.Yields() do result[y.ID]=plot:GetYield(y.ID) end;return result
end
GameEvents.CityConstructed.Add(function(owner,id,b,gold,faith)
    if owner==Game.GetActivePlayer() and b==building then
        assert(not gold and not faith,"Hacienda was purchased instead of built")
        constructed=true
        LekmodScenarioEvent("hacienda-native-construction",{owner=owner,city=id,building=b})
    end
end)
function LekmodScenario.snapshot(player)
    local city=assert(player:GetCapitalCity());local plots={}
    for index=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(index)
        if p:GetOwner()==player:GetID() and p:GetResourceType(-1)>=0 then
            plots[index]={resource=p:GetResourceType(-1),quantity=p:GetNumResource(),yields=yields(p)}
        end
    end
    return {turn=Game.GetGameTurn(),city=city:GetID(),hacienda=city:GetNumRealBuilding(building),maintenance=city:GetTotalBaseBuildingMaintenance(),plots=plots}
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity())
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MEXICO,"requires Mexico")
    if phase=="init" then
        assert(city:GetNumRealBuilding(building)==0,"fixture already has Hacienda")
        LekmodScenarioGrantTech(player,"TECH_ECONOMICS")
        phase="resources"
    elseif phase=="resources" then
        local options={}
        for _,class in ipairs(classes) do options[class]={} end
        for index=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(index)
            if p:GetOwner()==player:GetID() and not p:IsCity() and not p:IsWater() and not p:IsMountain()
                and p:GetFeatureType()~=GameInfoTypes.FEATURE_OASIS and p:GetFeatureType()~=GameInfoTypes.FEATURE_LAKE_VICTORIA then
                local old=p:GetResourceType(-1)
                for resource in GameInfo.Resources() do
                    local list=options[resource.ResourceClassType]
                    if list and resource.Type~="RESOURCE_ARTIFACTS" and resource.Type~="RESOURCE_HIDDEN_ARTIFACTS"
                        and (old==resource.ID or (old==-1 and p:CanHaveResource(resource.ID,1))) then
                        list[#list+1]={index=index,resource=resource.ID,class=resource.ResourceClassType,existing=old==resource.ID}
                    end
                end
            end
        end
        local choice,used={},{}
        local function choose(n)
            if n>#classes then return true end
            for _,row in ipairs(options[classes[n]]) do if not used[row.index] then
                used[row.index]=true;choice[n]=row
                if choose(n+1) then return true end
                used[row.index]=nil
            end end
            return false
        end
        local sizes={};for _,class in ipairs(classes)do sizes[class]=#options[class]end
        LekmodScenarioEvent("hacienda-resource-options",sizes)
        if #options.RESOURCECLASS_RUSH==0 then
            for index=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(index)
                local feature=plot:GetFeatureType()
                if plot:GetOwner()==player:GetID() and not plot:IsCity() and plot:GetResourceType(-1)==-1
                    and (feature==GameInfoTypes.FEATURE_FOREST or feature==GameInfoTypes.FEATURE_JUNGLE) then
                    plot:SetFeatureType(-1,-1)
                    LekmodScenarioEvent("fixture-setup",{operation="provided-cleared-resource-plot",plot=index,old_feature=feature})
                    return false
                end
            end
        end
        assert(choose(1),"no four distinct compatible owned resource plots")
        selected=choice
        for _,row in ipairs(selected) do
            local p=Map.GetPlotByIndex(row.index);local info=GameInfo.Resources[row.resource]
            if not row.existing then p:SetResourceType(row.resource,1) end
            LekmodScenarioEvent("fixture-setup",{operation=row.existing and "existing-resource" or "provided-compatible-resource",plot=row.index,resource=info.Type,class=row.class})
            if info.TechReveal then LekmodScenarioGrantTech(player,info.TechReveal) end
        end
        phase="order"
    elseif phase=="order" then
        for _,row in ipairs(selected) do
            local p=Map.GetPlotByIndex(row.index)
            assert(p:GetResourceType(player:GetTeam())==row.resource,"resource is not revealed to the owner")
            before[row.index]=yields(p)
        end
        assert(city:CanConstruct(building),"Hacienda construction unavailable")
        assert(not city:CanConstruct(GameInfoTypes.BUILDING_WINDMILL),"Mexico may build the replaced Windmill")
        maintenance=city:GetTotalBaseBuildingMaintenance()
        Game.CityPushOrder(city,OrderTypes.ORDER_CONSTRUCT,building,false,true,true)
        phase="queued"
    elseif phase=="queued" then
        if not LekmodScenarioAwait("hacienda-order",city:GetProductionBuilding()==building) then return false end
        local cost=city:GetBuildingProductionNeeded(building)
        city:SetBuildingProduction(building,cost-1)
        LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-Hacienda-production",production=cost-1,needed=cost})
        turn=Game.GetGameTurn();phase="built";return "turn"
    elseif phase=="built" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Game.GetGameTurn()==turn+1 and constructed and city:GetNumRealBuilding(building)==1,"normal turn did not construct exactly one Hacienda")
        LekmodScenarioRecord("hacienda-construction","PASS","path=normal-production-order-and-CityConstructed base-Windmill-rejected=true")
        for _,row in ipairs(selected) do
            local after=yields(Map.GetPlotByIndex(row.index))
            LekmodScenarioEvent("hacienda-resource-yields",{class=row.class,plot=row.index,before=before[row.index],after=after})
            for y,value in pairs(before[row.index]) do assert(after[y]==value+(y==extra[row.class] and 1 or 0),"Hacienda resource class yield differs: "..row.class.." yield="..y) end
        end
        LekmodScenarioRecord("hacienda-resource-classes","PASS","bonus-gold=1 luxury-production=1 rush-food=1 modern-food=1 other-plot-yields=unchanged")
        assert(city:GetTotalBaseBuildingMaintenance()==maintenance,"Hacienda increased base maintenance")
        LekmodScenarioRecord("hacienda-no-maintenance","PASS","native-city-maintenance-unchanged=true")
        return true
    end
    return false
end
