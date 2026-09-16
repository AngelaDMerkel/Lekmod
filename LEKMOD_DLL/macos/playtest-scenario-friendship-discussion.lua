-- Capture the real AI reply event because its UI state remains HUMAN_INVOKED
-- for both acceptance and rejection. Never infer a reply from a timer alone.
do
    local target,waiting,reply,elapsed,verifyOnly,incoming
    local handlers={OnButton1,OnButton2,OnButton3,OnButton4,OnButton5,OnButton6,OnButton7,OnButton8}
    LuaEvents.LekmodFriendshipOpen.Add(function(player,verify)
        target,waiting,reply,elapsed,verifyOnly,incoming=player,false,nil,0,verify,false
    end)
    Events.AILeaderMessage.Add(function(player,state,message,animation,data)
        if target==player and waiting then
            reply={accepted=Players[player]:IsDoF(Game.GetActivePlayer()),state=state,message=message}
        end
    end)
    ContextPtr:SetUpdate(function(dt)
        if ContextPtr:IsHidden() then return end
        elapsed=(elapsed or 0)+dt;if elapsed<1 then return end;elapsed=0
        local ok,err=pcall(function()
            if not target then
                if g_DiploUIState==DiploUIStateTypes.DIPLO_UI_STATE_DISCUSS_WORK_WITH_US then
                    assert(not Controls.Button1:IsHidden() and not Controls.Button1:IsDisabled(),"AI friendship acceptance is unavailable")
                    target,waiting,incoming,reply=g_iAIPlayer,true,true,nil
                    OnButton1()
                elseif g_bCanGoBack then OnBack()
                else
                    for i=8,1,-1 do local b=Controls["Button"..i]
                        if b and handlers[i] and not b:IsHidden() and not b:IsDisabled() then handlers[i]();break end
                    end
                end
                return
            end
            if g_iAIPlayer~=target then return end
            if not waiting then
                if g_DiploUIState~=DiploUIStateTypes.DIPLO_UI_STATE_DISCUSS_HUMAN_INVOKED or g_iInvokedDiscussionMode~=g_iModeDiscussionRoot then return end
                if verifyOnly then
                    assert(Players[Game.GetActivePlayer()]:IsDoF(target) and Players[target]:IsDoF(Game.GetActivePlayer()),"accepted AI offer did not establish mutual friendship")
                    assert(Controls.Button6:IsHidden() or Controls.Button6:IsDisabled(),"duplicate request remains enabled after AI offer")
                    local player=target;target=nil
                    LuaEvents.LekmodFriendshipReply(player,{accepted=true,duplicate_blocked=true,path="AI-offer-Button1-accept-and-human-duplicate-check"})
                    OnBack();LuaEvents.LekmodFriendshipClose();return
                end
                assert(not Controls.Button6:IsHidden() and not Controls.Button6:IsDisabled(),"friendship request button is unavailable")
                waiting=true;OnButton6()
            elseif reply then
                local result=reply
                local active=Players[Game.GetActivePlayer()]
                assert(active:IsDoF(target)==result.accepted,"friendship state differs between the two players")
                result.duplicate_blocked=Controls.Button6:IsHidden() or Controls.Button6:IsDisabled()
                result.path="human-Discuss-Button6-reply-Back-Goodbye"
                local player=target;target=nil
                if incoming then LuaEvents.LekmodFriendshipIncoming(player,result)
                else LuaEvents.LekmodFriendshipReply(player,result) end
                assert(g_bCanGoBack,"friendship reply has no normal Back action")
                OnBack();LuaEvents.LekmodFriendshipClose()
            end
        end)
        if not ok then
            target=nil
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=friendship-dialog status=FAIL error="..tostring(err))
        end
    end)
end
