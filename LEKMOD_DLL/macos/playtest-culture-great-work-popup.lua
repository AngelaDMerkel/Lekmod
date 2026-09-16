-- Preserve the original great-work zoom animation and normal Close callback.
do
    local originalShowHide=ShowHideHandler
    ContextPtr:SetShowHideHandler(function(hidden,initializing)
        originalShowHide(hidden,initializing)
        if not hidden and not initializing then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=created-great-work")
        end
    end)
    LuaEvents.LekmodCultureCloseGreatWork.Add(function()
        assert(not ContextPtr:IsHidden(),"great-work popup is not visible")
        OnClose()
        LuaEvents.LekmodCultureGreatWorkClosed()
    end)
end
