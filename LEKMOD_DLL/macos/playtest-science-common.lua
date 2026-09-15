-- Shared read-only state and normal action dispatch for science fixtures.
function LekmodScienceSnapshot(player)
    local team,projects,units=Teams[player:GetTeam()],{},{}
    for item in GameInfo.Projects() do
        if item.Type=="PROJECT_APOLLO_PROGRAM" or string.sub(item.Type,1,11)=="PROJECT_SS_" then
            projects[item.Type]=team:GetProjectCount(item.ID)
        end
    end
    for unit in player:Units() do
        local info=GameInfo.Units[unit:GetUnitType()]
        if info.SpaceshipProject then
            units[unit:GetID()]={type=info.Type,project=info.SpaceshipProject,x=unit:GetX(),y=unit:GetY(),moves=unit:GetMoves()}
        end
    end
    return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),victory=Game.GetVictory(),projects=projects,units=units,
        gold=player:GetGold(),aluminum=player:GetNumResourceAvailable(GameInfoTypes.RESOURCE_ALUMINUM,true)}
end

function LekmodScienceAction(unit)
    assert(unit:CanBuildSpaceship(unit:GetPlot()),"component is not eligible for assembly at its plot")
    UI.SelectUnit(unit)
    for id=0,#GameInfoActions do
        local action=GameInfoActions[id]
        if action and action.Type=="MISSION_SPACESHIP" then
            if not Game.CanHandleAction(id) then return false end
            Game.HandleAction(id)
            return true
        end
    end
    error("spaceship action is missing")
end
