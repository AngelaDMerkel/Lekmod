LekmodScenario={name="diplomacy",items={"diplomacy-open","diplomacy-gift"}}
local phase,response,target,beforeUs,beforeThem="init"
local opened,proposed=false,false
LuaEvents.LekmodScenarioDiplomacyResponse.Add(function(kind)
    response=kind
    if kind=="open" then opened=true end
    if kind=="proposed" then proposed=true end
end)
function LekmodScenario.snapshot(player)
    local players={}
    for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
        local other=Players[id]
        if other and other:IsAlive() and Teams[player:GetTeam()]:IsHasMet(other:GetTeam()) then
            players[id]={gold=other:GetGold(),friend=other:IsDoF(player:GetID()),war=Teams[player:GetTeam()]:IsAtWar(other:GetTeam()),
                embassy=Teams[other:GetTeam()]:HasEmbassyAtTeam(player:GetTeam())}
        end
    end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),players=players}
end
function LekmodScenario.step(player)
    if phase=="init" then
        local deal=UI.GetScratchDeal();deal:ClearItems()
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
            local other=Players[id]
            if other and other:IsAlive() and not other:IsHuman() and Teams[player:GetTeam()]:IsHasMet(other:GetTeam()) and not Teams[player:GetTeam()]:IsAtWar(other:GetTeam()) then
                deal:SetFromPlayer(player:GetID());deal:SetToPlayer(id)
                local possible=deal:IsPossibleToTradeItem(player:GetID(),id,TradeableItems.TRADE_ITEM_ALLOW_EMBASSY)
                LekmodScenarioEvent("diplomacy-eligibility",{player=id,embassy_gift=possible,friend=other:IsDoF(player:GetID())})
                if possible then target=id;break end
            end
        end
        deal:ClearItems()
        assert(target, "fixture has no legal AI embassy-gift partner")
        beforeUs,beforeThem=player:GetGold(),Players[target]:GetGold()
        -- Diplomacy deliberately holds the game-level processing guard while
        -- waiting for UI input. Arm the ordinary UI adapters before opening;
        -- this scenario resumes only after those contexts close normally.
        response=nil;LuaEvents.LekmodScenarioDiplomacyGift(target)
        LuaEvents.LekmodScenarioDiplomacyOpen(target);phase="pending"
    elseif phase=="pending" then
        if response~="closed" then return false end
        assert(opened and proposed,"diplomacy UI did not complete the intended callbacks")
        LekmodScenarioRecord("diplomacy-open","PASS","path=leader-and-trade-callback player="..target)
        local accepted=Teams[Players[target]:GetTeam()]:HasEmbassyAtTeam(player:GetTeam())
        if not LekmodScenarioAwait("accepted-embassy-gift",accepted) then return false end
        assert(player:GetGold()==beforeUs and Players[target]:GetGold()==beforeThem,"free embassy changed treasury")
        LekmodScenarioRecord("diplomacy-gift","PASS","path=actual-embassy-and-propose-callback recipient="..target)
        return true
    end
    return false
end
