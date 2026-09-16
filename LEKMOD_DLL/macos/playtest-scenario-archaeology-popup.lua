-- Actual archaeology selection/confirmation/close callbacks, including No.
do
    local request,stage,elapsed,announced
    LuaEvents.LekmodArchaeologyChoice.Add(function(kind,id,x,y)
        request={kind=kind,id=id,x=x,y=y};stage="select";elapsed=0;announced=false
    end)
    ContextPtr:SetUpdate(function(dt)
        if not request or ContextPtr:IsHidden() or Game.IsProcessingMessages() then return end
        elapsed=elapsed+dt;if elapsed<1 then return end
        if not announced then
            announced=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=archaeology-"..request.kind)
        end
        if __TEST_CAPTURE_PANELS__ and elapsed<10 then return end
        elapsed=0
        local ok,err=pcall(function()
            local player=Players[Game.GetActivePlayer()];local plot=player:GetNextDigCompletePlot()
            assert(plot and plot:GetX()==request.x and plot:GetY()==request.y,"archaeology popup has the wrong completed dig")
            assert(not plot:HasWrittenArtifact(),"ordinary artifact fixture opened written choice")
            local choice=request.kind=="artifact" and 2 or 1
            if choice==2 then assert(player:HasAvailableGreatWorkSlot(GameInfo.GreatWorkSlots.GREAT_WORK_SLOT_ART_ARTIFACT.ID),"artifact has no legal slot") end
            if stage=="select" and request.kind=="artifact" then
                local works=player:GetNumGreatWorks()
                SelectArchaeologyChoice(choice);assert(not Controls.ChooseConfirm:IsHidden(),"archaeology confirmation did not open")
                OnConfirmNo()
                assert(Controls.ChooseConfirm:IsHidden() and player:GetNumGreatWorks()==works and player:GetUnitByID(request.id),"cancelling archaeology applied a choice")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=archaeology-cancel status=PASS path=actual-OnConfirmNo")
                stage="confirm";return
            end
            local r=request;request=nil
            SelectArchaeologyChoice(choice);assert(not Controls.ChooseConfirm:IsHidden(),"archaeology confirmation missing")
            OnConfirmYes()
            LuaEvents.LekmodArchaeologyAnswered(r.kind,r.x,r.y)
        end)
        if not ok then request=nil;print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=archaeology-choice status=FAIL error="..tostring(err)) end
    end)
end
