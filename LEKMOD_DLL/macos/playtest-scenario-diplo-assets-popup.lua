if ContextPtr:GetID()=="DiploTrade" then
    local request,waiting,elapsed,closing
    LuaEvents.LekmodDiplomacyAssets.Add(function(r) request=r;elapsed=0;waiting=nil;closing=false end)
    LuaEvents.LekmodScenarioDiplomacyClose.Add(function() closing=true end)
    ContextPtr:SetUpdate(function(dt)
        if waiting then
            local us=Players[Game.GetActivePlayer()];local them=Players[waiting.player]
            local accepted=false
            if waiting.kind=="assets" then accepted=us:GetGoldPerTurnFromDiplomacy()==waiting.gpt_before-1 and us:GetNumResourceAvailable(waiting.resource,true)==waiting.resource_before-1
            elseif waiting.kind=="embassies" then accepted=Teams[us:GetTeam()]:HasEmbassyAtTeam(them:GetTeam()) and Teams[them:GetTeam()]:HasEmbassyAtTeam(us:GetTeam())
            else accepted=Teams[us:GetTeam()]:IsAllowsOpenBordersToTeam(them:GetTeam()) end
            if accepted then
                LuaEvents.LekmodDiplomacyAssetsAccepted(waiting.kind)
                waiting=nil;LuaEvents.LekmodScenarioDiplomacyClose()
            end
        end
        if closing and not ContextPtr:IsHidden() then closing=false;OnBack();return end
        if not request or ContextPtr:IsHidden() or g_iThem~=request.player then return end
        elapsed=elapsed+dt;if elapsed<1 then return end
        local r=request;request=nil
        local ok,err=pcall(function()
            assert(not g_bPVPTrade and g_iUs==Game.GetActivePlayer(),"not a single-player AI deal")
            g_Deal:ClearItems();g_Deal:SetFromPlayer(g_iUs);g_Deal:SetToPlayer(g_iThem)
            if r.kind=="assets" then
                assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_RESOURCES,r.resource,1,g_iDealDuration),"luxury gift is not legal")
                assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_GOLD_PER_TURN,1,g_iDealDuration),"GPT gift is not legal")
                PocketResourceHandler(1,r.resource);PocketGoldPerTurnHandler(1)
                ChangeGoldPerTurnAmount("1",Controls.UsGoldPerTurnAmount)
            elseif r.kind=="embassies" then
                assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_ALLOW_EMBASSY) and g_Deal:IsPossibleToTradeItem(g_iThem,g_iUs,TradeableItems.TRADE_ITEM_ALLOW_EMBASSY),"mutual embassies unavailable")
                PocketAllowEmbassyHandler(1);PocketAllowEmbassyHandler(0)
            else
                assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_OPEN_BORDERS,g_iDealDuration),"open borders gift unavailable")
                PocketOpenBordersHandler(1)
            end
            OnPropose(PROPOSE_TYPE);waiting=r
            LuaEvents.LekmodDiplomacyAssetsProposed(r.kind)
        end)
        if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=diplomacy-assets status=FAIL error="..tostring(err));OnBack() end
    end)
end
