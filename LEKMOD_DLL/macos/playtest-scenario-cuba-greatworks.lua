-- Cuba's music-holding building bonus must follow the real work location.
-- City/population/buildings/Musician are supplied, the work and moves are not.
LekmodScenario={name="cuba-greatworks",items={"cuba-music-bonus","cuba-music-removal","cuba-music-return","cuba-occupied-swap"}}
local phase,other,unitID,work,baseline,localBefore,closed,wait="init",nil,nil,nil,nil,nil,false,0
local otherWork
local defects={}
local function check(value,message)
    if not value then
        defects[#defects+1]=message
        LekmodScenarioEvent("cuba-greatwork-defect",{message=message})
    end
    return value
end
local hall,tower=GameInfoTypes.BUILDINGCLASS_OPERA_HOUSE,GameInfoTypes.BUILDINGCLASS_BROADCAST_TOWER
LuaEvents.LekmodCultureGreatWorkClosed.Add(function() closed=true end)
function LekmodScenario.snapshot(player)
    local cities={}
    for c in player:Cities() do cities[c:GetID()]={population=c:GetPopulation(),local_happiness=c:GetLocalHappiness(),works=c:GetNumGreatWorks(),
        music_hall=c:GetBuildingGreatWork(hall,0),music_tower=c:GetBuildingGreatWork(tower,0),culture=c:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE),tourism=c:GetBaseTourism()} end
    return {turn=Game.GetGameTurn(),cities=cities,happiness=player:GetExcessHappiness(),works=player:GetNumGreatWorks()}
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_CUBA,"choose Cuba")
    local city=player:GetCapitalCity();if not city then return "turn" end
    if phase=="init" then
        assert(player:GetNumGreatWorks()==0,"fixture already has a work")
        local site
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())
            if distance>=4 and distance<=8 and p:GetArea()==city:Plot():GetArea() and p:GetOwner()==-1 and p:GetNumUnits()==0 and player:CanFound(p:GetX(),p:GetY()) then site=p;break end
        end
        assert(site,"no legal second-city input")
        player:Found(site:GetX(),site:GetY());other=site:GetPlotCity():GetID()
        local target=player:GetCityByID(other)
        if city:GetNumBuilding(GameInfoTypes.BUILDING_DANCE_HALL)==0 then city:SetNumRealBuilding(GameInfoTypes.BUILDING_DANCE_HALL,1) end
        if target:GetNumBuilding(GameInfoTypes.BUILDING_BROADCAST_TOWER)==0 then target:SetNumRealBuilding(GameInfoTypes.BUILDING_BROADCAST_TOWER,1) end
        city:SetPopulation(20,true);target:SetPopulation(20,true)
        LekmodScenarioEvent("fixture-setup",{operation="provided-city-and-holding-buildings-and-populations",second_city=other,dance_hall=city:GetID(),broadcast_tower=other,population_each=20})
        assert(city:GetNumBuilding(GameInfoTypes.BUILDING_DANCE_HALL)==1,"duplicate dance halls in fixture")
        baseline=player:GetExcessHappiness();localBefore=city:GetLocalHappiness()
        assert(localBefore<20,"local happiness is already capped")
        local u=assert(player:InitUnit(GameInfoTypes.UNIT_MUSICIAN,city:GetX(),city:GetY()));unitID=u:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-musician",id=unitID})
        phase="create"
    elseif phase=="create" or phase=="second-create" then
        UI.SelectUnit(assert(player:GetUnitByID(unitID)))
        local found=false
        for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_CREATE_GREAT_WORK" then
            assert(Game.CanHandleAction(i),"normal music creation unavailable");Game.HandleAction(i);found=true;break
        end end
        assert(found,"great-work action missing");phase=phase=="create" and "created" or "second-created"
    elseif phase=="created" then
        if not LekmodScenarioAwait("music-created",player:GetNumGreatWorks()==1) then return false end
        work=city:GetBuildingGreatWork(hall,0);assert(work>=0,"music was not placed in the Dance Hall")
        local u=player:GetUnitByID(unitID);assert(not u or u:IsDead() or u:IsDelayedDeath(),"musician not consumed")
        assert(city:GetLocalHappiness()==localBefore+1 and player:GetExcessHappiness()==baseline+1,"Dance Hall did not add exactly one happiness")
        local culture=city:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE)
        if check(culture==6,"Dance Hall music culture="..culture..", expected=6") then
            LekmodScenarioRecord("cuba-music-bonus","PASS","path=normal-Music-action happiness=1 culture=6")
        end
        phase="panel"
    elseif phase=="panel" then
        wait=wait+1;if wait<8 then return false end
        if not closed then LuaEvents.LekmodCultureCloseGreatWork();return false end
        Network.SendMoveGreatWorks(player:GetID(),city:GetID(),hall,0,other,tower,0);phase="removed"
    elseif phase=="removed" then
        local target=player:GetCityByID(other)
        if not LekmodScenarioAwait("music-removed",city:GetBuildingGreatWork(hall,0)==-1 and target:GetBuildingGreatWork(tower,0)==work) then return false end
        LekmodScenarioEvent("music-removal-state",{before_happiness=baseline,happiness=player:GetExcessHappiness(),before_local=localBefore,local_happiness=city:GetLocalHappiness(),culture_source=city:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE),culture_target=target:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE)})
        local happy=check(city:GetLocalHappiness()==localBefore and player:GetExcessHappiness()==baseline,"empty Dance Hall retained its music happiness")
        local culture=check(city:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE)==0 and target:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE)==2,"music building-specific culture did not follow its destination")
        if happy and culture then LekmodScenarioRecord("cuba-music-removal","PASS","path=normal-cross-city-move happiness-removed=1 culture=0-and-2") end
        Network.SendMoveGreatWorks(player:GetID(),other,tower,0,city:GetID(),hall,0);phase="returned"
    elseif phase=="returned" then
        if not LekmodScenarioAwait("music-returned",city:GetBuildingGreatWork(hall,0)==work) then return false end
        if check(city:GetLocalHappiness()==localBefore+1 and player:GetExcessHappiness()==baseline+1 and city:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE)==6,"returning music did not restore Dance Hall benefits") then
            LekmodScenarioRecord("cuba-music-return","PASS","path=normal-cross-city-move happiness-restored=1 culture=6")
        end
        assert(#defects==0,table.concat(defects,"; "))
        local target=player:GetCityByID(other)
        local u=assert(player:InitUnit(GameInfoTypes.UNIT_MUSICIAN,target:GetX(),target:GetY()));unitID=u:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-second-musician-for-occupied-swap",id=unitID,city=other})
        closed,wait=false,0;phase="second-create"
    elseif phase=="second-created" then
        if not LekmodScenarioAwait("second-music",player:GetNumGreatWorks()==2) then return false end
        local target=player:GetCityByID(other)
        otherWork=target:GetBuildingGreatWork(hall,0)
        if otherWork<0 then otherWork=target:GetBuildingGreatWork(tower,0) end
        assert(otherWork>=0 and otherWork~=work,"new music is not in the second city")
        phase="second-panel"
    elseif phase=="second-panel" then
        wait=wait+1;if wait<8 then return false end
        if not closed then LuaEvents.LekmodCultureCloseGreatWork();return false end
        local target=player:GetCityByID(other)
        if target:GetBuildingGreatWork(tower,0)~=otherWork then Network.SendMoveGreatWorks(player:GetID(),other,hall,0,other,tower,0) end
        phase="swap-ready"
    elseif phase=="swap-ready" then
        local target=player:GetCityByID(other)
        if not LekmodScenarioAwait("occupied-swap-prepared",target:GetBuildingGreatWork(tower,0)==otherWork) then return false end
        assert(city:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE)==6 and target:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE)==2,"occupied swap lacks distinct building yield inputs")
        Network.SendMoveGreatWorks(player:GetID(),other,tower,0,city:GetID(),hall,0);phase="occupied-swapped"
    elseif phase=="occupied-swapped" then
        local target=player:GetCityByID(other)
        if not LekmodScenarioAwait("occupied-swapped",city:GetBuildingGreatWork(hall,0)==otherWork and target:GetBuildingGreatWork(tower,0)==work) then return false end
        local capCulture=city:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE)
        local targetCulture=target:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_CULTURE)
        LekmodScenarioEvent("occupied-music-swap",{capital_culture=capCulture,other_culture=targetCulture,happiness=player:GetExcessHappiness(),expected_happiness=baseline+1})
        assert(capCulture==6 and targetCulture==2 and player:GetExcessHappiness()==baseline+1,"occupied swap retained a former building's great-work benefits")
        assert(string.find(Game.GetGreatWorkTooltip(otherWork,player:GetID()),"+6 [ICON_CULTURE]",1,true),"Dance Hall tooltip does not reflect its current culture")
        assert(string.find(Game.GetGreatWorkTooltip(work,player:GetID()),"+2 [ICON_CULTURE]",1,true),"Broadcast Tower tooltip retained the Dance Hall's culture")
        LekmodScenarioRecord("cuba-occupied-swap","PASS","path=normal-occupied-cross-city-swap culture=6-and-2 happiness=1")
        return true
    end
    return false
end
