-- Load the actual four-city Philippines baseline. A supplied AI attacker uses
-- normal war/move-attack commands; city loss and the later founding are outcomes.
LekmodScenario={name="philippines-loss",items={"philippines-real-city-loss","philippines-lifetime-quota"}}
local phase,x,y,sent,captured,site,unitID="init",nil,nil,false,false,nil,nil
local dummy=GameInfoTypes.BUILDING_PHILIPPINES_TRAIT
local function stage(player)
    local capital=assert(player:GetCapitalCity());local best,plot=999,nil
    local ruins={}
    for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);if p:IsGoody(-1) then ruins[#ruins+1]=p end end
    for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
        local safe=true
        for _,ruin in ipairs(ruins) do if Map.PlotDistance(p:GetX(),p:GetY(),ruin:GetX(),ruin:GetY())<=2 then safe=false;break end end
        local distance=Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())
        if safe and distance>=4 and distance<=10 and distance<best and p:GetArea()==capital:Plot():GetArea()
            and p:GetOwner()==-1 and p:GetNumUnits()==0 and p:GetImprovementType()==-1
            and player:CanFound(p:GetX(),p:GetY()) then plot,best=p,distance end
    end
    assert(plot,"no legal additional-city site")
    local unit=assert(player:InitUnit(GameInfoTypes.UNIT_SETTLER,plot:GetX(),plot:GetY()))
    LekmodScenarioEvent("fixture-setup",{operation="provided-settler-and-staging",unit=unit:GetID(),x=plot:GetX(),y=plot:GetY(),nearby_ruins_excluded=true})
    assert(unit:CanFound(plot));UI.SelectUnit(unit)
    for id=0,#GameInfoActions do if GameInfoActions[id] and GameInfoActions[id].Type=="MISSION_FOUND" then
        assert(Game.CanHandleAction(id));Game.HandleAction(id);return plot,unit:GetID()
    end end
    error("normal Found action missing")
end

GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,population,conquest)
    if old==0 and new==1 and cx==x and cy==y then
        assert(not capital and conquest and sent,"city transfer did not follow the supplied attack")
        captured=true
        LekmodScenarioEvent("philippines-native-capture",{old=old,new=new,x=cx,y=cy,population=population,conquest=conquest})
    end
end)
GameEvents.PlayerDoTurn.Add(function(id)
    if id~=1 or phase~="capture" or sent then return end
    local enemy=Players[1];assert(enemy:IsTurnActive(),"AI attack must occur on its own turn")
    local target=assert(Map.GetPlot(x,y):GetPlotCity());local staging
    for direction=0,5 do local p=Map.PlotDirection(x,y,direction)
        if p and not p:IsCity() and not p:IsWater() and not p:IsMountain() and p:GetNumUnits()==0 then staging=p;break end
    end
    assert(staging,"no legal adjacent attack staging plot")
    enemy:ChangeGold(1000);enemy:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
    local unit=assert(enemy:InitUnit(GameInfoTypes.UNIT_MECH,staging:GetX(),staging:GetY()))
    LekmodScenarioEvent("fixture-setup",{operation="provided-AI-attacker-uranium-and-upkeep",unit=unit:GetID(),x=staging:GetX(),y=staging:GetY(),uranium=1,gold_added=1000})
    assert(unit:CanMoveOrAttackInto(target:Plot()),"AI capture move is not legal")
    sent=true;unit:PushMission(MissionTypes.MISSION_MOVE_TO,x,y,0,0,1)
end)
function LekmodScenario.snapshot(player)
    local result={turn=Game.GetGameTurn(),war=Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam()),players={}}
    for id=0,1 do local p=Players[id];local cities={}
        for c in p:Cities() do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),dummy=c:GetNumRealBuilding(dummy),capital=c:IsCapital(),original_owner=c:GetOriginalOwner()} end
        result.players[id]={civ=p:GetCivilizationType(),cities=cities,dummies=p:CountNumBuildings(dummy)}
    end
    if player.GetNumCitiesFounded then
        LekmodScenarioEvent("philippines-founding-history",{human=player:GetNumCitiesFounded(),AI=Players[1]:GetNumCitiesFounded(),human_owned=player:GetNumCities(),AI_owned=Players[1]:GetNumCities()})
    end
    return result
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PHILIPPINES,"requires Philippines")
    if phase=="init" then
        assert(player:GetNumCities()==4 and player:CountNumBuildings(dummy)==2,"load the first-three-expansions baseline")
        assert(player.GetNumCitiesFounded and player:GetNumCitiesFounded()==4 and Players[1]:GetNumCitiesFounded()==1,"matching lifetime-history binding or old-save values missing")
        local target
        for c in player:Cities() do if not c:IsCapital() and c:GetNumRealBuilding(dummy)>0 and (not target or c:GetID()<target:GetID()) then target=c end end
        assert(target);x,y=target:GetX(),target:GetY()
        Teams[player:GetTeam()]:Meet(Players[1]:GetTeam(),true)
        Network.SendChangeWar(Players[1]:GetTeam(),true);phase="war"
    elseif phase=="war" then
        if not LekmodScenarioAwait("philippines-war",Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam())) then return false end
        phase="capture";return "turn"
    elseif phase=="capture" then
        if not captured then return "turn" end
        assert(player:GetNumCities()==3 and player:CountNumBuildings(dummy)==1,"real city loss did not remove one awarded city's marker")
        assert(player:GetNumCitiesFounded()==4 and Players[1]:GetNumCitiesFounded()==1,"capture changed lifetime founding history")
        LekmodScenarioEvent("philippines-history-after-capture",{human_founded=player:GetNumCitiesFounded(),human_owned=player:GetNumCities(),AI_founded=Players[1]:GetNumCitiesFounded(),AI_owned=Players[1]:GetNumCities()})
        LekmodScenarioRecord("philippines-real-city-loss","PASS","path=normal-AI-move-attack-and-CityCaptureComplete awarded-city-lost=true")
        site,unitID=stage(player);phase="later-city"
    elseif phase=="later-city" then
        local city=site:GetPlotCity()
        if not LekmodScenarioAwait("philippines-fourth-expansion",city and city:GetOwner()==player:GetID()) then return false end
        local unit=player:GetUnitByID(unitID);assert(not unit or unit:IsDead() or unit:IsDelayedDeath(),"normal founding did not consume supplied Settler")
        assert(player:GetNumCitiesFounded()==5,"later founding did not increment lifetime history exactly once")
        local count=city:GetNumRealBuilding(dummy)
        LekmodScenarioEvent("philippines-later-expansion",{city=city:GetID(),population=city:GetPopulation(),dummy=count,owned_dummies=player:CountNumBuildings(dummy)})
        LekmodScenarioRecord("philippines-lifetime-quota",count==0 and city:GetPopulation()==1 and "PASS" or "FAIL","fourth-expansion-after-city-loss expected-dummy=0 actual="..count.." population="..city:GetPopulation())
        return true
    end
    return false
end
