-- Invoke the actual GenericPopup choice closure for a specifically requested
-- test unit/action. Preserve normal HideWindow bookkeeping and cancellation.
do
    local request,ready,callback,elapsed
    LuaEvents.LekmodConfirmUnitAction.Add(function(kind,id,choice)
        request={kind=kind,id=id,choice=choice};ready=false
    end)
    local original=assert(PopupLayouts[ButtonPopupTypes.BUTTONPOPUP_CONFIRMCOMMAND])
    PopupLayouts[ButtonPopupTypes.BUTTONPOPUP_CONFIRMCOMMAND]=function(info)
        local action=GameInfoActions[info.Data1]
        if not request or action.Type~=request.kind then return original(info) end
        local add=AddButton
        AddButton=function(text,fn,tooltip,preventClose)
            local key=request.choice=="no" and "TXT_KEY_POPUP_NO" or "TXT_KEY_POPUP_YES"
            if text==Locale.ConvertTextKey(key) then ready,callback,elapsed=true,fn,0;assert(not preventClose) end
            add(text,fn,tooltip,preventClose)
        end
        local ok,result=pcall(original,info);AddButton=add
        if not ok then error(result) end
        return result
    end
    ContextPtr:SetUpdate(function(dt)
        if not ready or ContextPtr:IsHidden() or Game.IsProcessingMessages() then return end
        elapsed=elapsed+dt;if elapsed<1 then return end
        local r,fn=request,callback;request,callback,ready=nil,nil,false
        local ok,err=pcall(function()
            local u=UI.GetHeadSelectedUnit();assert(u and u:GetID()==r.id,"command confirmation selected a different unit")
            if fn then fn() end
            HideWindow()
            LuaEvents.LekmodUnitCommandConfirmed(r.kind,r.id,r.choice)
        end)
        if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=unit-confirmation status=FAIL error="..tostring(err)) end
    end)
end
