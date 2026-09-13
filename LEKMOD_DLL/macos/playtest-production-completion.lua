-- Bounded gameplay-outcome fixture. No resources, production, units, buildings,
-- technologies, or synchronization state are injected. The ordinary human
-- driver makes required decisions and ends at most three turns.
do
    local phase, startTurn, cityID = "init", nil, nil
    local worker, mill = GameInfoTypes.UNIT_WORKER, GameInfoTypes.BUILDING_WATERMILL
    local originalUnits, unitDone, buildingDone = {}, false, false
    local trainedUnits, constructedMill = {}, false
    GameEvents.CityTrained.Add(function(owner, city, unit, gold, faith)
        if owner == 0 and city == cityID and not gold and not faith then
            trainedUnits[unit] = true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=city-trained city=" .. city ..
                " unit=" .. unit .. " gold=false faith=false")
        end
    end)
    GameEvents.CityConstructed.Add(function(owner, city, building, gold, faith)
        if owner == 0 and city == cityID and building == mill and not gold and not faith then
            constructedMill = true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=city-constructed city=" .. city ..
                " building=" .. building .. " gold=false faith=false")
        end
    end)
    local function record(item, detail)
        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=" .. item .. " status=PASS " .. detail)
    end
    local function step(player)
        local city = cityID and player:GetCityByID(cityID) or player:GetCapitalCity()
        assert(city and not city:IsPuppet(), "completion fixture requires a controlled capital")
        local turn = Game.GetGameTurn()
        if phase == "init" then
            assert(city:CanTrain(worker) and city:CanConstruct(mill), "fixture cannot produce Worker and Water Mill")
            assert(city:GetNumRealBuilding(mill) == 0, "Water Mill already exists")
            assert(city:GetUnitProductionTurnsLeft(worker, 0) <= 1, "fixture needs a one-turn Worker")
            assert(city:GetBuildingProductionTurnsLeft(mill, 0) <= 2, "fixture needs a two-turn Water Mill")
            startTurn, cityID = turn, city:GetID()
            for unit in player:Units() do originalUnits[unit:GetID()] = true end
            Game.CityPushOrder(city, OrderTypes.ORDER_TRAIN, worker, false, true, true)
            phase = "append"
            return true
        elseif phase == "append" then
            local kind, id = city:GetOrderFromQueue(0)
            assert(kind == OrderTypes.ORDER_TRAIN and id == worker, "Worker order not applied")
            Game.CityPushOrder(city, OrderTypes.ORDER_CONSTRUCT, mill, false, false, true)
            phase = "verify-queue"
            return true
        elseif phase == "verify-queue" then
            local kind, id = city:GetOrderFromQueue(1)
            assert(city:GetOrderQueueLength() == 2 and kind == OrderTypes.ORDER_CONSTRUCT and id == mill,
                "Water Mill not appended behind Worker")
            print("[LEKMOD_TEST] production-verified turn=" .. turn .. " city=" .. cityID .. " queue=Worker,WaterMill")
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=completion-queue start_turn=" .. startTurn ..
                " city=" .. cityID .. " worker=" .. worker .. " building=" .. mill .. " path=synchronized-orders")
            phase = "wait"
        elseif phase == "done" then
            return true
        end
        for unit in player:Units() do
            if not unitDone and trainedUnits[unit:GetID()] and not originalUnits[unit:GetID()] and unit:GetUnitType() == worker then
                assert(turn > startTurn, "Worker appeared without a completed turn")
                unitDone = true
                record("production-completion-unit", "turn=" .. turn .. " unit=" .. unit:GetID() .. " type=" .. worker)
            end
        end
        if not buildingDone and constructedMill and city:GetNumRealBuilding(mill) == 1 then
            assert(turn > startTurn, "Water Mill appeared without a completed turn")
            buildingDone = true
            record("production-completion-building", "turn=" .. turn .. " city=" .. cityID .. " building=" .. mill)
        end
        if unitDone and buildingDone then
            phase = "done"
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete scope=production-completion")
            return true
        end
        assert(turn - startTurn < 3, "production did not complete within the three-turn fixture")
        return false
    end
    function LekmodProductionCompletionStep(player)
        local ok, pause = pcall(step, player)
        if not ok then
            phase = "done"
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=production-completion status=FAIL error=" .. tostring(pause))
            return true
        end
        return pause
    end
end
