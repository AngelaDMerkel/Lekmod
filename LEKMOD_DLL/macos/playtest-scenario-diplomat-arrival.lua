LekmodScenario={name="diplomat-arrival",items={"diplomat-arrival"}}
local selected,previous
function LekmodScenario.snapshot(player)
    return {turn=Game.GetGameTurn(),spies=player:GetEspionageSpies()}
end
function LekmodScenario.step(player)
    for _,spy in ipairs(player:GetEspionageSpies()) do
        if spy.IsDiplomat and (selected==nil or spy.AgentID==selected) then
            selected=spy.AgentID
            local state=spy.State..":"..spy.TurnsLeft
            if state~=previous then LekmodScenarioEvent("diplomat-progress",spy);previous=state end
            assert(spy.State~="TXT_KEY_SPY_STATE_DEAD", "diplomat died")
            if player:IsSpySchmoozing(selected) then
                LekmodScenarioRecord("diplomat-arrival","PASS","path=ordinary-travel-and-introductions agent="..selected)
                return true
            end
            return "turn"
        end
    end
    error("fixture has no assigned diplomat")
end
