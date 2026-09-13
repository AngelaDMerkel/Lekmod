-- Temporary checks inside the installed CityView. Use its existing callbacks.
do
    local cityID, originalFocus, originalAvoid, elapsed, stage, index, expected
    local focuses = {
        {"BalancedFocusButton", "NO_CITY_AI_FOCUS_TYPE"},
        {"FoodFocusButton", "CITY_AI_FOCUS_TYPE_FOOD"},
        {"ProductionFocusButton", "CITY_AI_FOCUS_TYPE_PRODUCTION"},
        {"GoldFocusButton", "CITY_AI_FOCUS_TYPE_GOLD"},
        {"ResearchFocusButton", "CITY_AI_FOCUS_TYPE_SCIENCE"},
        {"CultureFocusButton", "CITY_AI_FOCUS_TYPE_CULTURE"},
        {"GPFocusButton", "CITY_AI_FOCUS_TYPE_GREAT_PEOPLE"},
        {"FaithFocusButton", "CITY_AI_FOCUS_TYPE_FAITH"},
        {"GoldenAgePointsFocusButton", "CITY_AI_FOCUS_TYPE_GOLDEN_AGE_POINTS"}
    }
    LuaEvents.LekmodFunctionalCity.Add(function(id)
        local city = Players[Game.GetActivePlayer()]:GetCityByID(id)
        cityID, originalFocus, originalAvoid = id, city:GetFocusType(), city:IsForcedAvoidGrowth()
        elapsed, stage, index = 0, "open", 0
        UI.DoSelectCityAtPlot(city:Plot())
    end)
    local function step()
        local city = UI.GetHeadSelectedCity()
        assert(city and city:GetID() == cityID, "CityView selected the wrong city")
        if stage == "open" then
            assert(not ContextPtr:IsHidden(), "CityView did not open")
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=city-view")
            stage = "capture"
        elseif stage == "capture" then
            stage = "focus"
        elseif stage == "focus" then
            index = index + 1
            if index > #focuses then
                FocusChanged(originalFocus)
                stage = "restore-focus"
                return
            end
            local pair = focuses[index]
            assert(Controls[pair[1]] ~= nil, "missing focus control: " .. pair[1])
            expected = CityAIFocusTypes[pair[2]]
            assert(expected ~= nil, "missing focus enum: " .. pair[2])
            FocusChanged(expected)
            stage = "verify-focus"
        elseif stage == "verify-focus" then
            assert(city:GetFocusType() == expected, "focus callback did not apply " .. focuses[index][2])
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=focus-verified type=" .. focuses[index][2])
            stage = "focus"
        elseif stage == "restore-focus" then
            assert(city:GetFocusType() == originalFocus, "focus not restored")
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=city-focus status=PASS path=city-view-callback types=9 restored=true")
            OnAvoidGrowth()
            stage = "verify-growth"
        elseif stage == "verify-growth" then
            assert(city:IsForcedAvoidGrowth() == not originalAvoid, "avoid-growth callback not applied")
            OnAvoidGrowth()
            stage = "restore-growth"
        elseif stage == "restore-growth" then
            assert(city:IsForcedAvoidGrowth() == originalAvoid, "avoid-growth not restored")
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=avoid-growth status=PASS path=city-view-callback restored=true")
            OnReturnToMapButton()
            cityID = nil
            LuaEvents.LekmodFunctionalCityResult("PASS")
        end
    end
    ContextPtr:SetUpdate(function(dt)
        if not cityID or Game.IsProcessingMessages() then return end
        elapsed = elapsed + dt
        local interval = stage == "capture" and __TEST_CAPTURE_PANELS__ and 10 or 1
        if elapsed < interval then return end
        elapsed = 0
        local ok, err = pcall(step)
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=city-view status=FAIL error=" .. tostring(err))
            cityID = nil
            OnReturnToMapButton()
            LuaEvents.LekmodFunctionalCityResult("FAIL")
        end
    end)
end
