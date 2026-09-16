LekmodScenario={name="peace-expiry",items={"peace-duration","peace-expiry","post-peace-war-eligibility"}}
local deadline,last
function LekmodScenario.snapshot(player)
    local p=Players[1];local a,b=Teams[player:GetTeam()],Teams[p:GetTeam()]
    return {turn=Game.GetGameTurn(),war=a:IsAtWar(p:GetTeam()),ours=a:IsForcePeace(p:GetTeam()),theirs=b:IsForcePeace(player:GetTeam()),
        us_can_war=a:CanDeclareWar(p:GetTeam()),them_can_war=b:CanDeclareWar(player:GetTeam())}
end
function LekmodScenario.step(player)
    if not deadline then
        local deal=UI.GetScratchDeal();local items=0
        for i=0,UI.GetNumCurrentDeals(player:GetID())-1 do
            UI.LoadCurrentDeal(player:GetID(),i);deal:ResetIterator()
            while true do local kind,duration,finish=deal:GetNextItem();if kind==nil then break end
                if kind==TradeableItems.TRADE_ITEM_PEACE_TREATY then
                    assert(duration==5,"AI peace duration differs from the shipped rule")
                    assert(not deadline or deadline==finish,"bilateral peace end turns differ")
                    deadline=finish;items=items+1
                end
            end
        end
        assert(items==2 and deadline>Game.GetGameTurn() and deadline-Game.GetGameTurn()<=5,"load the accepted five-turn peace fixture")
        LekmodScenarioEvent("existing-peace-terms",{start=Game.GetGameTurn(),finish=deadline,items=items})
        LekmodScenarioRecord("peace-duration","PASS","actual-bilateral-duration=5")
    end
    local s=LekmodScenario.snapshot(player);assert(not s.war,"war resumed during the peace expiry case")
    if last~=s.turn then last=s.turn;LekmodScenarioEvent("peace-expiry-progress",s) end
    if s.turn<deadline then
        assert(s.ours and s.theirs and not s.us_can_war and not s.them_can_war,"peace protection ended before its quoted turn")
        return "turn"
    end
    assert(s.turn==deadline and not s.ours and not s.theirs,"peace flags did not end at their quoted turn")
    assert(s.us_can_war and s.them_can_war,"war eligibility did not return after peace expiry")
    LekmodScenarioRecord("peace-expiry","PASS","path=ordinary-turns exact-end="..deadline)
    LekmodScenarioRecord("post-peace-war-eligibility","PASS","both-directions=true no-war-declared=true")
    return true
end
