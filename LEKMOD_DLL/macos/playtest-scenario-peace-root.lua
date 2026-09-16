do
    local target,elapsed,closing,armed
    LuaEvents.LekmodPeaceOpen.Add(function(player) target,elapsed,closing,armed=player,0,false,true;Players[player]:DoBeginDiploWithHuman() end)
    LuaEvents.LekmodPeaceClose.Add(function() closing=true end)
    ContextPtr:SetUpdate(function(dt)
        if ContextPtr:IsHidden() then return end
        if closing then closing=false;armed=false;OnReturn();LuaEvents.LekmodPeaceClosed();return end
        if not target then if not armed and g_DiploUIState==DiploUIStateTypes.DIPLO_UI_STATE_DEFAULT_ROOT then OnReturn() end;return end
        elapsed=elapsed+dt;if elapsed<1 or g_iAIPlayer~=target then return end
        assert(Teams[Game.GetActiveTeam()]:IsAtWar(g_iAITeam),"peace request opened while not at war")
        assert(not Controls.WarButton:IsHidden() and not Controls.WarButton:IsDisabled(),"normal Negotiate Peace button unavailable")
        local player=target;target=nil;LuaEvents.LekmodPeaceRequested(player);OnWarOrPeace()
    end)
end
