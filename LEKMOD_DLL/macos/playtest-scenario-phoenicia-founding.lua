-- Starting civilizations and founding actions are normal. Two additional
-- settlers/staging locations and technology prerequisites are supplied inputs.
LekmodScenario={name="phoenicia-founding",items={"phoenicia-before-Optics","phoenicia-after-Optics","phoenicia-existing-city","phoenicia-AI-owner","phoenicia-other-owner"}}
local phase,site,settler,oldGold,earlyCity,earlyPopulation,turn="init"
local dummy=GameInfoTypes.BUILDING_PHOENICIAN_TRAIT
GameEvents.SetPopulation.Add(function(x,y,old,new)
    local plot=Map.GetPlot(x,y);local city=plot and plot:GetPlotCity()
    LekmodScenarioEvent("phoenicia-population-event",{turn=Game.GetGameTurn(),x=x,y=y,old=old,new=new,owner=city and city:GetOwner() or -1,dummy=city and city:GetNumRealBuilding(dummy) or -1,observed=city and city:GetPopulation() or -1})
end)
GameEvents.PlayerCityFounded.Add(function(owner,x,y)
    local city=Map.GetPlot(x,y):GetPlotCity()
    LekmodScenarioEvent("phoenicia-found-event",{turn=Game.GetGameTurn(),owner=owner,city=city:GetID(),population=city:GetPopulation(),food100=city:GetFoodTimes100(),dummy=city:GetNumRealBuilding(dummy)})
end)

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
    for id=0,2 do local p=Players[id];local cities={}
        for c in p:Cities() do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),dummy=c:GetNumRealBuilding(dummy),capital=c:IsCapital()} end
        result.players[id]={civ=p:GetCivilizationType(),gold=p:GetGold(),optics=Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_OPTICS),cities=cities}
    end
    return result
end
function LekmodScenario.step(player)
    local capital=player:GetCapitalCity();if not capital then return "turn" end
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PHOENICIAN and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PHOENICIAN,"requires human and AI Phoenicia")
    assert(Players[2]:IsAlive() and Players[2]:GetCivilizationType()~=GameInfoTypes.CIVILIZATION_PHOENICIAN,"requires a normally selected non-Phoenician third major")
    if phase=="init" then
        assert(not Teams[player:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_OPTICS),"start before Optics")
        assert(capital:GetNumRealBuilding(dummy)==0 and capital:GetPopulation()==1,"pre-Optics capital received a bonus")
        oldGold=player:GetGold();site,settler=stage(player);phase="early-city"
    elseif phase=="early-city" then
        local city=site:GetPlotCity()
        if not LekmodScenarioAwait("early-colony",city and city:GetOwner()==player:GetID()) then return false end
        LekmodScenarioEvent("phoenicia-before-Optics-outcome",{city=city:GetID(),population=city:GetPopulation(),dummy=city:GetNumRealBuilding(dummy),initial_population=GameDefines.INITIAL_CITY_POPULATION,new_city_extra=player:GetNewCityExtraPopulation(),gold_before=oldGold,gold=player:GetGold(),team_has=Teams[player:GetTeam()]:IsHasTech(GameInfoTypes.TECH_OPTICS),techs_has=Teams[player:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_OPTICS)})
        assert(city:GetNumRealBuilding(dummy)==0 and player:GetGold()==oldGold,"pre-Optics colony received population/gold")
        earlyCity=city:GetID();earlyPopulation=city:GetPopulation()
        LekmodScenarioRecord("phoenicia-before-Optics","PASS","capital-and-expansion dummy=0 gold-unchanged=true expansion-baseline-population="..earlyPopulation)
        for id=0,2 do LekmodScenarioGrantTech(Players[id],"TECH_OPTICS") end
        phase="late-order"
    elseif phase=="late-order" then
        assert(capital:GetNumRealBuilding(dummy)==0 and player:GetCityByID(earlyCity):GetNumRealBuilding(dummy)==0,"Optics retroactively awarded existing cities")
        LekmodScenarioRecord("phoenicia-existing-city","PASS","Optics-does-not-retroactively-award=true")
        oldGold=player:GetGold();site,settler=stage(player);phase="late-city"
    elseif phase=="late-city" then
        local city=site:GetPlotCity()
        if not LekmodScenarioAwait("late-colony",city and city:GetOwner()==player:GetID()) then return false end
        local unit=player:GetUnitByID(settler)
        assert(not unit or unit:IsDead() or unit:IsDelayedDeath(),"normal founding did not consume Settler")
        LekmodScenarioEvent("phoenicia-new-city",{city=city:GetID(),population=city:GetPopulation(),dummy=city:GetNumRealBuilding(dummy),gold_before=oldGold,gold=player:GetGold()})
        local passed=city:GetNumRealBuilding(dummy)==1 and city:GetPopulation()==earlyPopulation+1 and player:GetGold()==oldGold+50
        LekmodScenarioRecord("phoenicia-after-Optics",passed and "PASS" or "FAIL","path=normal-Found expected-population="..(earlyPopulation+1).." actual="..city:GetPopulation().." gold-added="..(player:GetGold()-oldGold).." dummy="..city:GetNumRealBuilding(dummy))
        turn=Game.GetGameTurn();phase="AI";return "turn"
    elseif phase=="AI" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Game.GetGameTurn()==turn+1,"AI founding check exceeded one ordinary turn")
        local same=assert(Players[1]:GetCapitalCity());local other=assert(Players[2]:GetCapitalCity())
        LekmodScenarioEvent("phoenicia-owner-outcomes",LekmodScenario.snapshot(player))
        assert(same:GetNumRealBuilding(dummy)==1 and same:GetPopulation()==2,"AI Phoenician city did not receive the founding population")
        assert(other:GetNumRealBuilding(dummy)==0,"other civilization received Phoenician dummy")
        LekmodScenarioRecord("phoenicia-AI-owner","PASS","normal-AI-founding with-Optics=true population=2 dummy=1")
        LekmodScenarioRecord("phoenicia-other-owner","PASS","other-civilization-with-Optics dummy=0")
        return true
    end
    return false
end
