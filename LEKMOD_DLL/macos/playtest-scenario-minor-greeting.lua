LekmodScenario={name="minor-greeting",items={"minor-personality-greeting"}}
local requested,done=false,false
LuaEvents.LekmodGreetingValidated.Add(function(id,text) done=true;LekmodScenarioEvent("greeting-text",{minor=id,text=text}) end)
function LekmodScenario.snapshot(player)
    local minors={}
    for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do
        local p=Players[id]
        if p and p:IsAlive() and p:IsMinorCiv() then
            minors[id]={met=Teams[player:GetTeam()]:IsHasMet(p:GetTeam()),personality=p:GetMinorCivPersonalityType()}
        end
    end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),minors=minors}
end
function LekmodScenario.step(player)
    if done then LekmodScenarioRecord("minor-personality-greeting","PASS","path=real-first-contact-popup-and-Close");return true end
    if requested then return false end
    for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do
        local p=Players[id]
        if p and p:IsAlive() and p:IsMinorCiv() and not Teams[player:GetTeam()]:IsHasMet(p:GetTeam()) then
            requested=true
            LekmodScenarioEvent("fixture-setup",{operation="established-contact",minor=id,personality=p:GetMinorCivPersonalityType()})
            Teams[player:GetTeam()]:Meet(p:GetTeam(),false);return false
        end
    end
    error("fixture has no unmet city state")
end
