-- Exercise the normal exit confirmation; only a test-scoped event arms it.
do
    local armed, elapsed = false, 0
    LuaEvents.LekmodFunctionalExit.Add(function()
        armed, elapsed = true, 0
        Events.UserRequestClose()
    end)
    ContextPtr:SetUpdate(function(dt)
        if not armed then return end
        elapsed = elapsed + dt
        if elapsed < 2 then return end
        -- Modal presentation is separate from the context's ordinary hidden
        -- flag. Use the same modal API as Aspyr's stock popup code.
        if not UIManager:IsTopModal(ContextPtr) then
            return
        end
        armed = false
        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=exit-confirmed")
        OnYes()
    end)
end
