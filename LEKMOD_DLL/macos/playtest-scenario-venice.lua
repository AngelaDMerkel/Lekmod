-- Two Venice players selected through normal single-player setup. Supplied
-- technologies generate native TeamTechResearched events; not earned research.
LekmodScenario={name="venice",items={"venice-first-compass","venice-second-compass","venice-idempotent-tech"}}
local phase,before="init",{}
function LekmodScenario.snapshot(player)
    local result={}
    for id=0,1 do local p=Players[id]
        result[id]={civ=p:GetCivilizationType(),compass=Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_COMPASS),misc_routes=p:GetNumMiscTradeRoutes(),capacity=p:GetNumInternationalTradeRoutesAvailable()}
    end
    return {turn=Game.GetGameTurn(),players=result}
end
function LekmodScenario.step(player)
    if not player:GetCapitalCity() or not Players[1]:GetCapitalCity() then return "turn" end
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_VENEZ and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_VENEZ,"select human and AI Venice in normal setup")
    assert(player:GetTeam()~=Players[1]:GetTeam(),"requires distinct teams")
    if phase=="init" then
        for id=0,1 do local p=Players[id]
            assert(not Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_COMPASS),"start before Compass")
            before[id]=p:GetNumMiscTradeRoutes()
        end
        LekmodScenarioGrantTech(player,"TECH_COMPASS");phase="first"
    elseif phase=="first" then
        assert(player:GetNumMiscTradeRoutes()==before[0]+1 and Players[1]:GetNumMiscTradeRoutes()==before[1],"first Compass award/other-owner boundary differs")
        LekmodScenarioRecord("venice-first-compass","PASS","native-team-tech-event bonus=1 other-owner=unchanged")
        LekmodScenarioGrantTech(Players[1],"TECH_COMPASS");phase="second"
    elseif phase=="second" then
        LekmodScenarioEvent("venice-compass-outcome",LekmodScenario.snapshot(player))
        if Players[1]:GetNumMiscTradeRoutes()~=before[1]+1 or player:GetNumMiscTradeRoutes()~=before[0]+1 then
            LekmodScenarioRecord("venice-second-compass","FAIL","later-Venice-on-another-team-lost-Compass-bonus")
            -- Finish diagnostic collection and normal save/exit. The explicit
            -- FAIL keeps functional verification false even with completion.
            return true
        end
        LekmodScenarioRecord("venice-second-compass","PASS","native-team-tech-event bonus=1 both-owners=true")
        for id=0,1 do local p=Players[id]
            Teams[p:GetTeam()]:SetHasTech(GameInfoTypes.TECH_COMPASS,true,id,true,true)
            assert(p:GetNumMiscTradeRoutes()==before[id]+1,"already-known technology repeated the bonus")
        end
        LekmodScenarioRecord("venice-idempotent-tech","PASS","already-known-technology-no-additional-event-bonus=true")
        return true
    end
    return false
end
