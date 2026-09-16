-- Temporary ActionInfoPanel test driver. Keep player 0 human and use the real
-- end-turn button handler. This covers the human/AI handoff, not mouse hitboxes.
do
    LEKMOD_TEST_DRIVER_GENERATION = (LEKMOD_TEST_DRIVER_GENERATION or 0) + 1
    local generation = LEKMOD_TEST_DRIVER_GENERATION
    local stopped = false
    local elapsed, lastTurn = 0, -1
    local pendingProduction = nil
    local observedProduction = {}
    local pendingPolicy = nil
    local pendingIdeology = nil
    local firstProduction = true
    local lastBlockedTurn = -1
    local leagueNotificationWaits = 0
    local techAwardVisible = false
    local techAwardCooldown = 0
    LuaEvents.LekmodTestTechAwardVisible.Add(function(visible)
        techAwardVisible, techAwardCooldown = visible, 2
    end)
    local originalUpdate = OnSoftPromptUpdate
    if not LEKMOD_TEST_INIT_HOOK then
        Events.SequenceGameInitComplete.Add(function() LEKMOD_TEST_READY = true end)
        LEKMOD_TEST_INIT_HOOK = true
    end

    local function unitAction(unit, actionType)
        UI.SelectUnit(unit)
        for actionID = 0, #GameInfoActions do
            local action = GameInfoActions[actionID]
            if action and action.Type == actionType then
                if Game.CanHandleAction(actionID) then
                    Game.HandleAction(actionID)
                    return
                end
                -- A newly produced unit may be stacked with a waiting unit;
                -- Civ V correctly refuses Skip until that stack is resolved.
                if actionType == "MISSION_SKIP" then
                    for direction = 0, 5 do
                        local plot = Map.PlotDirection(unit:GetX(), unit:GetY(), direction)
                        -- Occupancy alone is not illegality: a civilian and a
                        -- military unit may share a tile. The engine checks
                        -- stacking, terrain, diplomacy and movement eligibility.
                        if plot and not plot:IsWater() and
                           unit:CanMoveOrAttackInto(plot, 0, 1) then
                            Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,
                                MissionTypes.MISSION_MOVE_TO, plot:GetX(), plot:GetY(), 0, false, false)
                            print("[LEKMOD_TEST] moved-stacked-unit id=" .. unit:GetID() ..
                                " target=" .. plot:GetX() .. "," .. plot:GetY())
                            return
                        end
                    end
                end
                error("unit action is unavailable: " .. actionType)
            end
        end
        error("unit action is missing: " .. actionType)
    end

    local function step()
        if not LEKMOD_TEST_READY or Game.IsProcessingMessages() then return end
        assert(Game.GetActivePlayer() == 0, "active player is not the test human")
        assert(Game.GetAIAutoPlay() == 0, "autoplay unexpectedly enabled")
        local player = Players[0]
        assert(player:IsHuman(), "test player is not human")
        if not player:IsTurnActive() then return end
        -- Award popups pause ordinary notification updates. Their own adapter
        -- uses Continue; do not spend a synchronized-result timeout while a
        -- batch of announced fixture technologies is still being presented.
        if techAwardVisible then return end
        if techAwardCooldown > 0 then techAwardCooldown = techAwardCooldown - 1; return end
        local turn = Game.GetGameTurn()
        if turn ~= lastTurn then
            print("[LEKMOD_TEST] human-active turn=" .. turn .. " cities=" .. player:GetNumCities())
            lastTurn = turn
        end
        if LekmodProductionCompletionStep and LekmodProductionCompletionStep(player) then return end

        local greeting = UIManager:GetVisibleNamedContext("CityStateGreetingPopup")
        if greeting then
            -- This is the complete stock Close handler. Dequeue dispatches the
            -- original show/hide callback and balances its turn semaphore.
            UIManager:DequeuePopup(greeting)
            print("[LEKMOD_TEST] dismiss-city-state-greeting turn=" .. turn)
            return
        end

        if pendingPolicy then
            local applied = pendingPolicy.branch and player:IsPolicyBranchUnlocked(pendingPolicy.id) or
                            (not pendingPolicy.branch and player:HasPolicy(pendingPolicy.id))
            assert(applied, "policy selection was not applied")
            print("[LEKMOD_TEST] policy-verified turn=" .. turn .. " id=" .. pendingPolicy.id)
            pendingPolicy = nil
        end
        if pendingIdeology then
            assert(player:GetLateGamePolicyTree() == pendingIdeology, "ideology choice was not applied")
            print("[LEKMOD_TEST] ideology-verified turn=" .. turn .. " branch=" .. pendingIdeology)
            pendingIdeology = nil
        end

        for unit in player:Units() do
            if unit:IsPromotionReady() and not unit:IsBusy() then
                UI.SelectUnit(unit)
                for actionID = 0, #GameInfoActions do
                    local action = GameInfoActions[actionID]
                    if action and action.SubType == ActionSubTypes.ACTIONSUBTYPE_PROMOTION and
                       Game.CanHandleAction(actionID) then
                        Game.HandleAction(actionID)
                        print("[LEKMOD_TEST] promoted-unit turn=" .. turn .. " id=" .. unit:GetID() .. " action=" .. action.Type)
                        return
                    end
                end
                error("promotion-ready unit has no available promotion action")
            end
        end

        if pendingProduction then
            local city = player:GetCityByID(pendingProduction.city)
            local actual = city and (pendingProduction.order == OrderTypes.ORDER_TRAIN and
                city:GetProductionUnit() or city:GetProductionBuilding())
            assert(actual == pendingProduction.item,
                "production order did not reach the city queue")
            print("[LEKMOD_TEST] production-verified turn=" .. turn .. " city=" .. city:GetID())
            observedProduction[city:GetID()] = true
            pendingProduction = nil
        end

        if player:GetNumCities() == 0 then
            for unit in player:Units() do
                if unit:CanFound(unit:GetPlot()) then
                    unitAction(unit, "MISSION_FOUND")
                    print("[LEKMOD_TEST] founded-city turn=" .. turn)
                    return
                end
            end
            error("no city and no settler can found at the starting location")
        end

        for city in player:Cities() do
            if city:GetOrderQueueLength() > 0 and not observedProduction[city:GetID()] then
                local kind, id = city:GetOrderFromQueue(0)
                local actual
                if kind == OrderTypes.ORDER_TRAIN then actual = city:GetProductionUnit()
                elseif kind == OrderTypes.ORDER_CONSTRUCT then actual = city:GetProductionBuilding()
                elseif kind == OrderTypes.ORDER_CREATE then actual = city:GetProductionProject()
                elseif kind == OrderTypes.ORDER_MAINTAIN then actual = city:GetProductionProcess() end
                assert(actual == id, "inherited order does not match active production")
                observedProduction[city:GetID()] = true
                print("[LEKMOD_TEST] production-inherited turn=" .. turn .. " city=" .. city:GetID() .. " order=" .. kind .. " item=" .. id)
            end
            if city:GetOrderQueueLength() == 0 then
                -- Exercise real building queues and avoid filling the capital
                -- with an endless stream of scouts during a long stress run.
                if not firstProduction then
                    for _, name in ipairs({"BUILDING_MONUMENT", "BUILDING_GRANARY", "BUILDING_LIBRARY",
                        "BUILDING_WATERMILL", "BUILDING_BARRACKS", "BUILDING_WALLS", "BUILDING_COLOSSEUM",
                        "BUILDING_MARKET", "BUILDING_WORKSHOP", "BUILDING_GARDEN", "BUILDING_UNIVERSITY"}) do
                        local building = GameInfo.Buildings[name]
                        if building and city:CanConstruct(building.ID) then
                            Game.CityPushOrder(city, OrderTypes.ORDER_CONSTRUCT, building.ID, false, true, true)
                            pendingProduction = {city = city:GetID(), order = OrderTypes.ORDER_CONSTRUCT, item = building.ID}
                            return
                        end
                    end
                end
                local unitType
                for _, name in ipairs({"UNIT_SCOUT", "UNIT_WORKER"}) do
                    local id = GameInfoTypes[name]
                    if id and city:CanTrain(id) then unitType = id; break end
                end
                assert(unitType, "city cannot produce a legal test scout or worker")
                Game.CityPushOrder(city, OrderTypes.ORDER_TRAIN, unitType, false, true, true)
                pendingProduction = {city = city:GetID(), order = OrderTypes.ORDER_TRAIN, item = unitType}
                firstProduction = false
                return
            end
        end

        local freeTechs = player:GetNumFreeTechs()
        if player:GetCurrentResearch() == -1 or freeTechs > 0 then
            for tech in GameInfo.Technologies() do
                if (freeTechs > 0 and player:CanResearchForFree(tech.ID)) or
                   (freeTechs == 0 and player:CanResearch(tech.ID)) then
                    Network.SendResearch(tech.ID, freeTechs, -1, false)
                    print("[LEKMOD_TEST] selected-research turn=" .. turn .. " tech=" .. tech.Type)
                    return
                end
            end
            error("no available research choice")
        end

        for unit in player:Units() do
            if unit:IsReadyToMove() and not unit:IsBusy() then
                local info = GameInfo.Units[unit:GetUnitType()]
                if info and info.Class == "UNITCLASS_SCOUT" then
                    UI.SelectUnit(unit)
                    for actionID = 0, #GameInfoActions do
                        local action = GameInfoActions[actionID]
                        if action and action.Type == "AUTOMATE_EXPLORE" and Game.CanHandleAction(actionID) then
                            Game.HandleAction(actionID)
                            print("[LEKMOD_TEST] scout-auto-explore turn=" .. turn .. " id=" .. unit:GetID())
                            return
                        end
                    end
                end
                unitAction(unit, "MISSION_SKIP")
                return
            end
        end
        local blocking = player:GetEndTurnBlockingType()
        if blocking == EndTurnBlockingTypes.ENDTURN_BLOCKING_CHOOSE_IDEOLOGY then
            assert(player:GetLateGamePolicyTree() == -1, "ideology prompt appeared after an ideology was chosen")
            -- Freedom is one of the three choices in Aspyr's ChooseIdeologyPopup.
            -- Submit its normal network choice, then verify the resulting tree;
            -- never dismiss the required decision or clear its blocking flag.
            local branch = GameInfo.PolicyBranchTypes.POLICY_BRANCH_FREEDOM
            assert(branch, "fixture has no Freedom ideology")
            Network.SendIdeologyChoice(player:GetID(), branch.ID)
            pendingIdeology = branch.ID
            print("[LEKMOD_TEST] selected-ideology turn=" .. turn .. " branch=" .. branch.ID .. " path=network-choice")
            return
        end
        if blocking == EndTurnBlockingTypes.ENDTURN_BLOCKING_CITY_RANGE_ATTACK then
            local width = Map.GetGridSize()
            for city in player:Cities() do
                if city:CanRangeStrikeNow() then
                    for dx = -3, 3 do
                        for dy = -3, 3 do
                            local plot = Map.GetPlot((city:GetX() + dx) % width, city:GetY() + dy)
                            if plot and not plot:IsFighting() and city:CanRangeStrikeAt(plot:GetX(), plot:GetY()) then
                                UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_CITY_RANGE_ATTACK)
                                UI.ClearSelectionList()
                                UI.SelectCity(city)
                                Game.SelectedCitiesGameNetMessage(GameMessageTypes.GAMEMESSAGE_DO_TASK,
                                    TaskTypes.TASK_RANGED_ATTACK, plot:GetX(), plot:GetY())
                                Events.SpecificCityInfoDirty(0, city:GetID(), CityUpdateTypes.CITY_UPDATE_TYPE_BANNER)
                                UI.ClearSelectedCities()
                                UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_SELECTION)
                                print("[LEKMOD_TEST] city-range-attack turn=" .. turn .. " x=" .. plot:GetX() .. " y=" .. plot:GetY())
                                return
                            end
                        end
                    end
                end
            end
            error("city ranged-attack prompt has no legal target")
        end
        if blocking == EndTurnBlockingTypes.ENDTURN_BLOCKING_POLICY or
           blocking == EndTurnBlockingTypes.ENDTURN_BLOCKING_FREE_POLICY then
            for policy in GameInfo.Policies() do
                if not player:HasPolicy(policy.ID) and player:CanAdoptPolicy(policy.ID) then
                    Network.SendUpdatePolicies(policy.ID, true, true)
                    pendingPolicy = {id = policy.ID, branch = false}
                    print("[LEKMOD_TEST] selected-policy turn=" .. turn .. " policy=" .. policy.Type)
                    return
                end
            end
            for branch in GameInfo.PolicyBranchTypes() do
                if not player:IsPolicyBranchUnlocked(branch.ID) and player:CanUnlockPolicyBranch(branch.ID) then
                    Network.SendUpdatePolicies(branch.ID, false, true)
                    pendingPolicy = {id = branch.ID, branch = true}
                    print("[LEKMOD_TEST] selected-policy-branch turn=" .. turn .. " branch=" .. branch.Type)
                    return
                end
            end
            error("policy prompt has no valid choice")
        end
        if blocking == EndTurnBlockingTypes.ENDTURN_BLOCKING_LEAGUE_CALL_FOR_PROPOSALS then
            local league = assert(Game.GetActiveLeague(), "proposal prompt has no active league")
            if not league:CanPropose(player:GetID()) then
                leagueNotificationWaits = leagueNotificationWaits + 1
                assert(leagueNotificationWaits <= 8, "spent proposal notification did not clear")
                return
            end
            leagueNotificationWaits = 0
            for resolution in GameInfo.Resolutions() do
                if league:CanProposeEnact(resolution.ID, player:GetID(), -1) then
                    Network.SendLeagueProposeEnact(league:GetID(), resolution.ID, player:GetID(), -1)
                    print("[LEKMOD_TEST] selected-congress-proposal turn=" .. turn .. " resolution=" .. resolution.Type)
                    return
                end
            end
            for _, resolution in ipairs(league:GetActiveResolutions()) do
                if league:CanProposeRepeal(resolution.ID, player:GetID()) then
                    Network.SendLeagueProposeRepeal(league:GetID(), resolution.ID, player:GetID())
                    print("[LEKMOD_TEST] selected-congress-repeal turn=" .. turn .. " resolution=" .. resolution.ID)
                    return
                end
            end
            error("proposal prompt has no legal target-free proposal or repeal")
        end
        if blocking == EndTurnBlockingTypes.ENDTURN_BLOCKING_LEAGUE_CALL_FOR_VOTES then
            local league = assert(Game.GetActiveLeague(), "vote prompt has no active league")
            local votes = league:GetRemainingVotesForMember(player:GetID())
            if not league:CanVote(player:GetID()) or votes <= 0 then
                leagueNotificationWaits = leagueNotificationWaits + 1
                assert(leagueNotificationWaits <= 8, "spent voting notification did not clear")
                return
            end
            leagueNotificationWaits = 0
            Network.SendLeagueVoteAbstain(league:GetID(), player:GetID(), votes)
            print("[LEKMOD_TEST] congress-abstain turn=" .. turn .. " votes=" .. votes)
            return
        end
        if blocking ~= EndTurnBlockingTypes.NO_ENDTURN_BLOCKING_TYPE then
            print("[LEKMOD_TEST] human-blocked turn=" .. turn .. " type=" .. blocking)
            return
        end
        leagueNotificationWaits = 0
        if not UI.CanEndTurn() and turn ~= lastBlockedTurn then
            lastBlockedTurn = turn
            for _, name in ipairs({"TechAwardPopup", "TechPopup", "TechTree", "SocialPolicyPopup", "CityView"}) do
                local context = UIManager:GetVisibleNamedContext(name)
                print("[LEKMOD_TEST] visible-context turn=" .. turn .. " name=" .. name .. " visible=" .. tostring(context ~= nil))
            end
        end
        print("[LEKMOD_TEST] end-turn-click turn=" .. turn)
        if LekmodScenarioBeforeEndTurn then LekmodScenarioBeforeEndTurn(player,turn) end
        OnEndTurnClicked()
    end

    if LEKMOD_TEST_EXTERNAL_DRIVER then
        -- The scenario owns the update loop and explicitly grants each step.
        -- All ordinary decision checks and the real end-turn handler remain.
        LekmodScenarioHumanTurn=step
    else
    ContextPtr:SetUpdate(function(dt)
        if originalUpdate then originalUpdate(dt) end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        include("LekmodTestCommands.lua")
        if generation ~= LEKMOD_TEST_DRIVER_GENERATION or stopped then return end
        local ok, err = pcall(step)
        if not ok then
            stopped = true
            print("[LEKMOD_TEST] ERROR " .. tostring(err))
            Controls.EndTurnText:SetText("TEST ERROR: " .. tostring(err))
        end
    end)
    end
end
