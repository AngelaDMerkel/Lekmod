LekmodScenario={name="disabled-agreements",items={"disabled-research-ui","disabled-trade-ui"}}
local opened,checked,closed
LuaEvents.LekmodDisabledAgreementsChecked.Add(function(result) checked=result end)
LuaEvents.LekmodScenarioDiplomacyResponse.Add(function(kind) if kind=="closed" then closed=true end end)
function LekmodScenario.snapshot(player)
    local p=Players[1];local a,b=Teams[player:GetTeam()],Teams[p:GetTeam()]
    return {turn=Game.GetGameTurn(),our_gold=player:GetGold(),their_gold=p:GetGold(),friendship=player:IsDoF(1),
        our_embassy=a:HasEmbassyAtTeam(p:GetTeam()),their_embassy=b:HasEmbassyAtTeam(player:GetTeam()),
        research_allowed=a:IsResearchAgreementTradingAllowed() or b:IsResearchAgreementTradingAllowed(),
        trade_allowed=a:IsTradeAgreementTradingAllowed() or b:IsTradeAgreementTradingAllowed()}
end
function LekmodScenario.step(player)
    if not opened then
        local p=Players[1];local a,b=Teams[player:GetTeam()],Teams[p:GetTeam()]
        assert(player:IsDoF(1) and p:IsDoF(player:GetID()) and a:HasEmbassyAtTeam(p:GetTeam()) and b:HasEmbassyAtTeam(player:GetTeam()),"load the funded friendship/embassy fixture")
        assert(not a:IsAtWar(p:GetTeam()) and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE),"war/science options confound agreement eligibility")
        assert(player:GetGold()>=Game.GetResearchAgreementCost(player:GetID(),1) and p:GetGold()>=Game.GetResearchAgreementCost(1,player:GetID()),"insufficient funds confound the research restriction")
        local s=LekmodScenario.snapshot(player);assert(not s.research_allowed and not s.trade_allowed,"native unlock counts differ from configured restrictions")
        opened=true;LuaEvents.LekmodDisabledAgreementsOpen(1);LuaEvents.LekmodScenarioDiplomacyOpen(1);return false
    end
    if not closed or not checked then return false end
    assert(checked.research_disabled and checked.trade_hidden_or_disabled,"actual controls were not checked")
    LekmodScenarioRecord("disabled-research-ui","PASS","actual-bilateral-controls=disabled configured-unlock=false")
    LekmodScenarioRecord("disabled-trade-ui","PASS","actual-bilateral-controls=hidden-or-disabled configured-unlock=false")
    return true
end
