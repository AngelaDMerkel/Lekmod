-- Use the actual choice closure installed by PuppetCityPopup and the original
-- GenericPopup close bookkeeping. This is scripted callback, not mouse input.
do
    local desired,selected,cityID,elapsed
    LuaEvents.LekmodCaptureChoice.Add(function(kind) desired=kind end)
    local originalLayout=PopupLayouts[ButtonPopupTypes.BUTTONPOPUP_CITY_CAPTURED]
    assert(originalLayout,"city capture popup layout missing")
    PopupLayouts[ButtonPopupTypes.BUTTONPOPUP_CITY_CAPTURED]=function(info)
        selected,cityID=nil,nil
        local originalAdd=AddButton
        local keys={puppet="TXT_KEY_POPUP_PUPPET_CAPTURED_CITY",liberate="TXT_KEY_POPUP_LIBERATE_CITY"}
        AddButton=function(text,callback,tooltip,preventClose)
            if desired and text==Locale.ConvertTextKey(keys[desired]) then
                selected,cityID,elapsed=callback,info.Data1,0
                assert(not preventClose,"capture choice unexpectedly keeps popup open")
            end
            originalAdd(text,callback,tooltip,preventClose)
        end
        local ok,result=pcall(originalLayout,info)
        AddButton=originalAdd
        if not ok then error(result) end
        if desired and not selected then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=city-disposition status=FAIL error=requested-capture-choice-missing choice="..desired)
        end
        return result
    end
    ContextPtr:SetUpdate(function(dt)
        if not selected or ContextPtr:IsHidden() or Game.IsProcessingMessages() then return end
        elapsed=elapsed+dt;if elapsed<1 then return end
        local callback,kind,id=selected,desired,cityID
        selected,desired=nil,nil
        local ok,err=pcall(function()
            callback();HideWindow()
            LuaEvents.LekmodCaptureChoiceDone(kind,id)
        end)
        if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=city-disposition status=FAIL error="..tostring(err)) end
    end)
end
