-- Temporary adapter for a whitelist of informational awards/rankings. Preserve
-- the actual close handler and show/hide semaphore bookkeeping, not game state.
do
    local elapsed = 0
    local originalUpdate = OnUpdate
    local close = OnClose or OnCloseButtonClicked
    assert(type(close) == "function", "test popup has no normal close callback")
    function OnUpdate(dt)
        if originalUpdate then originalUpdate(dt) end
        if ContextPtr:IsHidden() then elapsed = 0; return end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        print("[LEKMOD_TEST] dismiss-info-popup turn=" .. Game.GetGameTurn())
        close()
    end
    ContextPtr:SetUpdate(OnUpdate)
end
