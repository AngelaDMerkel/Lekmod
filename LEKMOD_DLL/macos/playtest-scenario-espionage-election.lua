-- Existing spy, normal relocation/coup commands and ordinary election timing.
-- Contact, visibility and starting influence are explicitly supplied inputs.
-- No spy progress, rank, election clock, RNG or coup outcome is assigned.
LekmodScenario={name="espionage-election",items={"counterspy-arrival","minor-spy-surveillance","spy-election","spy-coup-outcome","coup-restrictions"}}
local phase,agent,minorID,start,arrival,ledger,coupBefore="init"
local function spy(player)
    for _,s in ipairs(player:GetEspionageSpies()) do if s.AgentID==agent then return s end end
    error("fixture spy disappeared")
end
local function send(player,owner,city)
    local legal=false
    for _,c in ipairs(player:GetAvailableSpyRelocationCities(agent)) do
        if c.PlayerID==owner and c.CityID==city:GetID() then legal=true;break end
    end
    assert(legal,"spy destination not in normal relocation list")
    Network.SendMoveSpy(player:GetID(),agent,owner,city:GetID(),false)
    LekmodScenarioEvent("spy-command",{agent=agent,owner=owner,city=city:GetID(),path="normal-network"})
end
local function influence(minor,owner,value)
    local before=minor:GetMinorCivFriendshipWithMajor(owner)
    minor:ChangeMinorCivFriendshipWithMajor(owner,value-before)
    LekmodScenarioEvent("fixture-setup",{operation="provided-influence",minor=minor:GetID(),major=owner,before=before,added=value-before})
end
function LekmodScenario.snapshot(player)
    local minors={}
    for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id]
        if p and p:IsAlive() and p:IsMinorCiv() then
            minors[id]={ally=p:GetAlly(),human=p:GetMinorCivFriendshipWithMajor(player:GetID()),ai=p:GetMinorCivFriendshipWithMajor(1)}
        end
    end
    return {turn=Game.GetGameTurn(),election=Game.GetTurnsUntilMinorCivElection(),spies=player:GetEspionageSpies(),minors=minors}
end
function LekmodScenarioBeforeEndTurn(player,turn)
    if phase=="election" then
        local minor=Players[minorID]
        ledger={turn=turn,friendship=minor:GetMinorCivFriendshipWithMajor(player:GetID()),decay100=minor:GetFriendshipChangePerTurnTimes100(player:GetID()),until_election=Game.GetTurnsUntilMinorCivElection()}
        LekmodScenarioEvent("election-ledger-before",ledger)
    end
end
local function electionOutcome(player,city)
    for i=0,player:GetNumNotifications()-1 do
        if player:GetNotificationTurn(i)>=arrival then
            local summary=player:GetNotificationSummaryStr(i)
            for _,kind in ipairs({"SUCCESS","FAILURE"}) do
                if summary==Locale.ConvertTextKey("TXT_KEY_NOTIFICATION_SPY_RIG_ELECTION_"..kind.."_S",city:GetNameKey()) then return kind end
            end
        end
    end
