do
    local stage,elapsed,old,culture,free,anarchy
    LuaEvents.LekmodTestRevolution.Add(function()
        stage="cancel";elapsed=0
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY,Data1=0,Data2=2})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not stage or ContextPtr:IsHidden() or Game.IsProcessingMessages() then return end
        elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
        local ok,err=pcall(function()
            local p=Players[Game.GetActivePlayer()]
            if stage=="cancel" then
                assert(not Controls.SwitchIdeologyButton:IsDisabled(),"actual revolution button is disabled under pressure")
                old=p:GetLateGamePolicyTree();culture=p:GetJONSCulture();free=p:GetNumFreeTenets();anarchy=p:GetAnarchyNumTurns()
                ChooseChangeIdeology();assert(not Controls.ChangeIdeologyConfirm:IsHidden(),"revolution confirmation not shown")
                OnChangeIdeologyConfirmNo()
                assert(Controls.ChangeIdeologyConfirm:IsHidden() and p:GetLateGamePolicyTree()==old and p:GetJONSCulture()==culture and p:GetNumFreeTenets()==free and p:GetAnarchyNumTurns()==anarchy,"cancelled revolution changed state")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=revolution-cancel status=PASS path=actual-OnChangeIdeologyConfirmNo")
                ChooseChangeIdeology();OnChangeIdeologyConfirmYes();stage="result"
            elseif stage=="result" then
                if p:GetLateGamePolicyTree()==old then return end
                assert(p:GetPublicOpinionUnhappiness()==0 and Controls.SwitchIdeologyButton:IsDisabled(),"content revolution was not disabled after switch")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=revolution-content-rejection status=PASS actual-button-disabled=true")
                stage=nil;OnClose();LuaEvents.LekmodRevolutionFinished()
            end
        end)
        if not ok then stage=nil;print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=revolution-popup status=FAIL error="..tostring(err));OnClose() end
    end)
end
