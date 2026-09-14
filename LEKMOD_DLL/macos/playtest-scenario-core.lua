-- Temporary scenario support. Engine message processing and turn ownership are
-- prerequisites, never altered. Scenario setup/actions must be recorded.
function LekmodScenarioJSON(value)
    local kind = type(value)
    if kind == "nil" then return "null" end
    if kind == "boolean" then return tostring(value) end
    if kind == "number" then
        assert(value == value and value ~= math.huge and value ~= -math.huge, "non-finite snapshot number")
        return string.format("%.17g", value)
    end
    if kind == "string" then
        return '"' .. string.gsub(value, '[%z\1-\31\\"]', function(c)
            return string.format("\\u%04x", string.byte(c))
        end) .. '"'
    end
    assert(kind == "table", "snapshot cannot serialize " .. kind)
    local keys, parts = {}, {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do
        parts[#parts + 1] = LekmodScenarioJSON(tostring(key)) .. ":" .. LekmodScenarioJSON(value[key])
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

function LekmodScenarioRecord(item, status, detail)
    print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=" .. item .. " status=" .. status .. " " .. (detail or ""))
end

function LekmodScenarioEvent(event, value)
    print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=" .. event .. " value=" .. LekmodScenarioJSON(value))
end

local scenarioWaits={}
function LekmodScenarioAwait(key, ready)
    if ready then scenarioWaits[key]=nil; return true end
    scenarioWaits[key]=(scenarioWaits[key] or 0)+1
    assert(scenarioWaits[key]<=8, "synchronized result did not arrive: "..key)
    return false
end

function LekmodScenarioGrantTech(player, techType, visited)
    visited=visited or {}
    local tech=assert(GameInfo.Technologies[techType], "unknown fixture technology")
    local team=Teams[player:GetTeam()]
    if team:GetTeamTechs():HasTech(tech.ID) then return end
    assert(not visited[techType], "cyclic technology prerequisites")
    visited[techType]=true
    for row in GameInfo.Technology_PrereqTechs{TechType=techType} do
        LekmodScenarioGrantTech(player,row.PrereqTech,visited)
    end
    -- This is explicitly recorded scenario setup, including prerequisites and
    -- the usual tech announcements; it is not earned research evidence.
    team:SetHasTech(tech.ID,true,player:GetID(),true,true)
    LekmodScenarioEvent("fixture-setup",{operation="provided-technology",technology=techType,id=tech.ID})
    visited[techType]=nil
end

function LekmodScenarioStart()
    local ready, stopped, started, elapsed, startTurn = false, false, false, 0, nil
    local turnLimit=__TEST_SCENARIO_TURN_LIMIT__ or 0
    local originalUpdate = OnSoftPromptUpdate
    Events.SequenceGameInitComplete.Add(function() ready = true end)
    ContextPtr:SetUpdate(function(dt)
        if originalUpdate then originalUpdate(dt) end
        if stopped or not ready then return end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        if Game.IsProcessingMessages() then return end
        local player = Players[Game.GetActivePlayer()]
        if not player or not player:IsTurnActive() then return end
        local ok, err = pcall(function()
            assert(player:IsHuman() and Game.GetAIAutoPlay() == 0, "scenario requires active human control")
            local expected = __TEST_EXPECTED_STATE__
            if not started then
                started = true
                startTurn=Game.GetGameTurn()
                LekmodScenarioEvent("scenario-start", {name=LekmodScenario.name, turn=Game.GetGameTurn()})
                if expected then
                    local actual= LekmodScenarioJSON(LekmodScenario.snapshot(player))
                    if actual~=expected then
                        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=reload-expected value="..expected)
                        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=reload-actual value="..actual)
                    end
                    assert(actual == expected, "scenario save/reload state differs")
                    LekmodScenarioRecord("save-reload", "PASS", "scope=" .. LekmodScenario.name)
                end
            end
            assert(Game.GetGameTurn()-startTurn<=turnLimit, "scenario exceeded its explicit turn bound")
            local result=expected and true or LekmodScenario.step(player)
            if result=="turn" then
                assert(turnLimit>0 and Game.GetGameTurn()-startTurn<turnLimit, "scenario needs a turn beyond its explicit bound")
                assert(LekmodScenarioHumanTurn, "scenario has no normal human driver")
                LekmodScenarioHumanTurn()
            elseif result==true then
                stopped = true
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete scope=" .. LekmodScenario.name)
                local saveName = __TEST_SAVE_NAME__
                if saveName then
                    print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=save-state value=" ..
                        LekmodScenarioJSON(LekmodScenario.snapshot(player)))
                    LuaEvents.LekmodFunctionalSave(saveName)
                end
            else
                assert(result==nil or result==false, "invalid scenario step result")
            end
        end)
        if not ok then
            stopped = true
            LekmodScenarioRecord("scenario-" .. LekmodScenario.name, "FAIL", "error=" .. tostring(err))
        end
    end)
end
