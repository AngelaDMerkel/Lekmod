-- Read-only preparation for an actual pressure/revolution fixture.
LekmodScenario={name="ideology-inventory",items={"ideology-input-inventory"}}
function LekmodScenario.snapshot(player)
    local players={}
    for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
        if p and p:IsAlive() then
            local influence={}
            for other=0,GameDefines.MAX_MAJOR_CIVS-1 do if Players[other] and Players[other]:IsAlive() and other~=id then influence[other]={amount=p:GetInfluenceOn(other),level=p:GetInfluenceLevel(other)} end end
            players[id]={ideology=p:GetLateGamePolicyTree(),culture=p:GetJONSCultureEverGenerated(),tourism=p:GetTourism(),influence=influence,
                unhappiness=p:GetPublicOpinionUnhappiness(),preferred=p:GetPublicOpinionPreferredIdeology(),current_culture=p:GetJONSCulture(),free_tenets=p:GetNumFreeTenets()}
        end
    end
    return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),players=players}
end
function LekmodScenario.step(player)
    LekmodScenarioEvent("ideology-input-inventory",LekmodScenario.snapshot(player))
    LekmodScenarioRecord("ideology-input-inventory","PASS","scope=read-only-state not-revolution-coverage")
    return true
end
