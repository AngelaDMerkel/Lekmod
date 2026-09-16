function LekmodDiploVictorySnapshot(player)
    local league=assert(Game.GetActiveLeague())
    local minors={}
    for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do
        local p=Players[id]
        if p and p:IsAlive() and p:IsMinorCiv() then
            minors[id]={ally=p:GetAlly(),friendship=p:GetMinorCivFriendshipWithMajor(player:GetID()),personality=p:GetMinorCivPersonalityType()}
        end
    end
    return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),victory=Game.GetVictory(),gold=player:GetGold(),
        league=league:GetID(),un=league:IsUnitedNations(),session=league:IsInSession(),host=league:GetHostMember(),
        votes=league:GetRemainingVotesForMember(player:GetID()),starting=league:CalculateStartingVotesForMember(player:GetID()),
        required=Game.GetVotesNeededForDiploVictory(),proposals=league:GetEnactProposals(),minors=minors}
end
function LekmodDiploVictoryProposal(league,kind)
    for _,proposal in ipairs(league:GetEnactProposals()) do
        if proposal.Type==GameInfoTypes[kind] then return proposal end
    end
end
function LekmodDiploVictoryVote(league,proposal,player,votes)
    local eligible=false
    -- The proposal table's VoterDecision is the current decision result, not
    -- the decision type. Match LeagueOverview's definition lookup.
    local decisionType=GameInfo.Resolutions[proposal.Type].VoterDecision
    local decisionID=GameInfo.ResolutionDecisions[decisionType].ID
    local choices=league:GetChoicesForDecision(decisionID,player:GetID())
    local seen={}
    for _,choice in ipairs(choices) do
        assert(not seen[choice] and not Players[choice]:IsMinorCiv(),"duplicate or minor candidate in ballot")
        seen[choice]=true
        if choice==player:GetID() then eligible=true end
    end
    if proposal.Type==GameInfoTypes.RESOLUTION_DIPLOMATIC_VICTORY then
        assert(#choices==1 and choices[1]==player:GetID(),"human World Leader ballot is not self-only")
        LekmodScenarioRecord("world-leader-choices","PASS","path=engine-eligible-choices human=self-only no-duplicates=true")
    end
    assert(eligible and league:CanVote(player:GetID()) and votes>0,"human is not an eligible vote choice")
    Network.SendLeagueVoteEnact(league:GetID(),proposal.ID,player:GetID(),votes,player:GetID())
end
