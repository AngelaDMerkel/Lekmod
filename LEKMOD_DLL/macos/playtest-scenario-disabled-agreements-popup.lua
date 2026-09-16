if ContextPtr:GetID()=="DiploTrade" then
    local target,elapsed
    LuaEvents.LekmodDisabledAgreementsOpen.Add(function(player) target,elapsed=player,0 end)
    ContextPtr:SetUpdate(function(dt)
        if not target or ContextPtr:IsHidden() or g_iThem~=target then return end
        elapsed=elapsed+dt;if elapsed<1 then return end;target=nil
        local ok,err=pcall(function()
            assert(not g_bPVPTrade and not g_bTradeReview,"not the normal single-player trade screen")
            assert(Controls.UsPocketResearchAgreement:IsDisabled() and Controls.ThemPocketResearchAgreement:IsDisabled(),"research agreement control enabled")
            assert((Controls.UsPocketTradeAgreement:IsHidden() or Controls.UsPocketTradeAgreement:IsDisabled()) and
                (Controls.ThemPocketTradeAgreement:IsHidden() or Controls.ThemPocketTradeAgreement:IsDisabled()),"trade agreement control enabled")
            LuaEvents.LekmodDisabledAgreementsChecked({research_disabled=true,trade_hidden_or_disabled=true})
            OnBack();LuaEvents.LekmodScenarioDiplomacyClose()
        end)
        if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=disabled-agreements status=FAIL error="..tostring(err));OnBack() end
    end)
end
