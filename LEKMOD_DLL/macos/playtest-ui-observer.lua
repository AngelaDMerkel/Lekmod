-- Read-only observer for physical UI tests. Does not choose orders, dismiss
-- popups, alter turn state, or dispatch input. Runs in its own UI context.
do
    local ready, elapsed, previous = false, 0, nil
    Events.SequenceGameInitComplete.Add(function() ready = true end)
    Events.EndGameShow.Add(function(kind,team)
        print("[LEKMOD_UI_OBSERVE] run=__TEST_RUN__ event=endgame type="..kind.." team="..team)
    end)
    ContextPtr:SetUpdate(function(dt)
        if not ready then return end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        local player = Players[Game.GetActivePlayer()]
        if not player or not player:IsTurnActive() or Game.IsProcessingMessages() then return end
        if previous == nil then
            print("[LEKMOD_UI_OPTIONS] run=__TEST_RUN__ culture_overview_disabled=" .. tostring(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")))
            for id, minor in pairs(Players) do
                if minor:IsAlive() and minor:IsMinorCiv() and Teams[player:GetTeam()]:IsHasMet(minor:GetTeam()) then
                    print("[LEKMOD_UI_PERSONALITY] run=__TEST_RUN__ id=" .. id .. " name=" .. Locale.ConvertTextKey(minor:GetCivilizationShortDescriptionKey()) .. " type=" .. tostring(minor:GetMinorCivPersonalityType()))
                end
            end
        end
        local city = player:GetCapitalCity()
        local order, item = -1, -1
        if city then order, item = city:GetOrderFromQueue(0) end
        local queue, buildings, specialists, yields, worked, units = {}, {}, {}, {}, {}, {}
        local baseYields, modifiers, plotYields = {}, {}, {}
        if city then
            for index = 0, city:GetOrderQueueLength() - 1 do
                local kind, id = city:GetOrderFromQueue(index)
                queue[#queue + 1] = kind .. "," .. id
            end
            for building in GameInfo.Buildings() do
                local count = city:GetNumRealBuilding(building.ID)
                if count > 0 then
                    buildings[#buildings + 1] = building.ID .. "," .. count
                end
                local assigned = city:GetNumSpecialistsInBuilding(building.ID)
                if assigned > 0 then specialists[#specialists + 1] = building.ID .. "," .. assigned end
            end
            for yield in GameInfo.Yields() do
                yields[#yields + 1] = yield.ID .. "," .. city:GetYieldRateTimes100(yield.ID)
                baseYields[#baseYields + 1] = yield.ID .. "," .. city:GetBaseYieldRate(yield.ID)
                modifiers[#modifiers + 1] = yield.ID .. "," .. city:GetBaseYieldRateModifier(yield.ID)
            end
            for index = 0, city:GetNumCityPlots() - 1 do
                local plot = city:GetCityIndexPlot(index)
                if plot and city:IsWorkingPlot(plot) then
                    worked[#worked + 1] = index .. "," .. tostring(city:IsForcedWorkingPlot(plot))
                    plotYields[#plotYields + 1] = table.concat({index,
                        plot:GetYield(YieldTypes.YIELD_FOOD), plot:GetYield(YieldTypes.YIELD_PRODUCTION),
                        plot:GetYield(YieldTypes.YIELD_GOLD)}, ",")
                end
            end
        end
        for unit in player:Units() do
            units[#units + 1] = table.concat({unit:GetID(), unit:GetUnitType(), unit:GetX(), unit:GetY()}, ",")
        end
        local greatWorks, cultureCities = {}, {}
        for ownedCity in player:Cities() do
            cultureCities[#cultureCities + 1] = table.concat({ownedCity:GetID(), ownedCity:GetNumGreatWorks(),
                ownedCity:GetThemingBonus(GameInfoTypes.BUILDINGCLASS_MUSEUM), ownedCity:GetBaseTourism()}, ",")
            for building in GameInfo.Buildings() do
                if building.GreatWorkCount > 0 and ownedCity:GetNumBuilding(building.ID) > 0 then
                    local class = GameInfo.BuildingClasses[building.BuildingClass].ID
                    for slot = 0, building.GreatWorkCount - 1 do
                        greatWorks[#greatWorks + 1] = table.concat({ownedCity:GetID(), class, slot,
                            ownedCity:GetBuildingGreatWork(class, slot)}, ",")
                    end
                end
            end
        end
        table.sort(greatWorks)
        table.sort(cultureCities)
        table.sort(units)
        local state = table.concat({Game.GetGameTurn(), player:GetID(), tostring(player:IsTurnActive()),
            city and city:GetID() or -1, order or -1, item or -1,
            city and city:GetFocusType() or -1,
            tostring(city and city:IsForcedAvoidGrowth())}, ":") ..
            " gold=" .. player:GetGold() .. " queue=" .. table.concat(queue, ";") ..
            " science100=" .. player:GetScienceTimes100() ..
            " generic_science100=" .. player:GetYieldTimes100(YieldTypes.YIELD_SCIENCE) ..
            " deficit_science100=" .. player:GetScienceFromBudgetDeficitTimes100() ..
            " buildings=" .. table.concat(buildings, ";") .. " specialists=" .. table.concat(specialists, ";") ..
            " manual_specialists=" .. tostring(city and city:IsNoAutoAssignSpecialists()) ..
            " yields100=" .. table.concat(yields, ";") .. " worked=" .. table.concat(worked, ";") ..
            " base_yields=" .. table.concat(baseYields, ";") .. " modifiers=" .. table.concat(modifiers, ";") ..
            " plot_food_production_gold=" .. table.concat(plotYields, ";") ..
            " game_state=" .. Game.GetGameState() .. " winner=" .. Game.GetWinner() .. " victory=" .. Game.GetVictory() ..
            " units=" .. table.concat(units, ";") ..
            " greatworks=" .. table.concat(greatWorks, ";") .. " culture_cities=" .. table.concat(cultureCities, ";")
        if state ~= previous then
            print("[LEKMOD_UI_OBSERVE] run=__TEST_RUN__ context=" .. ContextPtr:GetID() .. " state=" .. state)
            previous = state
        end
    end)
end
