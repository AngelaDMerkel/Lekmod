do
    local request,elapsed,stage
    LuaEvents.LekmodTradeHome.Add(function(id,x,y)
        request={id=id,x=x,y=y};elapsed=0;stage="cancel"
        UI.SelectUnit(Players[Game.GetActivePlayer()]:GetUnitByID(id))
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_CHOOSE_TRADE_UNIT_NEW_HOME,Data1=id})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not request or ContextPtr:IsHidden() or Game.IsProcessingMessages() then return end
        elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
        local ok,err=pcall(function()
            assert(g_iUnitIndex==request.id,"rebase popup selected another unit")
            local player=Players[Game.GetActivePlayer()];local u=assert(player:GetUnitByID(request.id));local valid=false
            for _,p in ipairs(player:GetPotentialTradeUnitNewHomeCity(u)) do if p.X==request.x and p.Y==request.y then valid=true end end
            assert(valid,"requested home is not in actual available choices")
            if stage=="cancel" then
                local x,y=u:GetX(),u:GetY();SelectNewHome(request.x,request.y);OnConfirmNo()
                assert(u:GetX()==x and u:GetY()==y and Controls.ChooseConfirm:IsHidden(),"rebase cancellation moved unit")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=trade-rebase-cancel status=PASS path=actual-OnConfirmNo")
                stage="confirm"
            else
                local r=request;request=nil;SelectNewHome(r.x,r.y);OnConfirmYes();LuaEvents.LekmodTradeHomeDone(r.id)
            end
        end)
        if not ok then request=nil;print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=trade-rebase status=FAIL error="..tostring(err));OnClose() end
    end)
end
