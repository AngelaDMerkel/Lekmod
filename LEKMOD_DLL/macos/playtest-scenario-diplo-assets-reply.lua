do
    local request,elapsed,checks
    LuaEvents.LekmodDiplomacyAssets.Add(function(r) request=r;elapsed=0;checks=0 end)
    ContextPtr:SetUpdate(function(dt)
        if not request or ContextPtr:IsHidden() or g_iAIPlayer~=request.player or not g_bCanGoBack then return end
        elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
        local us=Players[Game.GetActivePlayer()];local them=Players[request.player]
        local accepted=false
        if request.kind=="assets" then accepted=us:GetGoldPerTurnFromDiplomacy()==request.gpt_before-1 and us:GetNumResourceAvailable(request.resource,true)==request.resource_before-1
        elseif request.kind=="embassies" then accepted=Teams[us:GetTeam()]:HasEmbassyAtTeam(them:GetTeam()) and Teams[them:GetTeam()]:HasEmbassyAtTeam(us:GetTeam())
        else accepted=Teams[us:GetTeam()]:IsAllowsOpenBordersToTeam(them:GetTeam()) end
        checks=checks+1
        if not accepted then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=diplomatic-reply-state kind="..request.kind.." gpt="..us:GetGoldPerTurnFromDiplomacy().." resource="..us:GetNumResourceAvailable(request.resource,true))
            if checks>=8 then
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=diplomacy-assets status=FAIL error=accepted-reply-did-not-match-deal-state")
                request=nil;OnBack();LuaEvents.LekmodScenarioDiplomacyClose()
            end
            return
        end
        local kind=request.kind;request=nil
        LuaEvents.LekmodDiplomacyAssetsAccepted(kind)
        OnBack();LuaEvents.LekmodScenarioDiplomacyClose()
    end)
end
