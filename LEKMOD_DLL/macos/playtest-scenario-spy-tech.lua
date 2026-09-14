-- Choose a legitimately earned espionage science award through the real popup.
do
    local pending,elapsed
    LuaEvents.LekmodScenarioSpyTech.Add(function(target,tech)
        pending,elapsed={target=target,tech=tech},0
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_CHOOSE_TECH_TO_STEAL,
            Data1=Game.GetActivePlayer(),Data2=target,Data3=-1})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not pending then return end
        elapsed=elapsed+dt
        if elapsed<1 or ContextPtr:IsHidden() then return end
        local request=pending;pending=nil
        local ok,err=pcall(function()
            local player=Players[Game.GetActivePlayer()]
            assert(stealingTechTargetPlayerID==request.target, "tech popup is not in espionage mode")
            assert(player:canStealTech(request.target,request.tech) and player:ScienceToStealAmount(request.target,request.tech)>0,
                "no earned espionage science for this technology")
            TechSelected(request.tech,request.target)
            LuaEvents.LekmodScenarioSpyTechSelected(request.tech)
        end)
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=spy-science status=FAIL error="..tostring(err))
            ClosePopup()
        end
    end)
end
