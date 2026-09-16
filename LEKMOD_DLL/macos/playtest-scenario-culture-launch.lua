include("LekmodTestCulture.lua")
LekmodScenario={name="culture-launch",items={"culture-threshold","cultural-victory","victory-panel"}}
LekmodScenario.snapshot=LekmodCultureSnapshot
local submitted=false
function LekmodScenario.step(player)
    if submitted then
        if Game.GetWinner()~=-1 then return false end
        return "turn"
    end
    assert(Game.GetWinner()==-1 and player:GetNumCivsInfluentialOn()<player:GetNumCivsToBeInfluentialOn(),"fixture already meets victory")
    local musician
    for unit in player:Units() do
        if unit:GetUnitType()==GameInfoTypes.UNIT_MUSICIAN and not unit:IsDelayedDeath() then
            assert(not musician,"multiple final musicians");musician=unit
        end
    end
    assert(musician,"final musician missing")
    local target=musician:GetPlot():GetOwner()
    assert(target~=player:GetID() and target>=0,"final musician is not in foreign territory")
    local before=player:GetInfluenceOn(target)
    local strength=musician:GetBlastTourism()
    assert(before<Players[target]:GetJONSCultureEverGenerated() and before+strength>=Players[target]:GetJONSCultureEverGenerated(),"final concert cannot cross threshold")
    LuaEvents.LekmodCultureFinal(target,before,strength,musician:GetID())
    LekmodScenarioEvent("culture-before-final",LekmodCultureSnapshot(player))
    LekmodCultureAction(musician,"MISSION_ONE_SHOT_TOURISM");submitted=true
    return false
end
