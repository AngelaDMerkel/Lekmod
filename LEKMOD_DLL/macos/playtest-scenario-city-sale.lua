-- Actual CityView sale dialog, including a cancellation before confirmation.
do
    local request,stage,elapsed,gold
    LuaEvents.LekmodScenarioCitySale.Add(function(cityID,building)
        request={city=cityID,building=building};stage="open";elapsed=0
        UI.DoSelectCityAtPlot(Players[Game.GetActivePlayer()]:GetCityByID(cityID):Plot())
    end)
    ContextPtr:SetUpdate(function(dt)
        if not request or Game.IsProcessingMessages() then return end
        elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
        local ok,err=pcall(function()
            local city=UI.GetHeadSelectedCity()
            assert(city and city:GetID()==request.city and not ContextPtr:IsHidden(),"sale selected wrong city")
            if stage=="open" then
                gold=Players[Game.GetActivePlayer()]:GetGold()
                OnBuildingClicked(request.building)
                assert(not Controls.SellBuildingConfirm:IsHidden(),"sale confirmation did not open")
                OnNo();stage="cancelled"
            elseif stage=="cancelled" then
                assert(Controls.SellBuildingConfirm:IsHidden() and city:GetNumRealBuilding(request.building)==1 and Players[Game.GetActivePlayer()]:GetGold()==gold,"sale cancellation changed city/gold")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=building-sale-cancel status=PASS path=CityView-OnNo")
                OnBuildingClicked(request.building);OnYes();stage="sold"
            elseif stage=="sold" then
                if city:GetNumRealBuilding(request.building)~=0 then return end
                local building=request.building;request=nil
                OnReturnToMapButton()
                LuaEvents.LekmodScenarioCityResponse("sale",building)
            end
        end)
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=building-sale status=FAIL error="..tostring(err))
            request=nil;OnReturnToMapButton()
        end
    end)
end
