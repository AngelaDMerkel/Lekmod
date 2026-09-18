-- Supplied Settlers and ruin-free legal positions; normal Found actions must
-- award only the first two expansions. Capital and other-owner controls are normal.
LekmodScenario={name="philippines-founding",items={"philippines-capital","philippines-first-two","philippines-third-excluded","philippines-other-owner"}}
local phase,site,unitID,ordinal,turn="init",nil,nil,0,nil
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

function LekmodScenario.snapshot(player)
    local result={turn=Game.GetGameTurn(),players={}}
    for id=0,1 do local p=Players[id];local cities={}
        for c in p:Cities() do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),dummy=c:GetNumRealBuilding(dummy),capital=c:IsCapital()} end
        result.players[id]={civ=p:GetCivilizationType(),cities=cities,dummies=p:CountNumBuildings(dummy)}
    end
    return result
end
function LekmodScenario.step(player)
    local capital=player:GetCapitalCity();if not capital then return "turn" end
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PHILIPPINES and Players[1]:GetCivilizationType()~=GameInfoTypes.CIVILIZATION_PHILIPPINES,"requires normal Philippines and other-civilization setup")
    if phase=="init" then
        assert(capital:GetNumRealBuilding(dummy)==0 and capital:GetPopulation()==1,"capital received expansion bonus")
        LekmodScenarioRecord("philippines-capital","PASS","normal-capital population=1 dummy=0")
        phase="found"
    elseif phase=="found" then
        ordinal=ordinal+1;site,unitID=stage(player);phase="observe"
    elseif phase=="observe" then
        local city=site:GetPlotCity()
        if not LekmodScenarioAwait("philippines-city-"..ordinal,city and city:GetOwner()==player:GetID()) then return false end
        local unit=player:GetUnitByID(unitID);assert(not unit or unit:IsDead() or unit:IsDelayedDeath(),"Found did not consume Settler")
        local expected=ordinal<=2 and 1 or 0
        LekmodScenarioEvent("philippines-expansion",{ordinal=ordinal,city=city:GetID(),population=city:GetPopulation(),dummy=city:GetNumRealBuilding(dummy),owned_dummies=player:CountNumBuildings(dummy)})
        assert(city:GetNumRealBuilding(dummy)==expected and city:GetPopulation()==1+expected,"expansion population/marker differs from first-two rule")
        if player.GetNumCitiesFounded then assert(player:GetNumCitiesFounded()==ordinal+1,"lifetime founding history differs from normal actions") end
        if ordinal<3 then phase="found" else
            assert(player:CountNumBuildings(dummy)==2,"quota has wrong number of awarded cities")
            LekmodScenarioRecord("philippines-first-two","PASS","normal-Found population=2 dummy=1 each-of-first-two=true")
            LekmodScenarioRecord("philippines-third-excluded","PASS","normal-Found third-expansion population=1 dummy=0")
            turn=Game.GetGameTurn();phase="other";return "turn"
        end
    elseif phase=="other" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Game.GetGameTurn()==turn+1,"other-owner founding exceeded one ordinary turn")
        local other=assert(Players[1]:GetCapitalCity())
        assert(other:GetNumRealBuilding(dummy)==0 and Players[1]:CountNumBuildings(dummy)==0,"other civilization received Philippine marker")
        LekmodScenarioRecord("philippines-other-owner","PASS","normal-other-AI-founding dummy=0")
        return true
    end
    return false
end
