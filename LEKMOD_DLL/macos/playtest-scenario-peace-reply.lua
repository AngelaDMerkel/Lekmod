do
    local target,elapsed,message
    LuaEvents.LekmodPeaceRequested.Add(function(player) target,elapsed,message=player,0,nil end)
    Events.AILeaderMessage.Add(function(player,state,text) if target==player then message=text end end)
    ContextPtr:SetUpdate(function(dt)
        if ContextPtr:IsHidden() then return end
        if not target then if g_bCanGoBack then OnBack() end;return end
        if g_iAIPlayer~=target or not g_bCanGoBack or not message then return end
        elapsed=elapsed+dt;if elapsed<1 then return end
        local accepted=not Teams[Game.GetActiveTeam()]:IsAtWar(Players[target]:GetTeam())
        local text=message;target=nil;LuaEvents.LekmodPeaceReply(accepted,text);OnBack();LuaEvents.LekmodPeaceClose()
    end)
end
