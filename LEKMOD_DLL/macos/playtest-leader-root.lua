-- Temporary test adapter for ordinary leader greetings. Invoke the native
-- screen's Back callback; do not clear game-core diplomacy wait flags directly.
do
    local elapsed = 0
    ContextPtr:SetUpdate(function(dt)
        if ContextPtr:IsHidden() then elapsed = 0; return end
        if g_DiploUIState ~= DiploUIStateTypes.DIPLO_UI_STATE_DEFAULT_ROOT then return end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        print("[LEKMOD_TEST] dismiss-leader turn=" .. Game.GetGameTurn() .. " player=" .. g_iAIPlayer)
        OnReturn()
    end)
end
