-- Temporary unattended-test adapter: use the real Continue button callback.
-- The stock award popup ignores UI.SetDontShowPopups and owns a turn semaphore.
do
    local elapsed = 0
    local originalShowHide = ShowHideHandler
    ContextPtr:SetShowHideHandler(function(hidden, initializing)
        originalShowHide(hidden, initializing)
        LuaEvents.LekmodTestTechAwardVisible(not hidden)
    end)
    ContextPtr:SetUpdate(function(dt)
        if ContextPtr:IsHidden() then elapsed = 0; return end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        print("[LEKMOD_TEST] dismiss-tech-award turn=" .. Game.GetGameTurn())
        OnContinueButtonClicked()
    end)
end
