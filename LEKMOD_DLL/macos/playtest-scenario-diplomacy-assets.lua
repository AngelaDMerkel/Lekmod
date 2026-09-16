-- New Ancient fixture gives a naturally positive starting budget. Technologies,
-- contact and a luxury surplus are labeled inputs; deals are real AI proposals.
LekmodScenario={name="diplomacy-assets",items={"resource-gift","gpt-gift","mutual-embassies","open-borders-gift","diplomacy-trade-restrictions","gpt-settlement"}}
local phase,target,resource,beforeUs,beforeThem,gptUs,gptThem,closed,accepted,proposed,turn,ledger="init"
LuaEvents.LekmodScenarioDiplomacyResponse.Add(function(kind) if kind=="closed" then closed=true end end)
LuaEvents.LekmodDiplomacyAssetsAccepted.Add(function(kind) accepted=kind end)
LuaEvents.LekmodDiplomacyAssetsProposed.Add(function(kind) proposed=kind end)
local function request(kind)
    closed,accepted,proposed=false,nil,nil
    LuaEvents.LekmodDiplomacyAssets({player=target,kind=kind,resource=resource,resource_before=beforeUs,gpt_before=gptUs})
    LuaEvents.LekmodScenarioDiplomacyOpen(target)
end
function LekmodScenario.snapshot(player)
    local partners,resources={},{}
    for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
        if p and p:IsAlive() then partners[id]={gold=p:GetGold(),gpt=p:GetGoldPerTurnFromDiplomacy(),embassy=Teams[p:GetTeam()]:HasEmbassyAtTeam(player:GetTeam()),open=Teams[player:GetTeam()]:IsAllowsOpenBordersToTeam(p:GetTeam())} end
    end
    for r in GameInfo.Resources() do if r.ResourceUsage==2 then
        local counts={};for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id];if p and p:IsAlive() then counts[id]=p:GetNumResourceAvailable(r.ID,true) end end
        resources[r.ID]=counts
    end end
    for id,row in pairs(partners) do
        if id~=player:GetID() then
            assert(row.embassy and Teams[player:GetTeam()]:HasEmbassyAtTeam(Players[id]:GetTeam()),"mutual embassy state did not persist")
        end
    end
    return {turn=Game.GetGameTurn(),partners=partners,resources=resources}
end
function LekmodScenarioBeforeEndTurn(player,t)
    if phase=="settlement" then ledger={turn=t,gold=player:GetGold(),rate=player:CalculateGoldRateTimes100()};LekmodScenarioEvent("diplomatic-ledger-before",ledger) end
