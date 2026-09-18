-- Supplied great people build on naturally eligible owned plots. Improvement,
-- yield, territory and unit-consumption outcomes are never assigned.
LekmodScenario={name="great-person-builds",items={"academy","manufactory","customs-house","holy-site","citadel","great-person-build-restrictions","spent-prophet-build-rejection"}}
local cases={
 {name="academy",unit="UNIT_SCIENTIST",build="BUILD_ACADEMY"},
 {name="manufactory",unit="UNIT_ENGINEER",build="BUILD_MANUFACTORY"},
 {name="customs-house",unit="UNIT_MERCHANT",build="BUILD_CUSTOMS_HOUSE"},
 {name="holy-site",unit="UNIT_PROPHET",build="BUILD_HOLY_SITE"},
 {name="citadel",unit="UNIT_GREAT_GENERAL",build="BUILD_CITADEL"}}
local yields={YieldTypes.YIELD_FOOD,YieldTypes.YIELD_PRODUCTION,YieldTypes.YIELD_GOLD,YieldTypes.YIELD_SCIENCE,YieldTypes.YIELD_CULTURE,YieldTypes.YIELD_FAITH}
local phase,index,plotID,unitID,quote,resource,route,neighbors="prepare",1
local finished,used={},{ }
GameEvents.BuildFinished.Add(function(owner,x,y,improvement)
    if owner==Game.GetActivePlayer() then finished[x..":"..y]=improvement end
end)
local function yieldState(p)
    local result={};for _,id in ipairs(yields) do result[id]=p:CalculateYield(id,false) end;return result
end
function LekmodScenario.snapshot(player)
    local plots,units={},{};local kinds={}
    for _,case in ipairs(cases) do kinds[GameInfoTypes[GameInfo.Builds[case.build].ImprovementType]]=true end
    for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
        if p:GetOwner()==player:GetID() and kinds[p:GetImprovementType()] then
            local adjacent={};for d=0,5 do local a=Map.PlotDirection(p:GetX(),p:GetY(),d);if a then adjacent[a:GetPlotIndex()]=a:GetOwner() end end
            plots[i]={improvement=p:GetImprovementType(),owner=p:GetOwner(),resource=p:GetResourceType(-1),route=p:GetRouteType(),pillaged=p:IsImprovementPillaged(),yields=yieldState(p),neighbors=adjacent}
        end
    end
    for u in player:Units() do if not u:IsDead() and not u:IsDelayedDeath() then units[u:GetID()]={type=u:GetUnitType(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),x=u:GetX(),y=u:GetY()} end end
    return {turn=Game.GetGameTurn(),plots=plots,units=units}
