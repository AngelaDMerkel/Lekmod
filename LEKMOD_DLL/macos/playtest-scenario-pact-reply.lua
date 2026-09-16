do
    local target,elapsed
    LuaEvents.LekmodPactProposal.Add(function(player) target,elapsed=player,0 end)
    ContextPtr:SetUpdate(function(dt)
        if ContextPtr:IsHidden() then return end
        if not target then if g_bCanGoBack then OnBack() end;return end
        if g_iAIPlayer~=target or not g_bCanGoBack then return end
        elapsed=elapsed+dt;if elapsed<1 then return end
        local us=Players[Game.GetActivePlayer()];local them=Players[target]
        if not Teams[us:GetTeam()]:IsDefensivePact(them:GetTeam()) then
            if elapsed>8 then
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=pact-reply status=FAIL error=AI-did-not-accept-pact")
                target=nil;OnBack();LuaEvents.LekmodScenarioDiplomacyClose()
            end
            return
        end
        assert(Teams[them:GetTeam()]:IsDefensivePact(us:GetTeam()),"pact only applied in one direction")
        target=nil;LuaEvents.LekmodPactAccepted();OnBack();LuaEvents.LekmodScenarioDiplomacyClose()
    end)
end
