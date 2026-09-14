if ContextPtr:GetID()=="DiploTrade" then
    local pending,elapsed,announced,closing,awaiting
    LuaEvents.LekmodScenarioDiplomacyGift.Add(function(player,amount)
        pending,elapsed,announced={player=player,amount=amount},0,false
    end)
    LuaEvents.LekmodScenarioDiplomacyClose.Add(function() closing=true end)
    ContextPtr:SetUpdate(function(dt)
        if awaiting and Teams[Players[awaiting]:GetTeam()]:HasEmbassyAtTeam(Players[Game.GetActivePlayer()]:GetTeam()) then
            awaiting=nil
            LuaEvents.LekmodScenarioDiplomacyClose()
        end
        if closing then
            closing=false
            if not ContextPtr:IsHidden() then
                OnBack()
                LuaEvents.LekmodScenarioDiplomacyResponse("closed")
            end
            return
        end
        if not pending or ContextPtr:IsHidden() then return end
        elapsed=elapsed+dt
        if elapsed<1 or g_iThem~=pending.player then return end
        if __TEST_CAPTURE_PANELS__ and not announced then
            announced=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=diplomacy-trade")
        end
        if __TEST_CAPTURE_PANELS__ and elapsed<10 then return end
        local request=pending;pending=nil
        local ok,err=pcall(function()
            assert(not g_bPVPTrade and g_iUs==Game.GetActivePlayer(), "not the single-player AI trade screen")
            g_Deal:ClearItems()
            g_Deal:SetFromPlayer(g_iUs);g_Deal:SetToPlayer(g_iThem)
            assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_ALLOW_EMBASSY), "embassy gift is not legal")
            PocketAllowEmbassyHandler(1)
            OnPropose(PROPOSE_TYPE)
            awaiting=request.player
            LuaEvents.LekmodScenarioDiplomacyResponse("proposed")
        end)
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=diplomacy-gift status=FAIL error="..tostring(err))
            OnBack()
        end
    end)
end
