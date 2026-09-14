-- Select an actually available route through the standard popup's callbacks.
do
    local pending,elapsed,announced
    LuaEvents.LekmodScenarioTradeRoute.Add(function(unit,x,y,kind)
        pending,elapsed,announced={unit=unit,x=x,y=y,kind=kind},0,false
        UI.SelectUnit(Players[Game.GetActivePlayer()]:GetUnitByID(unit))
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_CHOOSE_INTERNATIONAL_TRADE_ROUTE,Data2=unit})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not pending then return end
        elapsed=elapsed+dt
        if elapsed<1 or ContextPtr:IsHidden() then return end
        if __TEST_CAPTURE_PANELS__ and not announced then
            announced=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=trade-route")
        end
        if __TEST_CAPTURE_PANELS__ and elapsed<10 then return end
        local request=pending; pending=nil
        local ok,err=pcall(function()
            assert(g_iUnitIndex==request.unit, "trade popup selected a different unit")
            local unit=assert(Players[Game.GetActivePlayer()]:GetUnitByID(request.unit))
            local available=false
            for _,entry in ipairs(Players[Game.GetActivePlayer()]:GetPotentialInternationalTradeRouteDestinations(unit)) do
                if entry.X==request.x and entry.Y==request.y and entry.TradeConnectionType==request.kind then available=true; break end
            end
            assert(available and unit:CanMakeTradeRouteAt(unit:GetPlot(),request.x,request.y,request.kind), "trade destination is not legal")
            SelectTradeDestinationChoice(request.x,request.y,request.kind)
            assert(not Controls.ChooseConfirm:IsHidden(), "trade confirmation did not open")
            OnConfirmYes()
            LuaEvents.LekmodScenarioTradeResponse("route",request.unit)
        end)
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=trade-route status=FAIL error="..tostring(err))
            OnClose()
        end
    end)
end
