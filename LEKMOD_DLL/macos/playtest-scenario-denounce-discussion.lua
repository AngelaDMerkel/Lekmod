-- Uses the shared discussion entry/exit adapter, then the actual denouncement
-- button and both confirmation callbacks.
do
    local target,phase,elapsed,reply,before
    LuaEvents.LekmodFriendshipOpen.Add(function(player) target,phase,elapsed,reply=player,"open",0,nil end)
    Events.AILeaderMessage.Add(function(player,state,message)
        if target==player and phase=="reply" then reply={state=state,message=message} end
    end)
    ContextPtr:SetUpdate(function(dt)
        if not target or ContextPtr:IsHidden() or g_iAIPlayer~=target then return end
        elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
        local ok,err=pcall(function()
            local active=Players[Game.GetActivePlayer()]
            if phase=="open" then
                if g_DiploUIState~=DiploUIStateTypes.DIPLO_UI_STATE_DISCUSS_HUMAN_INVOKED or g_iInvokedDiscussionMode~=g_iModeDiscussionRoot then return end
                assert(not Controls.Button7:IsHidden() and not Controls.Button7:IsDisabled(),"normal denouncement button unavailable")
                before={friendship=active:IsDoF(target),embassy=Teams[active:GetTeam()]:HasEmbassyAtTeam(Players[target]:GetTeam())}
                OnButton7();phase="cancel"
            elseif phase=="cancel" then
                assert(not Controls.DenounceConfirm:IsHidden(),"denouncement confirmation did not open")
                OnDenounceConfirmNo()
                assert(Controls.DenounceConfirm:IsHidden() and not active:IsDenouncedPlayer(target),"No did not cancel denouncement")
                assert(active:IsDoF(target)==before.friendship and Teams[active:GetTeam()]:HasEmbassyAtTeam(Players[target]:GetTeam())==before.embassy,"No changed the existing friendship or embassy")
                LuaEvents.LekmodDenounceCancelled()
                OnButton7();phase="confirm"
            elseif phase=="confirm" then
                assert(not Controls.DenounceConfirm:IsHidden(),"second denouncement confirmation did not open")
                phase="reply";OnDenonceConfirmYes()
            elseif phase=="reply" and reply then
                assert(active:IsDenouncedPlayer(target),"confirmed denouncement did not reach engine state")
                local result=reply;target=nil
                LuaEvents.LekmodDenounceConfirmed(result)
                assert(g_bCanGoBack,"denouncement reply has no normal Back action")
                OnBack();LuaEvents.LekmodFriendshipClose()
            end
        end)
        if not ok then target=nil;print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=denouncement-dialog status=FAIL error="..tostring(err)) end
    end)
end
