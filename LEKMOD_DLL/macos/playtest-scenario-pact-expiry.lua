LekmodScenario={name="pact-expiry",items={"pact-duration","pact-expiry","war-eligibility-restored"}}
local deadline,start,last
local function state(player)
    local other=Players[1];local a,b=Teams[player:GetTeam()],Teams[other:GetTeam()]
    return {turn=Game.GetGameTurn(),ours=a:IsDefensivePact(other:GetTeam()),theirs=b:IsDefensivePact(player:GetTeam()),
        us_can_war=a:CanDeclareWar(other:GetTeam()),them_can_war=b:CanDeclareWar(player:GetTeam()),war=a:IsAtWar(other:GetTeam()),friendship=player:IsDoF(1)}
end
function LekmodScenario.snapshot(player) return state(player) end
function LekmodScenario.step(player)
    if not deadline then
        local deal=UI.GetScratchDeal();local items=0;start=Game.GetGameTurn()
        for i=0,UI.GetNumCurrentDeals(player:GetID())-1 do
            UI.LoadCurrentDeal(player:GetID(),i);deal:ResetIterator()
            while true do local kind,duration,finish=deal:GetNextItem();if kind==nil then break end
                if kind==TradeableItems.TRADE_ITEM_DEFENSIVE_PACT then
                    assert(duration==10,"configured pact duration is not ten")
                    assert(not deadline or deadline==finish,"bilateral pact end turns differ")
                    deadline=finish;items=items+1
                end
            end
        end
        assert(items==2 and deadline>start and deadline-start<=10,"load the fresh bilateral pact fixture")
        LekmodScenarioEvent("existing-pact-terms",{start=start,finish=deadline,items=items})
        LekmodScenarioRecord("pact-duration","PASS","actual-bilateral-duration=10")
    end
    local s=state(player);assert(not s.war,"war began while testing pact expiry")
    if last~=s.turn then last=s.turn;LekmodScenarioEvent("pact-expiry-progress",s) end
    if s.turn<deadline then
        assert(s.ours and s.theirs and not s.us_can_war and not s.them_can_war,"pact protection ended before the quoted final turn")
        return "turn"
    end
    assert(s.turn==deadline and not s.ours and not s.theirs,"pact did not end on its quoted turn")
    assert(s.us_can_war and s.them_can_war,"ordinary war eligibility did not return after pact expiry")
    LekmodScenarioRecord("pact-expiry","PASS","path=ordinary-turns exact-end="..deadline)
    LekmodScenarioRecord("war-eligibility-restored","PASS","both-directions=true no-war-declared=true")
    return true
end
