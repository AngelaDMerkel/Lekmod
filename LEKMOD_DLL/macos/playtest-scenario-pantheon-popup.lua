-- Temporary adapter inside Aspyr's real pantheon context.
do
    local pending, elapsed, announced = false, 0, false
    LuaEvents.LekmodScenarioPantheon.Add(function()
        pending, elapsed, announced = true, 0, false
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_FOUND_PANTHEON, Data2=1})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not pending then return end
        elapsed=elapsed+dt
        if elapsed<1 or ContextPtr:IsHidden() then return end
        if __TEST_CAPTURE_PANELS__ and not announced then
            announced=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=pantheon")
        end
        if __TEST_CAPTURE_PANELS__ and elapsed<10 then return end
        pending=false
        local ok,err=pcall(function()
            assert(Players[Game.GetActivePlayer()]:CanCreatePantheon(true), "pantheon not legally available")
            local beliefs=Game.GetAvailablePantheonBeliefs()
            assert(#beliefs>0, "no available pantheon belief")
            SelectPantheon(beliefs[1])
            assert(not Controls.ChooseConfirm:IsHidden(), "pantheon confirmation did not open")
            OnYes()
            LuaEvents.LekmodScenarioReligionResponse("pantheon", beliefs[1])
        end)
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=pantheon status=FAIL error="..tostring(err))
            OnClose()
        end
    end)
end
