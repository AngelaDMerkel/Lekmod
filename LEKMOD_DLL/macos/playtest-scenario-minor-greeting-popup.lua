do
    local elapsed,announced,done=0,false,false
    ContextPtr:SetUpdate(function(dt)
        if done or ContextPtr:IsHidden() or not m_PopupInfo then return end
        elapsed=elapsed+dt;if elapsed<1 then return end
        if not announced then
            announced=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=minor-personality-greeting")
        end
        if __TEST_CAPTURE_PANELS__ and elapsed<10 then return end
        done=true
        local ok,err=pcall(function()
            local id=m_PopupInfo.Data1
            local expected=GetMinorCivPersonalityDisplayText(Players[id])
            local actual=Controls.PersonalityInfo:GetText()
            assert(expected~="" and actual==expected,"rendered personality differs from the configured personality")
            OnCloseButtonClicked()
            LuaEvents.LekmodGreetingValidated(id,actual)
        end)
        if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=minor-personality-greeting status=FAIL error="..tostring(err)) end
    end)
end
