-- Follow the already accepted luxury/GPT/open-border contracts without changing
-- duration, counters, diplomacy or income. Embassies must remain permanent.
LekmodScenario={name="diplomacy-expiry",items={"diplomatic-contract-expiry","expired-diplomatic-accounting","embassies-permanent"}}
local contracts,initial,deadline,last,resource
local function deals(player)
    local result={};local deal=UI.GetScratchDeal()
    for i=0,UI.GetNumCurrentDeals(player:GetID())-1 do
        UI.LoadCurrentDeal(player:GetID(),i);deal:ResetIterator()
        while true do
            local kind,duration,finish,a,b,c,flag,owner=deal:GetNextItem()
            if kind==nil then break end
            result[#result+1]={kind=kind,duration=duration,finish=finish,a=a,b=b,c=c,flag=flag,owner=owner,other=deal:GetOtherPlayer(owner)}
        end
    end
    return result
end
local function accounting(player)
    local other=Players[1];local exports,imports={},{}
    for r in GameInfo.Resources() do
        exports[r.ID]=player:GetResourceExport(r.ID);imports[r.ID]=other:GetResourceImport(r.ID)
    end
    return {us_gpt=player:GetGoldPerTurnFromDiplomacy(),them_gpt=other:GetGoldPerTurnFromDiplomacy(),exports=exports,imports=imports,
        open=Teams[player:GetTeam()]:IsAllowsOpenBordersToTeam(other:GetTeam()),
        our_embassy=Teams[player:GetTeam()]:HasEmbassyAtTeam(other:GetTeam()),their_embassy=Teams[other:GetTeam()]:HasEmbassyAtTeam(player:GetTeam())}
end
function LekmodScenario.snapshot(player)
    return {turn=Game.GetGameTurn(),accounting=accounting(player),deals=deals(player)}
end
function LekmodScenario.step(player)
    assert(not Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam()),"war cancelled the fixture's contracts before ordinary expiry")
    if not contracts then
        contracts={};initial=accounting(player);deadline=Game.GetGameTurn()
        for _,item in ipairs(deals(player)) do
            if item.owner==player:GetID() and item.other==1 and
                (item.kind==TradeableItems.TRADE_ITEM_GOLD_PER_TURN or item.kind==TradeableItems.TRADE_ITEM_RESOURCES or item.kind==TradeableItems.TRADE_ITEM_OPEN_BORDERS) then
                assert(not contracts[item.kind],"fixture has multiple matching contracts")
                contracts[item.kind]=item;deadline=math.max(deadline,item.finish)
                if item.kind==TradeableItems.TRADE_ITEM_RESOURCES then resource=item.a end
            end
        end
        assert(resource and contracts[TradeableItems.TRADE_ITEM_GOLD_PER_TURN] and contracts[TradeableItems.TRADE_ITEM_OPEN_BORDERS],"load the recorded luxury/GPT/borders fixture")
        assert(deadline>Game.GetGameTurn() and deadline-Game.GetGameTurn()<=30,"contract expiry is outside the bounded case")
        assert(initial.us_gpt==-1 and initial.them_gpt==1 and initial.exports[resource]==1 and initial.imports[resource]==1 and initial.open,"fixture accounting differs from the recorded one-unit gifts")
        LekmodScenarioEvent("existing-diplomatic-contracts",{turn=Game.GetGameTurn(),deadline=deadline,contracts=contracts,initial=initial})
    end
    local current=accounting(player);local turn=Game.GetGameTurn()
    assert(current.our_embassy and current.their_embassy,"embassy vanished during contract expiry")
    local gptActive=turn<contracts[TradeableItems.TRADE_ITEM_GOLD_PER_TURN].finish
    local resourceActive=turn<contracts[TradeableItems.TRADE_ITEM_RESOURCES].finish
    local bordersActive=turn<contracts[TradeableItems.TRADE_ITEM_OPEN_BORDERS].finish
    assert(current.us_gpt==(gptActive and -1 or 0) and current.them_gpt==(gptActive and 1 or 0),"GPT contract changed outside its quoted end turn")
    assert(current.exports[resource]==(resourceActive and 1 or 0) and current.imports[resource]==(resourceActive and 1 or 0),"resource import/export changed outside its quoted end turn")
    assert(current.open==bordersActive,"open borders changed outside its quoted end turn")
    if last~=turn then last=turn;LekmodScenarioEvent("diplomatic-expiry-progress",{turn=turn,gpt=current.us_gpt,export=current.exports[resource],open=current.open}) end
    if turn<deadline then return "turn" end
    assert(turn==deadline,"missed the observed expiry turn")
    LekmodScenarioRecord("diplomatic-contract-expiry","PASS","path=ordinary-turns exact-final-turn="..turn)
    LekmodScenarioRecord("expired-diplomatic-accounting","PASS","GPT-and-resource-import-export=0 open-borders=false")
    LekmodScenarioRecord("embassies-permanent","PASS","both-directions=true")
    return true
end
