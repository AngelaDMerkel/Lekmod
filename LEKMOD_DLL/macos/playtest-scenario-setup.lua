-- Normal single-player setup only: no supplied cities, units, yields or turns.
LekmodScenario={name="setup",items={"setup-configuration","setup-options","setup-two-human-turns"}}
local started,researchBefore
local optionNames={"GAMEOPTION_NO_BARBARIANS","GAMEOPTION_RAGING_BARBARIANS","GAMEOPTION_NO_SCIENCE","GAMEOPTION_NO_POLICIES","GAMEOPTION_NO_RELIGION","GAMEOPTION_NO_ESPIONAGE","GAMEOPTION_ONE_CITY_CHALLENGE","GAMEOPTION_NO_CITY_RAZING"}
local function roster()
    local majors,minors=0,0
    for id=0,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id]
        if p and p:IsAlive() and not p:IsBarbarian() then
            if p:IsMinorCiv() then minors=minors+1 else majors=majors+1 end
        end
    end
    return majors,minors
end
local function scienceState(player)
    local result={};local techs=Teams[player:GetTeam()]:GetTeamTechs()
    for t in GameInfo.Technologies() do result[t.ID]={known=techs:HasTech(t.ID),count=techs:GetTechCount(t.ID),progress100=techs:GetResearchProgressTimes100(t.ID)} end
    return {technologies=result,overflow=player:GetOverflowResearch()}
end
function LekmodScenario.snapshot(player)
    local options,cities,units={},{},{}
    for _,name in ipairs(optionNames) do options[name]=Game.IsOption(name) end
    for c in player:Cities() do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),food=c:GetFoodTimes100(),production=c:GetProductionTimes100(),unit=c:GetProductionUnit(),building=c:GetProductionBuilding()} end
    for u in player:Units() do if not u:IsDelayedDeath() then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage()} end end
    local width,height=Map.GetGridSize();local majors,minors=roster()
    return {turn=Game.GetGameTurn(),elapsed=Game.GetElapsedGameTurns(),speed=Game.GetGameSpeedType(),handicap=player:GetHandicapType(),game_handicap=Game.GetHandicapType(),era=Game.GetStartEra(),world=Map.GetWorldSize(),width=width,height=height,land=Map.GetLandPlots(),majors=majors,minors=minors,options=options,cities=cities,units=units,gold=player:GetGold(),culture=player:GetJONSCulture(),faith=player:GetFaith(),research=player:GetCurrentResearch(),spies=#player:GetEspionageSpies(),multiplayer=Game.IsGameMultiPlayer(),science=Game.IsOption("GAMEOPTION_NO_SCIENCE") and scienceState(player) or nil}
end
function LekmodScenario.step(player)
    if not started then
        started=Game.GetGameTurn()
        local s=LekmodScenario.snapshot(player)
        researchBefore=s.science and LekmodScenarioJSON(s.science) or nil
        assert(not s.multiplayer and player:IsHuman() and Game.GetAIAutoPlay()==0,"setup is not normal single-player human control")
        assert(s.speed==GameInfo.GameSpeeds["__TEST_GAME_SPEED__"].ID and s.handicap==GameInfo.HandicapInfos["__TEST_HANDICAP__"].ID,"speed or human difficulty differs from requested normal setup")
        assert(s.era==GameInfo.Eras["__TEST_START_ERA__"].ID and s.world==GameInfo.Worlds["__TEST_WORLD_SIZE__"].ID,"era/world differs from requested setup")
        assert(s.majors==__TEST_MAJORS__ and s.minors==__TEST_MINORS__,"actual living roster differs from requested slots")
        assert(s.width>0 and s.height>0 and s.land>0,"generated map has no usable land")
        for name,value in pairs(__TEST_GAME_OPTIONS__) do assert(Game.IsOption(name)==(value==1),"requested option differs: "..name) end
        LekmodScenarioEvent("actual-setup",s)
        LekmodScenarioEvent("setup-labels",{era=Locale.ConvertTextKey(GameInfo.Eras[s.era].Description),speed=Locale.ConvertTextKey(GameInfo.GameSpeeds[s.speed].Description),handicap=Locale.ConvertTextKey(GameInfo.HandicapInfos[s.handicap].Description)})
        LekmodScenarioRecord("setup-configuration","PASS","map=__TEST_MAP_SCRIPT__ speed=__TEST_GAME_SPEED__ human-handicap=__TEST_HANDICAP__ era=__TEST_START_ERA__ actual-roster-verified=true")
    end
    if Game.GetGameTurn()<started+2 then return "turn" end
    assert(Game.GetGameTurn()==started+2 and player:GetNumCities()>0 and Game.GetWinner()==-1,"two ordinary human turns/city readiness failed")
    if Game.IsOption("GAMEOPTION_NO_BARBARIANS") then
        assert(Players[GameDefines.BARBARIAN_PLAYER]:GetNumUnits()==0,"barbarian units appeared with barbarians disabled")
    end
    if Game.IsOption("GAMEOPTION_NO_ESPIONAGE") then assert(#player:GetEspionageSpies()==0,"spies awarded with espionage disabled") end
    if Game.IsOption("GAMEOPTION_NO_SCIENCE") then
        -- CanResearch reports prerequisite eligibility even with NO_SCIENCE.
        -- doResearch must not apply ordinary science, including to repeat techs.
        local actual= scienceState(player)
        assert(LekmodScenarioJSON(actual)==researchBefore,"ordinary research progressed with science disabled")
        LekmodScenarioEvent("disabled-science-outcome",{turns=2,technologies_and_progress_and_overflow_unchanged=true})
    end
    if Game.IsOption("GAMEOPTION_NO_POLICIES") then assert(player:GetTotalJONSCulturePerTurn()==0,"culture still accrues with policies disabled") end
    if Game.IsOption("GAMEOPTION_ONE_CITY_CHALLENGE") then
        assert(player:GetNumCities()==1,"human has multiple cities under OCC")
        local control=false
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            assert(not player:CanFound(p:GetX(),p:GetY()),"human may found a second OCC city")
            if Players[1]:CanFound(p:GetX(),p:GetY()) then control=true end
        end
        assert(control,"no otherwise-expandable AI control plot for OCC restriction")
    end
    LekmodScenarioRecord("setup-options","PASS","requested-flags-and-applicable-barbarian/spy/research/culture/OCC-boundaries verified")
    LekmodScenarioRecord("setup-two-human-turns","PASS","path=normal-human-driver ordinary-turns=2 city-founded=true")
    return true
end
