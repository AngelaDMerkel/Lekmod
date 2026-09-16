if ContextPtr:GetID()=="DiploTrade" then
    local target,elapsed,phase,message,negotiated
    LuaEvents.LekmodPactProposal.Add(function(player) target,elapsed,phase,message,negotiated=player,0,"prepare",nil,false end)
    LuaEvents.LekmodPactAccepted.Add(function() target=nil end)
    Events.AILeaderMessage.Add(function(player,state,text)
        if target==player and phase~="prepare" then message={state=state,text=text} end
    end)
    ContextPtr:SetUpdate(function(dt)
        if not target or ContextPtr:IsHidden() or g_iThem~=target then return end
        elapsed=elapsed+dt;if elapsed<1 then return end
        local player=target
        local ok,err=pcall(function()
            if phase=="waiting" then
                if not message then return end
                assert(not negotiated,"AI rejected the negotiated non-aggression terms")
                assert(not Controls.WhatWillMakeThisWorkButton:IsHidden() and not Controls.WhatWillMakeThisWorkButton:IsDisabled(),"normal negotiation button is unavailable")
                negotiated=true;phase="equalizing";message=nil;elapsed=0
                OnEqualizeDeal();return
            elseif phase=="equalizing" then
                if not message then return end
                local items=0;g_Deal:ResetIterator()
                while true do local kind,duration=g_Deal:GetNextItem();if kind==nil then break end
                    assert(kind==TradeableItems.TRADE_ITEM_DEFENSIVE_PACT and duration==10,"AI counteroffer requires different terms; this fixture does not approve them")
                    items=items+1
                end
                assert(items==2,"AI did not offer the requested bilateral pact")
                phase="waiting";message=nil;elapsed=0
                OnPropose(Controls.ProposeButton:GetVoid1());return
            end
            assert(not g_bPVPTrade and not g_bTradeReview,"not a new single-player AI proposal")
            assert(Controls.UsPocketResearchAgreement:IsDisabled() and Controls.ThemPocketResearchAgreement:IsDisabled(),"configured-off research agreement is enabled in the actual UI")
            LuaEvents.LekmodPactResearchDisabled(Locale.ConvertTextKey("TXT_KEY_DIPLO_DEF_PACT"))
            g_Deal:ClearItems();g_Deal:SetFromPlayer(g_iUs);g_Deal:SetToPlayer(g_iThem)
            assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_DEFENSIVE_PACT,10),"non-aggression pact is not legal")
            assert(not Controls.UsPocketDefensivePact:IsHidden() and not Controls.UsPocketDefensivePact:IsDisabled(),"actual pact button unavailable")
            PocketDefensivePactHandler(1)
            local items=0;g_Deal:ResetIterator()
            while true do local kind,duration=g_Deal:GetNextItem();if kind==nil then break end
                assert(kind==TradeableItems.TRADE_ITEM_DEFENSIVE_PACT and duration==10,"pact callback did not create the configured ten-turn terms")
                items=items+1
            end
            assert(items==2,"pact is not bilateral")
            phase="waiting";message=nil;elapsed=0
            OnPropose(PROPOSE_TYPE)
            LuaEvents.LekmodPactProposed(player)
        end)
        if not ok then target=nil;print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=pact-dialog status=FAIL error="..tostring(err));OnBack() end
    end)
end
