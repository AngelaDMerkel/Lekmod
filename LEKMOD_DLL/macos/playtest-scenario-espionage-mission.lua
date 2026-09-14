-- Existing spy and revealed foreign city; science is earned by normal turns.
LekmodScenario={name="espionage-mission",items={"spy-surveillance","spy-science","spy-return"}}
local phase,agent,target,cityID,chosen,before,award,remaining,response,previous="init"
local surveillance=false
LuaEvents.LekmodScenarioSpyTechSelected.Add(function(tech) response=tech end)
local function spyFor(player)
    for _,spy in ipairs(player:GetEspionageSpies()) do if spy.AgentID==agent then return spy end end
    error("fixture spy disappeared")
end
function LekmodScenario.snapshot(player)
    local techs,progress=Teams[player:GetTeam()]:GetTeamTechs(),{}
    for tech in GameInfo.Technologies() do
        progress[tech.ID]={known=techs:HasTech(tech.ID),progress=techs:GetResearchProgress(tech.ID)}
    end
    return {turn=Game.GetGameTurn(),spies=player:GetEspionageSpies(),research=progress}
end
function LekmodScenario.step(player)
    if phase=="init" then
        for _,spy in ipairs(player:GetEspionageSpies()) do
            if spy.State=="TXT_KEY_SPY_STATE_UNASSIGNED" then agent=spy.AgentID;break end
        end
        assert(agent~=nil, "fixture requires an unassigned existing spy")
        local biggest=-1
        for _,city in ipairs(player:GetAvailableSpyRelocationCities(agent)) do
            if city.PlayerID~=player:GetID() and not Players[city.PlayerID]:IsMinorCiv() and city.Population>biggest then
                target,cityID,biggest=city.PlayerID,city.CityID,city.Population
            end
        end
        assert(target, "no legal foreign major-city destination")
        -- Lekmod excludes ancient/classical technology from espionage. The
        -- ancient save needs research prerequisites for a known foreign
        -- medieval technology; the actual target and spy progress stay earned.
        local candidate
        for tech in GameInfo.Technologies() do
            if tech.Era=="ERA_MEDIEVAL" and Teams[Players[target]:GetTeam()]:GetTeamTechs():HasTech(tech.ID)
                and not Teams[player:GetTeam()]:GetTeamTechs():HasTech(tech.ID) then candidate=tech;break end
        end
        assert(candidate, "destination lacks a medieval research target")
        for row in GameInfo.Technology_PrereqTechs{TechType=candidate.Type} do
            LekmodScenarioGrantTech(player,row.PrereqTech)
        end
        LekmodScenarioEvent("spy-research-fixture",{target=target,technology=candidate.Type,known=false})
        local destination=assert(Players[target]:GetCityByID(cityID))
        local oldPopulation=destination:GetPopulation()
        local oldScience=destination:GetYieldRateTimes100(YieldTypes.YIELD_SCIENCE)
        destination:SetPopulation(32,true)
        local buildings={}
        for _,kind in ipairs({"BUILDING_LIBRARY","BUILDING_UNIVERSITY","BUILDING_PUBLIC_SCHOOL","BUILDING_LABORATORY"}) do
            local id=assert(GameInfoTypes[kind],"unknown science fixture building")
            buildings[kind]={before=destination:GetNumRealBuilding(id),after=1}
            destination:SetNumRealBuilding(id,1)
        end
        LekmodScenarioEvent("fixture-setup",{operation="provided-foreign-research-city",owner=target,city=cityID,
            population_before=oldPopulation,population_after=destination:GetPopulation(),buildings=buildings,
            science_before=oldScience,science_after=destination:GetYieldRateTimes100(YieldTypes.YIELD_SCIENCE)})
        local gold=player:GetGold();player:ChangeGold(1000)
        LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-buffer",before=gold,added=1000})
        Network.SendMoveSpy(player:GetID(),agent,target,cityID,false)
        phase="progress"
        return false
    end
    local spy=spyFor(player)
    assert(spy.State~="TXT_KEY_SPY_STATE_DEAD", "spy was caught and killed; fixture outcome must be reviewed")
    local state=spy.State..":"..spy.TurnsLeft
    if state~=previous then LekmodScenarioEvent("spy-mission-progress",spy);previous=state end
    if phase=="progress" then
        if spy.EstablishedSurveillance and not surveillance then
            surveillance=true
            LekmodScenarioRecord("spy-surveillance","PASS","path=ordinary-travel-and-surveillance agent="..agent)
        end
        for tech in GameInfo.Technologies() do
            if player:canStealTech(target,tech.ID) and player:ScienceToStealAmount(target,tech.ID)>0 then
                chosen=tech.ID;break
            end
        end
        if not chosen then return "turn" end
        local techs=Teams[player:GetTeam()]:GetTeamTechs()
        before=techs:GetResearchProgress(chosen)
        award=player:ScienceToStealAmount(target,chosen)
        remaining=player:GetResearchCost(chosen)-before
        assert(award>0 and not techs:HasTech(chosen), "espionage award is not available")
        LekmodScenarioEvent("spy-award-before",{target=target,tech=chosen,progress=before,award=award,remaining=remaining})
        response=nil;LuaEvents.LekmodScenarioSpyTech(target,chosen);phase="award"
    elseif phase=="award" then
        if not response then return false end
        local techs=Teams[player:GetTeam()]:GetTeamTechs()
        local applied=(techs:HasTech(chosen) and award==remaining) or techs:GetResearchProgress(chosen)==before+award
        if not LekmodScenarioAwait("espionage-science",applied) then return false end
        LekmodScenarioRecord("spy-science","PASS","path=earned-award-and-tech-popup tech="..chosen.." science="..award)
        Network.SendMoveSpy(player:GetID(),agent,-1,-1,false);phase="return"
    elseif phase=="return" then
        if not LekmodScenarioAwait("spy-return",spy.State=="TXT_KEY_SPY_STATE_UNASSIGNED") then return false end
        assert(surveillance and spy.CityX==-1 and spy.CityY==-1, "spy return/surveillance state invalid")
        LekmodScenarioRecord("spy-return","PASS","path=normal-recall")
        return true
    end
    return false
end
