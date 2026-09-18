-- Read-only check for an affected save or a normal later-era start. The product
-- initialization hook, not this scenario, must restore any missing route award.
LekmodScenario={name="venice-known-compass",items={"venice-known-compass-awards"}}
function LekmodScenario.snapshot(player)
    local result={}
    for id=0,1 do local p=Players[id]
        result[id]={civ=p:GetCivilizationType(),compass=Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_COMPASS),misc_routes=p:GetNumMiscTradeRoutes(),capacity=p:GetNumInternationalTradeRoutesAvailable()}
    end
    return {turn=Game.GetGameTurn(),players=result}
end
function LekmodScenario.step(player)
    for id=0,1 do local p=Players[id]
        assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_VENEZ,"requires two normally configured Venice players")
        assert(Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_COMPASS),"requires already-known Compass")
        assert(p:GetNumMiscTradeRoutes()==1,"known Compass has a missing or repeated Venice award")
    end
    LekmodScenarioRecord("venice-known-compass-awards","PASS","native-initialization both-owners=1 scenario-read-only=true")
    return true
end
