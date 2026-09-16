do
    local request,stage,elapsed,culture,free
    LuaEvents.LekmodChooseTestTenet.Add(function(id,cancel)
        request={id=id,cancel=cancel};stage="select";elapsed=0
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY,Data1=0,Data2=2})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not request or ContextPtr:IsHidden() or Game.IsProcessingMessages() then return end
        elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
        local ok,err=pcall(function()
            local p=Players[Game.GetActivePlayer()]
            if stage=="select" then
                assert(p:CanAdoptPolicy(request.id),"requested tenet is not legal")
                if request.cancel then
                    culture=p:GetJONSCulture();free=p:GetNumFreePolicies()+p:GetNumFreeTenets()
                    ChooseTenet(request.id,Locale.ConvertTextKey(GameInfo.Policies[request.id].Description))
                    OnTenetConfirmNo()
                    assert(not p:HasPolicy(request.id) and p:GetJONSCulture()==culture and p:GetNumFreePolicies()+p:GetNumFreeTenets()==free,"cancelled tenet changed state")
                    print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=tenet-cancel status=PASS path=actual-OnTenetConfirmNo")
                end
                if p:GetPublicOpinionUnhappiness()==0 then assert(Controls.SwitchIdeologyButton:IsDisabled(),"content ideology allows revolution") end
                ChooseTenet(request.id,Locale.ConvertTextKey(GameInfo.Policies[request.id].Description));OnTenetConfirmYes();stage="applied"
            elseif stage=="applied" then
                if not p:HasPolicy(request.id) then return end
                local id=request.id;request=nil;OnClose();LuaEvents.LekmodTenetChosen(id)
            end
        end)
        if not ok then request=nil;print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=tenet-choice status=FAIL error="..tostring(err));OnClose() end
    end)
end
