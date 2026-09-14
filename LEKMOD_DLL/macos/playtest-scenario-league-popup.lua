-- Render the real Congress panel, preserving its ordinary close bookkeeping.
do
    local pending,elapsed,announced
    LuaEvents.LekmodScenarioLeaguePanel.Add(function(league,kind)
        pending,elapsed,announced=kind,0,false
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_LEAGUE_OVERVIEW,Data1=league})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not pending then return end
        elapsed=elapsed+dt
        if elapsed<1 or ContextPtr:IsHidden() then return end
        if not announced then
            announced=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=congress-"..pending)
        end
        if __TEST_CAPTURE_PANELS__ and elapsed<10 then return end
        local kind=pending;pending=nil
        OnClose()
        LuaEvents.LekmodScenarioLeaguePanelDone(kind)
    end)
end
