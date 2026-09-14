-- Temporary adapter in the real founding/enhancing context. A legal prophet
-- mission must already have been consumed before the scenario requests it.
do
    local pending, elapsed, announced
    LuaEvents.LekmodScenarioReligionChoice.Add(function(kind, x, y)
        pending, elapsed, announced=kind,0,false
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_FOUND_RELIGION,
            Data1=x,Data2=y,Option1=kind=="found"})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not pending then return end
        elapsed=elapsed+dt
        if elapsed<1 or ContextPtr:IsHidden() then return end
        if __TEST_CAPTURE_PANELS__ and not announced then
            announced=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=religion-"..pending)
        end
        if __TEST_CAPTURE_PANELS__ and elapsed<10 then return end
        local kind=pending; pending=nil
        local originalSelect=SelectFromBeliefs
        local ok,err=pcall(function()
            assert(g_bFoundingReligion==(kind=="found"), "wrong religion popup mode")
            if kind=="found" then
                local taken={}
                for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
                    local p=Players[id]
                    if p and p:IsEverAlive() and p:HasCreatedReligion() then taken[p:GetReligionCreatedByPlayer()]=true end
                end
                local chosen
                for row in GameInfo.Religions() do
                    if row.Type~="RELIGION_PANTHEON" and not taken[row.ID] then chosen=row; break end
                end
                assert(chosen, "no unused religion")
                SelectReligion(chosen.ID,chosen.Description,chosen.IconAtlas,chosen.PortraitIndex)
            end
            -- Build the normal list, then call its actual selection closure.
            SelectFromBeliefs=function(beliefs,selectFn)
                originalSelect(beliefs,selectFn)
                assert(#beliefs>0, "belief list is empty")
                selectFn(beliefs[1])
                ToggleBeliefContext(nil)
            end
            if kind=="found" then OnFounderBeliefClick(); OnFollowerBeliefClick()
            else OnFollowerBelief2Click(); OnEnhancerBeliefClick() end
            SelectFromBeliefs=originalSelect
            CheckifCanCommit()
            assert(not Controls.FoundReligion:IsDisabled(), "religion commit is disabled")
            FoundReligion()
            assert(not Controls.ChooseConfirm:IsHidden(), "religion confirmation did not open")
            local selected=g_CurrentReligionID
            OnYes()
            LuaEvents.LekmodScenarioReligionResponse(kind,selected)
        end)
        SelectFromBeliefs=originalSelect
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=religion-"..kind.." status=FAIL error="..tostring(err))
            OnClose()
        end
    end)
end
