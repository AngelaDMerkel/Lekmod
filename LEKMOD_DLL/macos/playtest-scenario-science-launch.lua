include("LekmodTestScience.lua")
LekmodScenario={name="science-launch",items={"science-final-part","science-victory","victory-panel"}}
LekmodScenario.snapshot=LekmodScienceSnapshot
local submitted=false
function LekmodScenario.step(player)
    if submitted then
        if Game.GetWinner()~=-1 then return false end
        return "turn"
    end
    local team=Teams[player:GetTeam()]
    for name,count in pairs({PROJECT_APOLLO_PROGRAM=1,PROJECT_SS_COCKPIT=1,PROJECT_SS_BOOSTER=3,PROJECT_SS_ENGINE=1,PROJECT_SS_STASIS_CHAMBER=0}) do
        assert(team:GetProjectCount(GameInfoTypes[name])==count,"unexpected prelaunch project count: "..name)
    end
    assert(Game.GetWinner()==-1,"prelaunch fixture has a winner")
    local component
    for unit in player:Units() do
        if unit:GetUnitType()==GameInfoTypes.UNIT_SS_STASIS_CHAMBER then assert(not component,"multiple final components");component=unit end
    end
    assert(component and component:CanBuildSpaceship(component:GetPlot()),"final component is not ready at capital")
    LekmodScenarioEvent("science-before-final",LekmodScienceSnapshot(player))
    if not LekmodScienceAction(component) then return "turn" end
    submitted=true
    return false
end
