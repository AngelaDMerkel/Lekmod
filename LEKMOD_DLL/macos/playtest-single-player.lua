-- Temporary native functional checks. No autoplay, turn advancement, granted
-- resources/technology, or manual-save writes. These do not test mouse hitboxes.
do
    local ready, stopped = false, false
    local elapsed, phase = 0, "init"
    local cityID, oldFocus, oldAvoid, expectedFocus
    local productionIndex = 0
    local categories = {"unit", "building", "wonder", "process"}
    local pending, response
    local function fingerprint(player, city)
        local order, item = city:GetOrderFromQueue(0)
        local parts = {Game.GetGameTurn(), player:GetID(), city:GetID(), city:GetPopulation(),
            player:GetGold(), player:GetJONSCulture(), player:GetFaith(), player:GetCurrentResearch(),
            city:GetFocusType(), tostring(city:IsForcedAvoidGrowth()), order or -1, item or -1}
        local units = {}
        for unit in player:Units() do
            local data = string.gsub(unit:GetScriptData(), ".", function(c) return string.format("%02x", string.byte(c)) end)
            units[#units + 1] = table.concat({unit:GetID(), unit:GetUnitType(), unit:GetX(), unit:GetY(), unit:MovesLeft(), data}, ",")
        end
        table.sort(units)
        return table.concat(parts, ":") .. ";" .. table.concat(units, ";")
    end
    local function record(item, status, detail)
        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=" .. item .. " status=" .. status .. " " .. (detail or ""))
    end
    Events.SequenceGameInitComplete.Add(function() ready = true end)
    LuaEvents.LekmodFunctionalProductionResult.Add(function(category, status, order, item)
        response = {category = category, status = status, order = order, item = item}
    end)
    LuaEvents.LekmodFunctionalTechResult.Add(function(status)
        response = {status = status}
    end)
    LuaEvents.LekmodFunctionalCityResult.Add(function(status)
        response = {status = status}
    end)
    local function step()
        if not ready or Game.IsProcessingMessages() then return end
        local player = Players[Game.GetActivePlayer()]
        assert(player and player:IsHuman(), "fixture must have an active human player")
        -- Loading completes before the engine finishes handing the turn back.
        if not player:IsTurnActive() then return end
        assert(Game.GetAIAutoPlay() == 0, "autoplay must remain off")
        if phase == "init" then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=start")
            local city = player:GetCapitalCity()
            if not city then
                for unit in player:Units() do
                    if unit:CanFound(unit:GetPlot()) then
                        UI.SelectUnit(unit)
                        for actionID = 0, #GameInfoActions do
                            local action = GameInfoActions[actionID]
                            if action and action.Type == "MISSION_FOUND" and Game.CanHandleAction(actionID) then
                                Game.HandleAction(actionID)
                                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=fixture-city-founded")
                                return
                            end
                        end
                    end
                end
                error("new fixture has no city and no legal found-city action")
            end
            assert(city and not city:IsPuppet(), "fixture requires a controlled capital")
            local expected = __TEST_EXPECTED_STATE__
            if expected then
                assert(fingerprint(player, city) == expected, "reloaded game state differs from the manual save")
                record("save-reload", "PASS", "state=turn-city-queue-yields-unit-positions-moves-and-script-data")
            end
            cityID, oldFocus, oldAvoid = city:GetID(), city:GetFocusType(), city:IsForcedAvoidGrowth()
            local unit
            for candidate in player:Units() do unit = candidate; break end
            assert(unit, "fixture requires a unit")
            local original = unit:GetScriptData()
            local ok, err = pcall(function()
                for _, value in ipairs({"", "Lekmod native round trip", string.rep("long-script-data-", 512), "Lekmod: Māori"}) do
                    unit:SetScriptData(value)
                    for i = 1, 100 do assert(unit:GetScriptData() == value, "unit script data did not round-trip") end
                end
            end)
            unit:SetScriptData(original)
            assert(ok, err)
            assert(unit:GetScriptData() == original, "script data was not restored")
            record("script-data", "PASS", "reads=400 restored=true")
            local overflow = player:GetOverflowResearch()
            local research = player:GetCurrentResearch()
            local techs, progress = Teams[player:GetTeam()]:GetTeamTechs(), {}
            for tech in GameInfo.Technologies() do progress[tech.ID] = techs:GetResearchProgress(tech.ID) end
            assert(player.ChangeOverflowResearch, "GameCore lacks the science-overflow binding")
            local overflowOK, overflowError = pcall(function()
                player:ChangeOverflowResearch(12)
                assert(player:GetOverflowResearch() == overflow + 12, "science overflow did not increase by 12")
                assert(player:GetCurrentResearch() == research, "overflow changed the selected research")
                for id, value in pairs(progress) do
                    assert(techs:GetResearchProgress(id) == value, "overflow changed technology progress")
                end
            end)
            player:ChangeOverflowResearch(overflow - player:GetOverflowResearch())
            assert(overflowOK, overflowError)
            assert(player:GetOverflowResearch() == overflow, "science overflow was not restored")
            record("science-overflow", "PASS", "delta=12 technology-progress=unchanged restored=true path=lua-binding")
            local x,y=unit:GetX(),unit:GetY()
            local positionOK,positionError=pcall(function() unit:SetXY(x,y,false,true,false,false) end)
            assert(positionOK, "SetXY boolean flags rejected: "..tostring(positionError))
            assert(unit:GetX()==x and unit:GetY()==y, "same-position SetXY changed the unit position")
            record("unit-position-flags", "PASS", "path=lua-binding same-position=true flags=boolean")
            if __TEST_CITY_CONTROLS__ then
                response = nil
                LuaEvents.LekmodFunctionalCity(cityID)
                phase = "city-callbacks"
                return
            end
            expectedFocus = oldFocus == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION and
                CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD or CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION
            Network.SendSetCityAIFocus(cityID, expectedFocus)
            phase = "focus"
        elseif phase == "city-callbacks" then
            if not response then return end
            assert(response.status == "PASS", "CityView callback checks failed")
            response = nil
            LuaEvents.LekmodFunctionalTech()
            phase = "tech"
        elseif phase == "focus" then
            local city = player:GetCityByID(cityID)
            assert(city:GetFocusType() == expectedFocus, "focus command was not applied")
            Network.SendSetCityAIFocus(cityID, oldFocus)
            phase = "focus-restore"
        elseif phase == "focus-restore" then
            local city = player:GetCityByID(cityID)
            assert(city:GetFocusType() == oldFocus, "focus was not restored")
            record("city-focus", "PASS", "path=synchronized-command restored=true")
            Network.SendSetCityAvoidGrowth(cityID, not oldAvoid)
            phase = "growth"
        elseif phase == "growth" then
            local city = player:GetCityByID(cityID)
            assert(city:IsForcedAvoidGrowth() == not oldAvoid, "avoid-growth command was not applied")
            Network.SendSetCityAvoidGrowth(cityID, oldAvoid)
            phase = "growth-restore"
        elseif phase == "growth-restore" then
            assert(player:GetCityByID(cityID):IsForcedAvoidGrowth() == oldAvoid, "avoid-growth was not restored")
            record("avoid-growth", "PASS", "path=synchronized-command restored=true")
            response = nil
            LuaEvents.LekmodFunctionalTech()
            phase = "tech"
        elseif phase == "tech" then
            if not response then return end
            assert(response.status == "PASS", "tech-tree adapter failed")
            record("tech-tree", "PASS", "path=open-and-close-callback mouse_tested=false")
            phase = "production"
        elseif phase == "production" then
            productionIndex = productionIndex + 1
            if productionIndex > #categories then
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete")
                stopped = true
                local saveName = __TEST_SAVE_NAME__
                if saveName then
                    for unit in player:Units() do
                        unit:SetScriptData("LekmodSaveRoundtrip:__TEST_RUN__")
                        break
                    end
                    print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=save-state value=" .. fingerprint(player, player:GetCityByID(cityID)))
                    LuaEvents.LekmodFunctionalSave(saveName)
                end
                return
            end
            response, pending = nil, categories[productionIndex]
            LuaEvents.LekmodFunctionalProduction(cityID, pending)
            phase = "production-verify"
        elseif phase == "production-verify" then
            if not response then return end
            assert(response.category == pending, "unexpected production response")
            assert(response.status ~= "FAIL", "production adapter failed")
            if response.status == "SKIP" then
                record("production-" .. pending, "SKIP", "reason=no-legal-item-in-fixture")
            else
                local city = player:GetCityByID(cityID)
                local order, item = city:GetOrderFromQueue(0)
                assert(order == response.order and item == response.item, "UI selection did not reach production queue")
                record("production-" .. pending, "PASS", "path=production-popup-callback item_id=" .. item)
            end
            phase = "production"
        end
    end
    ContextPtr:SetUpdate(function(dt)
        if stopped then return end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        local ok, err = pcall(step)
        if not ok then
            stopped = true
            record(phase, "FAIL", "error=" .. tostring(err))
        end
    end)
end
