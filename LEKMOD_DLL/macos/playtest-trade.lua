-- Temporary single-player test adapter. Use the actual trade Refuse/Back
-- handler so its private UI state and game-side refusal bookkeeping stay paired.
do
    local elapsed = 0
    ContextPtr:SetUpdate(function(dt)
        if ContextPtr:IsHidden() then elapsed = 0; return end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        local active = Game.GetActivePlayer()
        local other = UI.GetScratchDeal():GetOtherPlayer(active)
        if other < 0 or other == active or not Players[other] or Players[other]:IsHuman() then return end
        print("[LEKMOD_TEST] dismiss-leader-trade turn=" .. Game.GetGameTurn() .. " player=" .. other)
        OnBack()
    end)
end