end
function LekmodScenario.step(player)
    local case=cases[index];local build=GameInfoTypes[case.build]
    local improvement=GameInfoTypes[GameInfo.Builds[case.build].ImprovementType]
    if phase=="prepare" then
        local plot,best=nil,-1
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if not used[i] and p:GetOwner()==player:GetID() and not p:IsCity() and not p:IsWater() and not p:IsMountain()
                and p:GetFeatureType()==-1 and p:GetImprovementType()==-1 and p:GetNumUnits()==0 and p:CanBuild(build,player:GetID(),false,true) then
                local neutral=0
                for d=0,5 do local a=Map.PlotDirection(p:GetX(),p:GetY(),d);if a and a:GetOwner()==-1 then neutral=neutral+1 end end
                if case.name~="citadel" or neutral>best then plot=p;best=neutral end
                if case.name~="citadel" then break end
            end
        end
        assert(plot and (case.name~="citadel" or best>0),"fixture lacks an eligible owned plot for "..case.name)
        plotID=plot:GetPlotIndex();used[plotID]=true
        if case.name=="holy-site" then
            local spent
            for u in player:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_PROPHET and u:GetReligion()>0 and u:GetSpreadsLeft()<GameInfo.Units.UNIT_PROPHET.ReligionSpreads then spent=u;break end end
            assert(spent,"load the saved reconversion fixture with an actually spent prophet")
            assert(not spent:CanBuild(plot,build),"a prophet that already spread religion may still build a Holy Site")
            LekmodScenarioRecord("spent-prophet-build-rejection","PASS","native-eligibility after-actual-saved-spread=true")
        end
        local origin=case.name=="holy-site" and player:GetCapitalCity():Plot() or plot
        local u=assert(player:InitUnit(GameInfoTypes[case.unit],origin:GetX(),origin:GetY()));unitID=u:GetID()
        if case.name=="holy-site" then
            assert(u:GetReligion()==player:GetReligionCreatedByPlayer() and u:GetSpreadsLeft()==GameInfo.Units.UNIT_PROPHET.ReligionSpreads,"city-born prophet did not inherit the full founder-religion charges")
            u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
        end
        LekmodScenarioEvent("fixture-setup",{operation="provided-great-person",kind=case.unit,unit=unitID,x=u:GetX(),y=u:GetY(),spreads=u:GetSpreadsLeft(),religion=u:GetReligion()})
        assert(u:CanBuild(plot,build),"supplied great person cannot build its eligible improvement")
        assert(not u:CanBuild(player:GetCapitalCity():Plot(),build),"great-person improvement allowed on a city")
        local water
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);if p:IsWater() then water=p;break end end
        assert(water and not u:CanBuild(water,build),"land great-person improvement allowed on water")
        quote={};for _,id in ipairs(yields) do quote[id]=plot:GetYieldWithBuild(build,id,false,player:GetID()) end
        resource=plot:GetResourceType(-1);route=plot:GetRouteType();neighbors={}
        for d=0,5 do local a=Map.PlotDirection(plot:GetX(),plot:GetY(),d);if a then neighbors[a:GetPlotIndex()]=a:GetOwner() end end
        LekmodScenarioEvent("great-person-build-before",{case=case.name,plot=plotID,yields=yieldState(plot),quoted=quote,neighbors=neighbors,resource=resource,route=route})
        UI.SelectUnit(u);local action
        for id=0,#GameInfoActions do if GameInfoActions[id] and GameInfoActions[id].Type==case.build then action=id;break end end
        assert(action and Game.CanHandleAction(action),"normal improvement action unavailable")
        Game.HandleAction(action);phase="result"
    else
        local p=Map.GetPlotByIndex(plotID);local u=player:GetUnitByID(unitID)
        if not LekmodScenarioAwait(case.name.."-complete",p:GetImprovementType()==improvement and (not u or u:IsDead() or u:IsDelayedDeath())) then return false end
        assert(finished[p:GetX()..":"..p:GetY()]==improvement,"real BuildFinished event missing")
        assert(p:GetResourceType(-1)==resource and p:GetRouteType()==route and not p:IsImprovementPillaged(),"build changed underlying resource/road or produced a pillaged improvement")
        local actual=yieldState(p)
        for _,id in ipairs(yields) do assert(actual[id]==quote[id],"completed yield differs from build quote: "..case.name.." yield="..id.." actual="..actual[id].." quoted="..quote[id]) end
        assert(not p:CanBuild(build,player:GetID(),false,true),"duplicate great-person improvement remains eligible")
        local annexed=0
        if case.name=="citadel" then
            for id,owner in pairs(neighbors) do if owner==-1 and Map.GetPlotByIndex(id):GetOwner()==player:GetID() then annexed=annexed+1 end end
            assert(annexed>0,"normal Citadel build claimed no adjacent neutral territory")
        end
        LekmodScenarioEvent("great-person-build-after",{case=case.name,plot=plotID,yields=actual,neutral_tiles_claimed=annexed})
        LekmodScenarioRecord(case.name,"PASS","path=normal-build-action real-completion=true great-person-consumed=true yields-match-quote=true")
        index=index+1
        if index>#cases then
            LekmodScenarioRecord("great-person-build-restrictions","PASS","city/water/duplicate=rejected all-five-actions=true resource-and-route-retained=true")
            return true
        end
        phase="prepare"
    end
    return false
end
