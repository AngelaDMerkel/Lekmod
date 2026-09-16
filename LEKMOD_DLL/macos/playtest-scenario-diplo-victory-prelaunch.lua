include("LekmodTestDiploVictory.lua")
LekmodScenario={name="diplo-victory-prelaunch",items={"city-state-gifts","city-state-gift-rejection","un-session","world-leader-ready"}}
LekmodScenario.snapshot=LekmodDiploVictorySnapshot
local phase,minors,index,pending,gifts,attempts="init",{},1,nil,0,0
local function logLeague(player,league)
    LekmodScenarioEvent("un-progress",{turn=Game.GetGameTurn(),un=league:IsUnitedNations(),session=league:IsInSession(),
        countdown=league:GetTurnsUntilSession(),votes=league:GetRemainingVotesForMember(player:GetID()),
        starting=league:CalculateStartingVotesForMember(player:GetID()),required=Game.GetVotesNeededForDiploVictory()})
end
local lastTurn=-1
function LekmodScenario.step(player)
    local league=assert(Game.GetActiveLeague(),"use the Congress fixture")
    if phase=="init" then
        assert(Game.IsVictoryValid(GameInfoTypes.VICTORY_DIPLOMATIC) and Game.GetWinner()==-1,"diplomatic victory unavailable")
        if LEKMOD_RESUME_DIPLO_VICTORY then
            assert(league:IsUnitedNations(),"resume requires an existing UN fixture")
            LekmodScenarioEvent("resume-existing-un",{turn=Game.GetGameTurn(),gold=player:GetGold()})
        else
            LekmodScenarioGrantTech(player,"TECH_ATOMIC_THEORY")
            local before=player:GetGold();player:ChangeGold(20000)
            LekmodScenarioEvent("fixture-setup",{operation="provided-gold",before=before,added=20000})
        end
        for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do
            local p=Players[id]
            if p and p:IsAlive() and p:IsMinorCiv() then
                assert(not Teams[player:GetTeam()]:IsAtWar(p:GetTeam()),"city-state fixture is at war")
                if not Teams[player:GetTeam()]:IsHasMet(p:GetTeam()) then
                    Teams[player:GetTeam()]:Meet(p:GetTeam(),false)
                    LekmodScenarioEvent("fixture-setup",{operation="established-contact",minor=id})
                end
                minors[#minors+1]=id
            end
        end
        assert(#minors>0,"fixture has no city states")
        phase="gifts"
    elseif phase=="gifts" then
        local id=minors[index]
        if not id then
            local allies=0
            for _,minorID in ipairs(minors) do if Players[minorID]:GetAlly()==player:GetID() then allies=allies+1 end end
            if gifts>0 then
                LekmodScenarioRecord("city-state-gifts","PASS","path=normal-gold-gift-command attempts="..gifts.." allies="..allies)
            else
                LekmodScenarioEvent("inherited-city-state-alliances",{allies=allies,new_gifts=0})
            end
            phase="sessions";return false
        end
        local minor=Players[id]
        if pending then
            LekmodScenarioEvent("gold-gift-poll",{minor=id,gold=player:GetGold(),expected_gold=pending.gold-pending.amount,
                friendship=minor:GetMinorCivFriendshipWithMajor(player:GetID()),before_friendship=pending.friendship,ally=minor:GetAlly()})
            if pending.rejected then
                assert(player:GetGold()==pending.gold and minor:GetMinorCivFriendshipWithMajor(player:GetID())==pending.friendship,
                    "no-gifts personality accepted a gold gift")
                LekmodScenarioRecord("city-state-gift-rejection","PASS","path=normal-command personality="..pending.personality.." gold-and-friendship=unchanged")
                pending=nil;index=index+1;return false
            end
            if not LekmodScenarioAwait("gold-gift-"..gifts,player:GetGold()==pending.gold-pending.amount and minor:GetMinorCivFriendshipWithMajor(player:GetID())>pending.friendship) then return false end
            LekmodScenarioEvent("gold-gift-outcome",{minor=id,spent=pending.amount,before=pending.friendship,after=minor:GetMinorCivFriendshipWithMajor(player:GetID()),ally=minor:GetAlly()})
            pending=nil
        end
        if minor:GetAlly()==player:GetID() and minor:GetMinorCivFriendshipWithMajor(player:GetID())>=150 then index=index+1;return false end
        local amount=GameDefines.MINOR_GOLD_GIFT_LARGE
        assert(player:GetGold()>=amount and gifts<30,"gift budget exhausted")
        local personality=assert(GameInfo.Minor_Civ_Personalities[minor:GetMinorCivPersonalityType()])
        pending={amount=amount,gold=player:GetGold(),friendship=minor:GetMinorCivFriendshipWithMajor(player:GetID()),
            rejected=personality.NoGifts==true or personality.NoGifts==1,personality=personality.Type}
        gifts=gifts+1
        Game.DoMinorGoldGift(id,amount)
    elseif phase=="voted" then
        if not LekmodScenarioAwait("session-vote-spent-"..attempts,league:GetRemainingVotesForMember(player:GetID())==0) then return false end
        phase="sessions";return "turn"
    elseif phase=="sessions" then
        assert(Game.GetWinner()==-1,"fixture crossed victory before its saved final ballot")
        if Game.GetGameTurn()~=lastTurn then lastTurn=Game.GetGameTurn();logLeague(player,league) end
        if league:IsInSession() and league:CanVote(player:GetID()) then
            local proposal=LekmodDiploVictoryProposal(league,"RESOLUTION_DIPLOMATIC_VICTORY")
            local votes=league:GetRemainingVotesForMember(player:GetID())
            if proposal then
                assert(league:IsUnitedNations(),"World Leader without UN")
                if votes>=Game.GetVotesNeededForDiploVictory() then
                    LekmodScenarioRecord("un-session","PASS","path=ordinary-era-trigger-and-session-countdown")
                    LekmodScenarioRecord("world-leader-ready","PASS","votes="..votes.." required="..Game.GetVotesNeededForDiploVictory().." prior-ballots="..attempts)
                    return true
                end
                attempts=attempts+1
                assert(attempts<=3,"insufficient delegates after three prior ballots")
                LekmodScenarioEvent("world-leader-insufficient-ballot",{votes=votes,required=Game.GetVotesNeededForDiploVictory(),attempt=attempts})
                LekmodDiploVictoryVote(league,proposal,player,votes);phase="voted";return false
            end
            proposal=LekmodDiploVictoryProposal(league,"RESOLUTION_CHANGE_LEAGUE_HOST")
            if proposal then LekmodDiploVictoryVote(league,proposal,player,votes);phase="voted";return false end
        end
        return "turn"
    end
    return false
end
