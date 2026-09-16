do
    local pending,armed,closing,elapsed
    LuaEvents.LekmodFriendshipOpen.Add(function(player)
        pending,armed,closing,elapsed=player,true,false,0
        Players[player]:DoBeginDiploWithHuman()
    end)
    LuaEvents.LekmodFriendshipClose.Add(function() closing=true end)
    ContextPtr:SetUpdate(function(dt)
        if ContextPtr:IsHidden() then return end
        if closing then closing=false;armed=false;OnReturn();LuaEvents.LekmodFriendshipClosed();return end
        if not pending then
            if not armed and g_DiploUIState==DiploUIStateTypes.DIPLO_UI_STATE_DEFAULT_ROOT then OnReturn() end
            return
        end
        elapsed=elapsed+dt;if elapsed<1 or g_iAIPlayer~=pending then return end
        assert(not Controls.DiscussButton:IsHidden() and not Controls.DiscussButton:IsDisabled(),"normal Discuss button is unavailable")
        pending=nil;OnDiscuss()
    end)
end
