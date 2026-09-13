-- Temporary single-player discussion adapter. Use an enabled normal callback;
-- never force a hidden response or clear GameCore's diplomacy wait directly.
do
    local elapsed = 0
    local handlers = {OnButton1, OnButton2, OnButton3, OnButton4, OnButton5, OnButton6, OnButton7, OnButton8}
    ContextPtr:SetUpdate(function(dt)
        if ContextPtr:IsHidden() then elapsed = 0; return end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        if g_bCanGoBack and type(OnBack) == "function" then
            print("[LEKMOD_TEST] dismiss-leader-discussion turn=" .. Game.GetGameTurn() .. " action=back")
            OnBack()
            return
        end
        for index = 8, 1, -1 do
            local button = Controls["Button" .. index]
            local handler = handlers[index]
            if button and type(handler) == "function" and not button:IsHidden() and not button:IsDisabled() then
                print("[LEKMOD_TEST] dismiss-leader-discussion turn=" .. Game.GetGameTurn() .. " choice=" .. index)
                handler()
                return
            end
        end
    end)
end
