do
    local request,stage,elapsed
    LuaEvents.LekmodChooseTestIdeology.Add(function(id) request=id;stage="cancel";elapsed=0 end)
    ContextPtr:SetUpdate(function(dt)
        if not request or ContextPtr:IsHidden() or Game.IsProcessingMessages() then return end
        elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
        local ok,err=pcall(function()
            local player=Players[Game.GetActivePlayer()]
            assert(player:GetLateGamePolicyTree()==-1,"ideology was already selected")
            SelectIdeologyChoice(request)
            assert(not Controls.ChooseConfirm:IsHidden(),"ideology confirmation missing")
            if stage=="cancel" then
                OnConfirmNo();assert(player:GetLateGamePolicyTree()==-1,"cancel chose an ideology")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=ideology-cancel status=PASS path=actual-OnConfirmNo")
                stage="confirm"
            else
                local id=request;request=nil;OnConfirmYes();LuaEvents.LekmodIdeologyChosen(id)
            end
        end)
        if not ok then request=nil;print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=ideology-choice status=FAIL error="..tostring(err)) end
    end)
end
