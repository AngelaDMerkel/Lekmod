-- Lekmod's defensive-pact item is a ten-turn non-aggression pact. Research
-- agreements have no technology unlock in the shipped data and stay unavailable.
LekmodScenario={name="diplomacy-pact",items={"research-agreement-configured-off","research-agreement-ui","pact-create","pact-war-restriction"}}
local started,closed,proposed,accepted,disabled,before,opinionTurn
LuaEvents.LekmodScenarioDiplomacyResponse.Add(function(kind) if kind=="closed" then closed=true end end)
LuaEvents.LekmodPactProposed.Add(function() proposed=true end)
LuaEvents.LekmodPactAccepted.Add(function() accepted=true end)
LuaEvents.LekmodPactResearchDisabled.Add(function(label) disabled=label end)
function LekmodScenario.snapshot(player)
    local other=Players[1];local a,b=Teams[player:GetTeam()],Teams[other:GetTeam()]
    return {turn=Game.GetGameTurn(),us_gold=player:GetGold(),them_gold=other:GetGold(),ours=a:IsDefensivePact(other:GetTeam()),theirs=b:IsDefensivePact(player:GetTeam()),
        us_can_war=a:CanDeclareWar(other:GetTeam()),them_can_war=b:CanDeclareWar(player:GetTeam()),war=a:IsAtWar(other:GetTeam()),
        our_embassy=a:HasEmbassyAtTeam(other:GetTeam()),their_embassy=b:HasEmbassyAtTeam(player:GetTeam()),friendship=player:IsDoF(1),research_allowed=a:IsResearchAgreementTradingAllowed() or b:IsResearchAgreementTradingAllowed()}
end
function LekmodScenario.step(player)
    if not opinionTurn then opinionTurn=Game.GetGameTurn();return "turn" end
    if Game.GetGameTurn()==opinionTurn then return "turn" end
    local other=Players[1];local a,b=Teams[player:GetTeam()],Teams[other:GetTeam()]
    if not started then
        assert(player:IsDoF(1) and other:IsDoF(player:GetID()),"load the accepted-friendship fixture")
        assert(a:HasEmbassyAtTeam(other:GetTeam()) and b:HasEmbassyAtTeam(player:GetTeam()),"mutual embassies required for the isolated research restriction")
        assert(not a:IsAtWar(other:GetTeam()) and not a:IsDefensivePact(other:GetTeam()),"fixture already at war or in a pact")
        assert(not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE) and not a:GetTeamTechs():HasResearchedAllTechs() and not b:GetTeamTechs():HasResearchedAllTechs(),"science-off/all-techs confounds the research restriction")
        local technologies=0
        for tech in GameInfo.Technologies() do
            technologies=technologies+1
            assert(tech.ResearchAgreementTradingAllowed~=true and tech.ResearchAgreementTradingAllowed~=1,"shipped data now contains a research-agreement unlock")
            assert(tech.TradeAgreementTradingAllowed~=true and tech.TradeAgreementTradingAllowed~=1,"shipped data now contains a trade-agreement unlock")
        end
        assert(technologies>0 and not a:IsResearchAgreementTradingAllowed() and not b:IsResearchAgreementTradingAllowed(),"native research-unlock state differs from the configuration")
        for _,p in ipairs({player,other}) do
            local partner=p:GetID()==player:GetID() and other:GetID() or player:GetID()
            local cost=Game.GetResearchAgreementCost(p:GetID(),partner)
            local needed=math.max(0,cost+1-p:GetGold())
            if needed>0 then p:ChangeGold(needed);LekmodScenarioEvent("fixture-setup",{operation="provided-affordability-control",player=p:GetID(),added=needed,quoted_cost=cost}) end
        end
        local deal=UI.GetScratchDeal();deal:ClearItems();deal:SetFromPlayer(player:GetID());deal:SetToPlayer(1)
        assert(TradeableItems.TRADE_ITEM_RESEARCH_AGREEMENT~=nil and not deal:IsPossibleToTradeItem(player:GetID(),1,TradeableItems.TRADE_ITEM_RESEARCH_AGREEMENT,Game.GetDealDuration()),"configured-off research agreement became eligible")
        LekmodScenarioRecord("research-agreement-configured-off","PASS","technology-unlocks=0 funds-embassies-friendship-present=true")
        before=LekmodScenario.snapshot(player);assert(before.us_can_war and before.them_can_war,"a separate restriction already prevents war")
        started=true;LuaEvents.LekmodPactProposal(1);LuaEvents.LekmodScenarioDiplomacyOpen(1);return false
    end
    if not closed then return false end
    assert(proposed and accepted and disabled,"pact callbacks or research UI check did not complete")
    LekmodScenarioEvent("pact-ui-label",{text=disabled})
    LekmodScenarioRecord("research-agreement-ui","PASS","actual-bilateral-controls=disabled")
    local state=LekmodScenario.snapshot(player)
    assert(state.ours and state.theirs and not state.war,"accepted pact did not apply bilaterally at peace")
    assert(state.us_gold==before.us_gold and state.them_gold==before.them_gold,"non-aggression pact unexpectedly spent treasury")
    LekmodScenarioRecord("pact-create","PASS","path=actual-pocket/propose/AI-reply callbacks duration=10")
    assert(not state.us_can_war and not state.them_can_war,"non-aggression pact failed to prohibit declarations")
    LekmodScenarioRecord("pact-war-restriction","PASS","both-directions=false")
    return true
end
