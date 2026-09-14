-- Accepted AI offers can replace the trade screen with a discussion reply.
-- Close only the test's accepted offer using the enabled ordinary Back action.
do
    local target,elapsed
    LuaEvents.LekmodScenarioDiplomacyGift.Add(function(player) target,elapsed=player,0 end)
    ContextPtr:SetUpdate(function(dt)
        if not target or ContextPtr:IsHidden() or g_iAIPlayer~=target then return end
        elapsed=elapsed+dt
        if elapsed<1 or not g_bCanGoBack then return end
        if not Teams[Players[target]:GetTeam()]:HasEmbassyAtTeam(Players[Game.GetActivePlayer()]:GetTeam()) then return end
        target=nil
        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=diplomacy-accepted-reply path=normal-back-callback")
        OnBack()
        -- A human-initiated conversation returns to the root "Anything else?"
        -- screen first. Its ordinary Goodbye callback completes the exit.
        LuaEvents.LekmodScenarioDiplomacyClose()
    end)
end
