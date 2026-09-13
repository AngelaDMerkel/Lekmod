-- Appended inside the real standard ProductionPopup context for an isolated test.
do
    local pending, elapsed, announced
    LuaEvents.LekmodFunctionalProduction.Add(function(cityID, category)
        pending, elapsed, announced = {city = cityID, category = category}, 0, false
        Events.SerialEventGameMessagePopup({Type = ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION,
            Data1 = cityID, Data2 = -1, Data3 = -1, Option1 = false, Option2 = false})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not pending then return end
        elapsed = elapsed + dt
        if __TEST_CAPTURE_PANELS__ then
            if elapsed >= 1 and not announced then
                announced = true
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=production-" .. pending.category)
            end
            if elapsed < 10 then return end
        end
        if elapsed < 1 then return end
        local request = pending
        pending = nil
        local ok, err = pcall(function()
            assert(not ContextPtr:IsHidden(), "production popup did not open")
            local city = GetCurrentCity()
            assert(city and city:GetID() == request.city, "production popup selected the wrong city")
            assert(not Controls.CloseButton:IsHidden(), "production close button is hidden")
            local chosen, purchaseEnum, order
            if request.category == "unit" then
                for item in GameInfo.Units() do
                    if city:CanTrain(item.ID) then chosen = item.ID; break end
                end
                purchaseEnum, order = g_CONSTRUCT_UNIT, OrderTypes.ORDER_TRAIN
            elseif request.category == "process" then
                for item in GameInfo.Processes() do
                    if city:CanMaintain(item.ID) then chosen = item.ID; break end
                end
                purchaseEnum, order = g_MAINTAIN_PROCESS, OrderTypes.ORDER_MAINTAIN
            else
                for item in GameInfo.Buildings() do
                    local class = GameInfo.BuildingClasses[item.BuildingClass]
                    local wonder = class and (class.MaxGlobalInstances == 1 or class.MaxPlayerInstances == 1 or class.MaxTeamInstances == 1)
                    if wonder == (request.category == "wonder") and city:CanConstruct(item.ID) then
                        chosen = item.ID; break
                    end
                end
                purchaseEnum, order = g_CONSTRUCT_BUILDING, OrderTypes.ORDER_CONSTRUCT
            end
            if not chosen then
                OnClose()
                LuaEvents.LekmodFunctionalProductionResult(request.category, "SKIP", -1, -1)
                return
            end
            -- The exact callback registered by the actual rendered production entries.
            ProductionSelected(purchaseEnum, chosen)
            assert(ContextPtr:IsHidden(), "production popup failed to close after selection")
            LuaEvents.LekmodFunctionalProductionResult(request.category, "PASS", order, chosen)
        end)
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=production-" .. request.category .. " status=FAIL error=" .. tostring(err))
            OnClose()
            LuaEvents.LekmodFunctionalProductionResult(request.category, "FAIL", -1, -1)
        end
    end)
end
