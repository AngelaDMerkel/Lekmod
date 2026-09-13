-- Existing spy, existing revealed cities, normal espionage network commands.
-- Tests assignment/recall and persisted state; no spy or intelligence is granted.
LekmodScenario = {name="espionage", items={"spy-home", "spy-recall", "spy-foreign", "spy-diplomat"}}
local phase, agent, home, target = "init", nil, nil, nil
local function getAgent(player)
    for _, spy in ipairs(player:GetEspionageSpies()) do
        if spy.AgentID == agent then return spy end
    end
    error("fixture spy disappeared")
end
local function send(player, owner, city, diplomat)
    if owner ~= -1 then
        local legal = false
        for _, candidate in ipairs(player:GetAvailableSpyRelocationCities(agent)) do
            if candidate.PlayerID == owner and candidate.CityID == city then legal = true; break end
        end
        assert(legal, "spy destination is not in the normal available relocation list")
    end
    Network.SendMoveSpy(player:GetID(), agent, owner, city, diplomat)
    LekmodScenarioEvent("spy-command", {agent=agent, owner=owner, city=city, diplomat=diplomat, path="network"})
end
local function verify(player, city, diplomat)
    local spy = getAgent(player)
    assert(spy.CityX == city:GetX() and spy.CityY == city:GetY(), "spy destination did not apply")
    assert(spy.IsDiplomat == diplomat, "spy/diplomat role did not apply")
    assert(spy.State == "TXT_KEY_SPY_STATE_TRAVELLING", "new assignment did not start travel")
    LekmodScenarioEvent("spy-observed", spy)
end
function LekmodScenario.snapshot(player)
    return {turn=Game.GetGameTurn(), player=player:GetID(), gold=player:GetGold(), faith=player:GetFaith(), spies=player:GetEspionageSpies()}
end
function LekmodScenario.step(player)
    if phase == "init" then
        for _, spy in ipairs(player:GetEspionageSpies()) do
            if spy.State == "TXT_KEY_SPY_STATE_UNASSIGNED" then agent=spy.AgentID; break end
        end
        assert(agent ~= nil, "fixture needs an existing unassigned spy")
        home = player:GetCapitalCity()
        for _, candidate in ipairs(player:GetAvailableSpyRelocationCities(agent)) do
            local other = Players[candidate.PlayerID]
            local city = other:GetCityByID(candidate.CityID)
            if candidate.PlayerID ~= player:GetID() and not other:IsMinorCiv() and city:IsCapital()
                and not Teams[player:GetTeam()]:IsAtWar(other:GetTeam()) then
                target=city; break
            end
        end
        assert(target, "fixture needs a revealed foreign capital available to a diplomat")
        send(player, player:GetID(), home:GetID(), false)
        phase="home"
    elseif phase == "home" then
        verify(player, home, false)
        LekmodScenarioRecord("spy-home", "PASS", "path=network-command")
        send(player, -1, -1, false)
        phase="recall"
    elseif phase == "recall" or phase == "recall-again" then
        local spy=getAgent(player)
        assert(spy.CityX == -1 and spy.CityY == -1 and spy.State == "TXT_KEY_SPY_STATE_UNASSIGNED", "recall did not return spy to HQ")
        LekmodScenarioRecord("spy-recall", "PASS", "path=network-command")
        local diplomat=phase == "recall-again"
        send(player, target:GetOwner(), target:GetID(), diplomat)
        phase=diplomat and "diplomat" or "foreign"
    elseif phase == "foreign" then
        verify(player, target, false)
        LekmodScenarioRecord("spy-foreign", "PASS", "path=network-command")
        send(player, -1, -1, false)
        phase="recall-again"
    elseif phase == "diplomat" then
        verify(player, target, true)
        LekmodScenarioRecord("spy-diplomat", "PASS", "path=network-command state=travelling")
        return true
    end
    return false
end
