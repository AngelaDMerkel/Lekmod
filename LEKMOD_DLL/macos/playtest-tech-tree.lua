-- Appended inside the real TechTree context; tests callbacks, not physical input.
do
    local pending, elapsed, announced = false, 0, false
    LuaEvents.LekmodFunctionalTech.Add(function()
        pending, elapsed, announced = true, 0, false
        Events.SerialEventGameMessagePopup({Type = ButtonPopupTypes.BUTTONPOPUP_TECH_TREE,
            Data1 = -1, Data2 = -1, Data3 = -1})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not pending then return end
        elapsed = elapsed + dt
        if __TEST_CAPTURE_PANELS__ then
            if elapsed >= 1 and not announced then
                announced = true
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=tech-tree")
            end
            if elapsed < 10 then return end
        end
        if elapsed < 2 then return end
        pending = false
        local ok, err = pcall(function()
            assert(not ContextPtr:IsHidden(), "tech tree did not open")
            assert(not Controls.CloseButton:IsHidden(), "tech-tree close button is hidden")
            local size = Controls.CloseButton:GetSize()
            assert(size.x > 0 and size.y > 0, "tech-tree close button has no area")
            OnCloseButtonClicked()
            assert(ContextPtr:IsHidden(), "tech-tree close callback did not hide the tree")
        end)
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=tech-tree status=FAIL error=" .. tostring(err))
            OnCloseButtonClicked()
        end
        LuaEvents.LekmodFunctionalTechResult(ok and "PASS" or "FAIL")
    end)
end
