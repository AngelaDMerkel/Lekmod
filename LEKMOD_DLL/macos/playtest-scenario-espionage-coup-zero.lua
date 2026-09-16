-- Supply an influence gap, then let the real coup command/RNG resolve failure.
-- The spy must already have earned surveillance in the saved fixture.
LekmodScenario={name="espionage-coup-zero",items={"coup-zero-chance","coup-failure","dead-spy-restrictions"}}
local phase,agent,minorID,before,checks="init"
local function findSpy(player,id)
    for _,s in ipairs(player:GetEspionageSpies()) do if s.AgentID==id then return s end end
end
function LekmodScenario.snapshot(player)
    local minors={}
    for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id]
        if p and p:IsAlive() and p:IsMinorCiv() then minors[id]={ally=p:GetAlly(),human=p:GetMinorCivFriendshipWithMajor(player:GetID()),ai=p:GetMinorCivFriendshipWithMajor(1)} end
    end
    return {turn=Game.GetGameTurn(),spies=player:GetEspionageSpies(),minors=minors,gold=player:GetGold()}
end
function LekmodScenario.step(player)
    if phase=="init" then
        for _,s in ipairs(player:GetEspionageSpies()) do
            if s.State=="TXT_KEY_SPY_STATE_RIGGING_ELECTION" and s.EstablishedSurveillance then
                local c=Map.GetPlot(s.CityX,s.CityY):GetPlotCity()
                if c and Players[c:GetOwner()]:IsMinorCiv() then agent=s.AgentID;minorID=c:GetOwner();break end
            end
        end
        assert(agent~=nil,"load a spy with established city-state surveillance")
        local minor=Players[minorID];local old=minor:GetMinorCivFriendshipWithMajor(1)
        local value=minor:GetMinorCivFriendshipWithMajor(player:GetID())+1000
        minor:ChangeMinorCivFriendshipWithMajor(1,value-old)
        LekmodScenarioEvent("fixture-setup",{operation="provided-AI-influence-gap",minor=minorID,before=old,added=value-old})
        assert(minor:GetAlly()==1 and player:CanSpyStageCoup(agent),"zero-chance coup is not otherwise eligible")
        assert(player:GetCoupChanceOfSuccess(minor:GetCapitalCity())==0,"fixture did not reach zero percent")
        LekmodScenarioRecord("coup-zero-chance","PASS","quoted-percent=0 eligible-surveillance=true")
        before={turn=Game.GetGameTurn(),gold=player:GetGold(),ai=minor:GetMinorCivFriendshipWithMajor(1)}
        Network.SendStageCoup(player:GetID(),agent);phase="failed";return false
    elseif phase=="failed" then
        local s=assert(findSpy(player,agent));local minor=Players[minorID]
        if not LekmodScenarioAwait("zero-coup-resolved",s.State=="TXT_KEY_SPY_STATE_DEAD" or minor:GetAlly()==player:GetID()) then return false end
        LekmodScenarioEvent("zero-coup-result",{spy=s,ally=minor:GetAlly(),human=minor:GetMinorCivFriendshipWithMajor(player:GetID()),ai=minor:GetMinorCivFriendshipWithMajor(1)})
        assert(s.State=="TXT_KEY_SPY_STATE_DEAD" and s.CityX==-1 and s.CityY==-1,"zero-percent coup unexpectedly succeeded or failed to extract the dead spy")
        assert(minor:GetAlly()==1 and minor:GetMinorCivFriendshipWithMajor(1)==before.ai,"failed coup changed the AI alliance/influence")
        assert(minor:GetMinorCivFriendshipWithMajor(player:GetID())==-10,"failed coup did not apply -10 influence")
        assert(player:GetGold()==before.gold and Game.GetGameTurn()==before.turn,"coup spent gold or advanced a turn")
        LekmodScenarioRecord("coup-failure","PASS","path=normal-command spy=dead influence=-10")
        assert(not player:CanSpyStageCoup(agent),"dead spy remains coup eligible")
        LekmodScenarioEvent("dead-spy-destinations",{count=#player:GetAvailableSpyRelocationCities(agent)})
        -- Exercise rejection through the ordinary command as well as the query.
        Network.SendMoveSpy(player:GetID(),agent,player:GetID(),player:GetCapitalCity():GetID(),false)
        checks=0;phase="dead-command";return false
    elseif phase=="dead-command" then
        checks=checks+1;if checks<2 then return false end
        local s=assert(findSpy(player,agent))
        LekmodScenarioEvent("dead-spy-after-command",s)
        assert(s.State=="TXT_KEY_SPY_STATE_DEAD" and s.CityX==-1 and s.CityY==-1,"normal relocation command revived a dead spy before replacement")
        assert(#player:GetAvailableSpyRelocationCities(agent)==0,"dead spy still has relocation destinations")
        LekmodScenarioRecord("dead-spy-restrictions","PASS","coup-and-relocation=rejected")
        return true
    end
    return false
end
