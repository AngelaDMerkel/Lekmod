if ContextPtr:GetID()=="DiploTrade" then
    local target,elapsed,proposed,reply
    LuaEvents.LekmodPeaceRequested.Add(function(player) target,elapsed,proposed,reply=player,0,false,nil end)
    Events.AILeaderMessage.Add(function(player,state,message) if target==player and proposed then reply={state=state,message=message} end end)
    ContextPtr:SetUpdate(function(dt)
        if not target or ContextPtr:IsHidden() or g_iThem~=target then return end
        elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
        local ok,err=pcall(function()
            if proposed then
                if reply and Teams[Game.GetActiveTeam()]:IsAtWar(Players[target]:GetTeam()) then
                    local r=reply;target=nil;LuaEvents.LekmodPeaceReply(false,r.message);OnBack();LuaEvents.LekmodPeaceClose()
                end
                return
            end
            assert(not g_bPVPTrade and not g_bTradeReview,"peace proposal is not a new single-player deal")
            local count=0;g_Deal:ResetIterator()
            while true do local kind,duration=g_Deal:GetNextItem();if kind==nil then break end
                assert(kind==TradeableItems.TRADE_ITEM_PEACE_TREATY or kind==TradeableItems.TRADE_ITEM_THIRD_PARTY_PEACE,"white-peace fixture contains an asset concession")
                if kind==TradeableItems.TRADE_ITEM_PEACE_TREATY then assert(duration==5,"AI peace terms are not the configured five turns");count=count+1 end
            end
            assert(count==2,"normal peace negotiation did not supply bilateral terms")
            proposed=true;OnPropose(PROPOSE_TYPE);LuaEvents.LekmodPeaceProposed()
        end)
        if not ok then target=nil;print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=peace-dialog status=FAIL error="..tostring(err));OnBack() end
    end)
end
