-- Actual ProductionPopup purchase callbacks, restricted to validated fixtures.
do
    local pending,elapsed,announced
    LuaEvents.LekmodScenarioFaithPurchase.Add(function(city,unit)
        pending,elapsed,announced={city=city,unit=unit,faith=true},0,false
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION,
            Data1=city,Data2=-1,Data3=-1,Option1=false,Option2=true})
    end)
    LuaEvents.LekmodScenarioGoldPurchase.Add(function(city,unit)
        pending,elapsed,announced={city=city,unit=unit,faith=false},0,false
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION,
            Data1=city,Data2=-1,Data3=-1,Option1=false,Option2=true})
    end)
    LuaEvents.LekmodScenarioBuildingPurchase.Add(function(city,building)
        pending,elapsed,announced={city=city,building=building,faith=false},0,false
        Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION,
            Data1=city,Data2=-1,Data3=-1,Option1=false,Option2=true})
    end)
    ContextPtr:SetUpdate(function(dt)
        if not pending then return end
        elapsed=elapsed+dt
        if elapsed<1 or ContextPtr:IsHidden() then return end
        if __TEST_CAPTURE_PANELS__ and not announced then
            announced=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name="..(pending.faith and "faith" or "gold").."-purchase")
        end
        if __TEST_CAPTURE_PANELS__ and elapsed<10 then return end
        local request=pending; pending=nil
        local ok,err=pcall(function()
            local city=GetCurrentCity()
            assert(city and city:GetID()==request.city and not g_IsProductionMode, "purchase popup mode/city is wrong")
            local yield=request.faith and YieldTypes.YIELD_FAITH or YieldTypes.YIELD_GOLD
            if request.building then
                assert(city:IsCanPurchase(true,true,-1,request.building,-1,yield),"building purchase is not legal")
                ProductionSelected(g_PURCHASE_BUILDING_GOLD,request.building)
                LuaEvents.LekmodScenarioCityResponse("purchase",request.building)
                return
            end
            assert(city:IsCanPurchase(true,true,request.unit,-1,-1,yield), "unit purchase is not legal")
            ProductionSelected(request.faith and g_PURCHASE_UNIT_FAITH or g_PURCHASE_UNIT_GOLD,request.unit)
            if request.faith then LuaEvents.LekmodScenarioReligionResponse("purchase",request.unit)
            else LuaEvents.LekmodScenarioTradeResponse("purchase",request.unit) end
        end)
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item="..(request.building and "building-purchase" or (request.faith and "faith-purchase" or "gold-unit-purchase")).." status=FAIL error="..tostring(err))
            OnClose()
        end
    end)
end