end
function LekmodScenario.step(player)
    local city=player:GetCapitalCity();if not city then return "turn" end
    if phase=="init" then
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do if id~=player:GetID() and Players[id] and Players[id]:IsAlive() then target=id;break end end
        assert(target,"no AI partner")
        LekmodScenarioGrantTech(player,"TECH_CIVIL_SERVICE")
        LekmodScenarioGrantTech(Players[target],"TECH_WRITING")
        if not Teams[player:GetTeam()]:IsHasMet(Players[target]:GetTeam()) then
            Teams[player:GetTeam()]:Meet(Players[target]:GetTeam(),false);LekmodScenarioEvent("fixture-setup",{operation="established-contact",other=target})
        end
        turn=Game.GetGameTurn();phase="ready";return "turn"
    elseif phase=="ready" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Players[target]:GetCapitalCity(),"AI has not founded its capital")
        assert(player:CalculateGoldRate()>=1,"fixture has no positive GPT to give")
        local deal=UI.GetScratchDeal();deal:ClearItems();deal:SetFromPlayer(player:GetID());deal:SetToPlayer(target)
        for r in GameInfo.Resources() do
            if r.ResourceUsage==2 and Players[target]:GetNumResourceAvailable(r.ID,true)==0 then
                if r.TechCityTrade then LekmodScenarioGrantTech(player,r.TechCityTrade) end
                local amount=math.max(0,2-player:GetNumResourceAvailable(r.ID,true))
                if amount>0 then player:ChangeNumResourceTotal(r.ID,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-luxury-surplus",resource=r.Type,added=amount}) end
                if deal:IsPossibleToTradeItem(player:GetID(),target,TradeableItems.TRADE_ITEM_RESOURCES,r.ID,1,30) then resource=r.ID;break end
            end
        end
        assert(resource,"no legal luxury gift")
        beforeUs=player:GetNumResourceAvailable(resource,true);beforeThem=Players[target]:GetNumResourceAvailable(resource,true)
        gptUs=player:GetGoldPerTurnFromDiplomacy();gptThem=Players[target]:GetGoldPerTurnFromDiplomacy()
        assert(not deal:IsPossibleToTradeItem(player:GetID(),target,TradeableItems.TRADE_ITEM_GOLD_PER_TURN,player:CalculateGoldRate()+1,30),"GPT exceeding income is legal")
        assert(not deal:IsPossibleToTradeItem(player:GetID(),target,TradeableItems.TRADE_ITEM_OPEN_BORDERS,30),"open borders allowed before embassy")
        deal:ClearItems();request("assets");phase="assets"
    elseif phase=="assets" then
        if not closed then return false end
        assert(accepted=="assets" and proposed=="assets","asset gift did not complete actual trade flow")
        assert(player:GetNumResourceAvailable(resource,true)==beforeUs-1 and Players[target]:GetNumResourceAvailable(resource,true)==beforeThem+1,"luxury transfer mismatch")
        assert(player:GetGoldPerTurnFromDiplomacy()==gptUs-1 and Players[target]:GetGoldPerTurnFromDiplomacy()==gptThem+1,"GPT transfer mismatch")
        LekmodScenarioRecord("resource-gift","PASS","path=actual-resource/propose/AI-reply callbacks amount=1")
        LekmodScenarioRecord("gpt-gift","PASS","path=actual-GPT/propose/AI-reply callbacks amount=1")
        local deal=UI.GetScratchDeal();deal:ClearItems();deal:SetFromPlayer(player:GetID());deal:SetToPlayer(target)
        assert(not deal:IsPossibleToTradeItem(player:GetID(),target,TradeableItems.TRADE_ITEM_RESOURCES,resource,1,30),"duplicate luxury recipient accepted another copy")
        request("embassies");phase="embassies"
    elseif phase=="embassies" then
        if not closed then return false end
        assert(accepted=="embassies" and proposed=="embassies","mutual embassy agreement not accepted")
        LekmodScenarioRecord("mutual-embassies","PASS","path=actual-mutual-pocket-and-propose callbacks")
        request("borders");phase="borders"
    elseif phase=="borders" then
        if not closed then return false end
        assert(accepted=="borders" and proposed=="borders","open borders gift not accepted")
        LekmodScenarioRecord("open-borders-gift","PASS","path=actual-open-borders/propose callbacks")
        LekmodScenarioRecord("diplomacy-trade-restrictions","PASS","excess-GPT/no-embassy-open-borders/duplicate-luxury=rejected")
        turn=Game.GetGameTurn();phase="settlement";return "turn"
    elseif phase=="settlement" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(ledger and player:GetGoldPerTurnFromDiplomacy()==gptUs-1,"missing settled diplomatic payment")
        local expected=math.floor(ledger.rate/100);local actual=player:GetGold()-ledger.gold
        LekmodScenarioEvent("diplomatic-ledger-after",{turn=Game.GetGameTurn(),delta=actual,expected=expected})
        assert(actual==expected,"ordinary treasury settlement differs from quoted rate including GPT gift")
        LekmodScenarioRecord("gpt-settlement","PASS","path=ordinary-turn delta="..actual)
        return true
    end
    return false
end
