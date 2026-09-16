include("LekmodTestDiploVictory.lua")
LekmodScenario={name="diplo-victory-launch",items={"world-leader-vote","diplomatic-victory","victory-panel"}}
LekmodScenario.snapshot=LekmodDiploVictorySnapshot
local submitted=false
function LekmodScenario.step(player)
    if submitted then
        if Game.GetWinner()~=-1 then return false end
        return "turn"
    end
    local league=assert(Game.GetActiveLeague())
    local proposal=assert(LekmodDiploVictoryProposal(league,"RESOLUTION_DIPLOMATIC_VICTORY"),"no World Leader proposal")
    local votes=league:GetRemainingVotesForMember(player:GetID())
    assert(Game.GetWinner()==-1 and votes>=Game.GetVotesNeededForDiploVictory(),"fixture is not ready for winning ballot")
    LuaEvents.LekmodDiploFinal(league:GetID(),proposal.ID,votes)
    LekmodScenarioEvent("world-leader-before-final",LekmodDiploVictorySnapshot(player))
    LekmodDiploVictoryVote(league,proposal,player,votes);submitted=true
    return false
end
