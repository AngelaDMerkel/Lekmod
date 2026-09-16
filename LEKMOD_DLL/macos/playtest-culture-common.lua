function LekmodCultureSnapshot(player)
    local targets,units={},{}
    for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
        local other=Players[id]
        if other and other:IsAlive() and id~=player:GetID() then
            targets[id]={culture=other:GetJONSCultureEverGenerated(),influence=player:GetInfluenceOn(id),level=player:GetInfluenceLevel(id)}
        end
    end
    for unit in player:Units() do
        if unit:GetUnitType()==GameInfoTypes.UNIT_MUSICIAN and not unit:IsDelayedDeath() then
            units[unit:GetID()]={strength=unit:GetTourismBlastStrength(),x=unit:GetX(),y=unit:GetY(),moves=unit:GetMoves()}
        end
    end
    return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),victory=Game.GetVictory(),targets=targets,units=units,
        tourism=player:GetTourism(),works=player:GetNumGreatWorks(),influential=player:GetNumCivsInfluentialOn(),required=player:GetNumCivsToBeInfluentialOn()}
end
function LekmodCultureActionID(kind)
    for id=0,#GameInfoActions do
        if GameInfoActions[id] and GameInfoActions[id].Type==kind then return id end
    end
    error("missing cultural action: "..kind)
end
function LekmodCultureAction(unit,kind)
    UI.SelectUnit(unit)
    local id=LekmodCultureActionID(kind)
    assert(Game.CanHandleAction(id),"cultural action unavailable: "..kind)
    Game.HandleAction(id)
end
