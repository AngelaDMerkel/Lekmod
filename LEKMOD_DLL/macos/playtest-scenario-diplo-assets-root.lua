do
    local pending,elapsed,closing,armed
    LuaEvents.LekmodScenarioDiplomacyOpen.Add(function(player)
        pending,elapsed,armed=player,0,true
        Players[player]:DoBeginDiploWithHuman()
    end)
    LuaEvents.LekmodScenarioDiplomacyClose.Add(function() closing=true end)
    ContextPtr:SetUpdate(function(dt)
        if closing then
            if ContextPtr:IsHidden() then return end
            closing=false;armed=false
            OnReturn()
            LuaEvents.LekmodScenarioDiplomacyResponse("closed")
            return
        end
        if not pending then
            if not armed and not ContextPtr:IsHidden() then OnReturn() end
            return
        end
        if ContextPtr:IsHidden() then return end
        elapsed=elapsed+dt
        if elapsed<1 or g_iAIPlayer~=pending then return end
        pending=nil
        OnTrade()
        LuaEvents.LekmodScenarioDiplomacyResponse("open")
    end)
end
