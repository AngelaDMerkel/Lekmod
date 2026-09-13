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

function LekmodScenarioStart()
    local ready, stopped, started, elapsed = false, false, false, 0
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
                LekmodScenarioEvent("scenario-start", {name=LekmodScenario.name, turn=Game.GetGameTurn()})
                if expected then
                    assert(LekmodScenarioJSON(LekmodScenario.snapshot(player)) == expected, "scenario save/reload state differs")
                    LekmodScenarioRecord("save-reload", "PASS", "scope=" .. LekmodScenario.name)
                end
            end
            if expected or LekmodScenario.step(player) then
                stopped = true
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete scope=" .. LekmodScenario.name)
                local saveName = __TEST_SAVE_NAME__
                if saveName then
                    print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=save-state value=" ..
                        LekmodScenarioJSON(LekmodScenario.snapshot(player)))
                    LuaEvents.LekmodFunctionalSave(saveName)
                end
            end
        end)
        if not ok then
            stopped = true
            LekmodScenarioRecord("scenario-" .. LekmodScenario.name, "FAIL", "error=" .. tostring(err))
        end
    end)
end