end
function LekmodScenario.step(player)
    start=start or Game.GetGameTurn()
    assert(Game.GetGameTurn()-start<=28,"espionage case exceeded 28 ordinary turns")
    if phase=="init" then
        for _,s in ipairs(player:GetEspionageSpies()) do if s.State=="TXT_KEY_SPY_STATE_UNASSIGNED" then agent=s.AgentID;break end end
        assert(agent~=nil,"existing unassigned spy required")
        assert(not player:CanSpyStageCoup(agent),"unassigned spy can stage a coup")
        send(player,player:GetID(),player:GetCapitalCity());phase="home";return false
    elseif phase=="home" then
        local s=spy(player)
        if s.State~="TXT_KEY_SPY_STATE_COUNTER_INTEL" then return "turn" end
        assert(s.CityX==player:GetCapitalCity():GetX() and s.CityY==player:GetCapitalCity():GetY(),"counterspy arrived in wrong city")
        assert(not player:CanSpyStageCoup(agent),"counterspy can stage a coup at home")
        LekmodScenarioRecord("counterspy-arrival","PASS","path=ordinary-travel state=counter-intelligence not-intruder-capture")
        for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id]
            if p and p:IsAlive() and p:IsMinorCiv() and p:GetCapitalCity() and not Teams[player:GetTeam()]:IsAtWar(p:GetTeam()) then minorID=id;break end
        end
        local minor=assert(Players[minorID]);local city=minor:GetCapitalCity()
        for _,p in ipairs({player,Players[1]}) do
            if not Teams[p:GetTeam()]:IsHasMet(minor:GetTeam()) then Teams[p:GetTeam()]:Meet(minor:GetTeam(),false) end
        end
        if not city:Plot():IsRevealed(player:GetTeam()) then city:Plot():SetRevealed(player:GetTeam(),true) end
        LekmodScenarioEvent("fixture-setup",{operation="provided-contact-and-capital-visibility",minor=minorID})
        influence(minor,1,140);influence(minor,player:GetID(),70)
        assert(minor:GetAlly()==1,"provided AI influence did not establish the fixture alliance")
        send(player,minorID,city);phase="minor";return false
    elseif phase=="minor" then
        local s=spy(player)
        if s.State=="TXT_KEY_SPY_STATE_TRAVELLING" then assert(not player:CanSpyStageCoup(agent),"travelling spy can coup") end
        if s.State~="TXT_KEY_SPY_STATE_RIGGING_ELECTION" then return "turn" end
        arrival=Game.GetGameTurn()
        assert(s.CityX==Players[minorID]:GetCapitalCity():GetX() and s.CityY==Players[minorID]:GetCapitalCity():GetY(),"spy arrived in wrong minor city")
        assert(player:HasSpyEstablishedSurveillance(agent),"minor spy lacks established surveillance")
        LekmodScenarioRecord("minor-spy-surveillance","PASS","path=normal-travel-and-surveillance state=rigging-elections")
        LekmodScenarioEvent("election-wait",{turn=arrival,until_election=Game.GetTurnsUntilMinorCivElection(),period=Game.GetTurnsBetweenMinorCivElections()})
        phase="election";return "turn"
    elseif phase=="election" then
        local minor=Players[minorID];local city=minor:GetCapitalCity();local outcome=electionOutcome(player,city)
        if not outcome then return "turn" end
        assert(ledger,"missing pre-election influence ledger")
        local delta=minor:GetMinorCivFriendshipWithMajor(player:GetID())-ledger.friendship
        if outcome=="SUCCESS" then
            assert(delta>0,"successful election did not increase influence")
        else assert(delta<0,"lost election did not reduce positive influence") end
        LekmodScenarioEvent("election-result",{outcome=outcome,delta=delta,before=ledger,after=minor:GetMinorCivFriendshipWithMajor(player:GetID())})
        LekmodScenarioRecord("spy-election","PASS","path=scheduled-election outcome="..outcome.." influence-delta="..delta)
        -- Supply a small influence gap for a meaningful, capped coup chance.
        -- The engine still makes the actual random decision.
        local human=minor:GetMinorCivFriendshipWithMajor(player:GetID())
        influence(minor,player:GetID(),math.max(human,100));human=minor:GetMinorCivFriendshipWithMajor(player:GetID())
        influence(minor,1,human+10)
        assert(minor:GetAlly()==1 and player:CanSpyStageCoup(agent),"coup not eligible after legitimate surveillance")
        coupBefore={turn=Game.GetGameTurn(),human=human,ai=minor:GetMinorCivFriendshipWithMajor(1),chance=player:GetCoupChanceOfSuccess(city),gold=player:GetGold()}
        assert(coupBefore.chance>0 and coupBefore.chance<=85,"coup chance outside normal cap")
        LekmodScenarioEvent("coup-before",coupBefore)
        Network.SendStageCoup(player:GetID(),agent);phase="coup";return false
    elseif phase=="coup" then
        local minor=Players[minorID];local s=spy(player);local won=minor:GetAlly()==player:GetID();local died=s.State=="TXT_KEY_SPY_STATE_DEAD"
        if not LekmodScenarioAwait("coup-resolved",won or died) then return false end
        assert(won~=died,"coup both won and killed the spy")
        assert(Game.GetGameTurn()==coupBefore.turn and player:GetGold()==coupBefore.gold,"coup unexpectedly advanced a turn or spent gold")
        if won then
            assert(math.abs(minor:GetMinorCivFriendshipWithMajor(player:GetID())-coupBefore.ai)<=1,"successful coup did not transfer the prior ally's influence")
        else
            assert(minor:GetAlly()==1 and minor:GetMinorCivFriendshipWithMajor(player:GetID())==-10 and s.CityX==-1 and s.CityY==-1,"failed coup did not kill/extract spy and apply -10 influence")
        end
        assert(not player:CanSpyStageCoup(agent),"own-ally or dead spy remains coup-eligible")
        LekmodScenarioEvent("coup-result",{outcome=won and "success" or "failure",spy=s,human=minor:GetMinorCivFriendshipWithMajor(player:GetID()),ai=minor:GetMinorCivFriendshipWithMajor(1)})
        LekmodScenarioRecord("spy-coup-outcome","PASS","path=normal-network-command outcome="..(won and "success" or "failure"))
        LekmodScenarioRecord("coup-restrictions","PASS","unassigned-home-travelling-and-after-outcome=rejected")
        return true
    end
    return false
end
