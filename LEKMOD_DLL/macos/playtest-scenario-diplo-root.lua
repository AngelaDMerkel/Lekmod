do
    local pending,elapsed,closing
    LuaEvents.LekmodScenarioDiplomacyOpen.Add(function(player)
        pending,elapsed=player,0
        Players[player]:DoBeginDiploWithHuman()
    end)
    LuaEvents.LekmodScenarioDiplomacyClose.Add(function() closing=true end)
    ContextPtr:SetUpdate(function(dt)
        if closing then
            if ContextPtr:IsHidden() then return end
            closing=false
            OnReturn()
            LuaEvents.LekmodScenarioDiplomacyResponse("closed")
            return
        end
        if not pending or ContextPtr:IsHidden() then return end
        elapsed=elapsed+dt
        if elapsed<1 or g_iAIPlayer~=pending then return end
        pending=nil
        OnTrade()
        LuaEvents.LekmodScenarioDiplomacyResponse("open")
    end)
end
