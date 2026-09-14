-- Small, ordinary Industrial setup. Explicit contact/gold inputs create a
-- bounded fixture; session timing, production, votes and results are unchanged.
LekmodScenario={name="congress",items={"congress-found","congress-propose","congress-vote","congress-resolve","wonder-completion","process-income"}}
local phase,initialized,wonder,wonderEvent,wonderDone,processQueued,processDone,ledger="init",false,nil,false,false,false,false,nil
local processWarmed=false
local proposalType,proposalID,votesBefore,voteSent,panelDone
local wealth=GameInfoTypes.PROCESS_WEALTH
LuaEvents.LekmodScenarioLeaguePanelDone.Add(function(kind) panelDone=kind end)
GameEvents.CityConstructed.Add(function(owner,city,building,gold,faith)
    if owner==0 and building==wonder and not gold and not faith then wonderEvent=true end
end)
local function isActive(league,id)
    for _,resolution in ipairs(league:GetActiveResolutions()) do if resolution.ID==id then return true end end
    return false
end
local function production(player,city)
    if not wonderDone and wonderEvent and city:GetNumRealBuilding(wonder)==1 then
        wonderDone=true
        LekmodScenarioRecord("wonder-completion","PASS","path=ordinary-production building="..wonder.." type="..GameInfo.Buildings[wonder].Type)
        Game.CityPushOrder(city,OrderTypes.ORDER_MAINTAIN,wealth,false,true,true)
        processQueued=true
        return true
    end
    if processQueued and not processDone and ledger and Game.GetGameTurn()>ledger.turn then
        assert(Game.GetGameTurn()==ledger.turn+1, "process ledger skipped a turn")
        local delta=player:GetGold()-ledger.gold
        assert(player.GetLastGoldChangeTimes100, "GameCore lacks the read-only settled-income getter")
        local committed=player:GetLastGoldChangeTimes100()
        LekmodScenarioEvent("process-ledger-after",{gold=player:GetGold(),delta=delta,forecast100=ledger.rate100,committed100=committed})
        if not processWarmed then
            -- The just-completed wonder sets PRODUCTION_TO_YIELD_FIX's
            -- finished-order guard. Let a normal process turn clear that guard
            -- before comparing the steady-state rate; do not clear it manually.
            processWarmed=true;ledger=nil
            LekmodScenarioEvent("process-transition",{scope="finished-order-to-wealth",delta=delta})
            return false
        end
        assert(math.abs(delta-committed/100)<1.01, "process treasury settlement differs from the committed amount")
        processDone=true
        LekmodScenarioRecord("process-income","PASS","path=wealth-and-ordinary-turn delta="..delta.." committed100="..committed.." conversion100="..ledger.conversion100)
    end
end
function LekmodScenarioBeforeEndTurn(player,turn)
    if processQueued and not processDone then
        local city=player:GetCapitalCity()
        local kind,id=city:GetOrderFromQueue(0)
        assert(kind==OrderTypes.ORDER_MAINTAIN and id==wealth, "wealth process not in the city queue")
        local modifier
        for row in GameInfo.Process_ProductionYields{ProcessType="PROCESS_WEALTH",YieldType="YIELD_GOLD"} do modifier=row.Yield;break end
        assert(modifier and modifier>0, "Wealth has no gold conversion")
        local conversion=math.floor(city:GetYieldRateTimes100(YieldTypes.YIELD_PRODUCTION)*modifier/100)
        assert(conversion>0, "Wealth has no production to convert")
        ledger={turn=turn,gold=player:GetGold(),rate100=player:CalculateGoldRateTimes100(),conversion100=conversion}
        LekmodScenarioEvent("process-ledger-before",ledger)
    end
end
function LekmodScenario.snapshot(player)
    local league=Game.GetActiveLeague()
    local city=player:GetCapitalCity()
    local buildings={}
    if city then
        for info in GameInfo.Buildings() do
            if city:GetNumRealBuilding(info.ID)>0 then buildings[info.ID]=city:GetNumRealBuilding(info.ID) end
        end
    end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),city=city and city:GetID() or -1,buildings=buildings,
        league=league and {id=league:GetID(),host=league:GetHostMember(),session=league:IsInSession(),
            turns=league:GetTurnsUntilSession(),votes=league:GetRemainingVotesForMember(player:GetID()),
            proposals=league:GetEnactProposals(),active=league:GetActiveResolutions()} or false}
end
function LekmodScenario.step(player)
    local city=player:GetCapitalCity()
    if not city then return "turn" end -- The normal human driver legally founds it.
    if not initialized then
        assert(Teams[player:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_PRINTING_PRESS), "use an ordinary Industrial start")
        local old=player:GetGold();player:ChangeGold(2000)
        LekmodScenarioEvent("fixture-setup",{operation="provided-gold",before=old,added=2000,after=player:GetGold()})
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
            local other=Players[id]
            if other and other:IsAlive() and other:GetTeam()~=player:GetTeam() and not Teams[player:GetTeam()]:IsHasMet(other:GetTeam()) then
                Teams[player:GetTeam()]:Meet(other:GetTeam(),false)
                LekmodScenarioEvent("fixture-setup",{operation="established-contact",team=other:GetTeam()})
            end
        end
        local preferred=GameInfo.Buildings.BUILDING_GLOBE_THEATER
        if preferred and city:CanConstruct(preferred.ID) then wonder=preferred.ID end
        if not wonder then
            local best=999
            for info in GameInfo.Buildings() do
                local class=GameInfo.BuildingClasses[info.BuildingClass]
                if class and class.MaxGlobalInstances==1 and city:CanConstruct(info.ID) then
                    local turns=city:GetBuildingProductionTurnsLeft(info.ID,0)
                    if turns<best then wonder,best=info.ID,turns end
                end
            end
        end
        assert(wonder and city:GetBuildingProductionTurnsLeft(wonder,0)<=22, "fixture has no bounded legal world wonder")
        Game.CityPushOrder(city,OrderTypes.ORDER_CONSTRUCT,wonder,false,true,true)
        LekmodScenarioEvent("world-wonder-order",{building=wonder,type=GameInfo.Buildings[wonder].Type,estimated_turns=city:GetBuildingProductionTurnsLeft(wonder,0)})
        initialized=true;phase="found"
        return false
    end
    if production(player,city) then return false end
    if processQueued and not processDone then
        local order,item=city:GetOrderFromQueue(0)
        if not LekmodScenarioAwait("wealth-queue",order==OrderTypes.ORDER_MAINTAIN and item==wealth) then return false end
    end
    local league=Game.GetActiveLeague()
    if phase=="found" then
        if not league then return "turn" end
        assert(league:IsMember(player:GetID()), "human is not a Congress member")
        LekmodScenarioRecord("congress-found","PASS","path=ordinary-eligibility league="..league:GetID().." countdown="..league:GetTurnsUntilSession())
        panelDone=nil;LuaEvents.LekmodScenarioLeaguePanel(league:GetID(),"proposals");phase="proposal-panel"
    elseif phase=="proposal-panel" then
        if not panelDone then return false end
        assert(league:CanPropose(player:GetID()), "human has no proposal privilege")
        for _,name in ipairs({"RESOLUTION_ARTS_FUNDING","RESOLUTION_SCIENCES_FUNDING","RESOLUTION_NATURAL_HERITAGE_SITES","RESOLUTION_STANDING_ARMY_TAX"}) do
            local info=GameInfo.Resolutions[name]
            if info and league:CanProposeEnact(info.ID,player:GetID(),-1) then proposalType=info.ID;break end
        end
        assert(proposalType, "no legal ongoing proposal in fixture")
        Network.SendLeagueProposeEnact(league:GetID(),proposalType,player:GetID(),-1)
        phase="proposed"
    elseif phase=="proposed" then
        for _,proposal in ipairs(league:GetEnactProposals()) do
            if proposal.Type==proposalType and proposal.ProposalPlayer==player:GetID() then proposalID=proposal.ID;break end
        end
        if not LekmodScenarioAwait("congress-proposal",proposalID~=nil) then return false end
        LekmodScenarioEvent("congress-proposal",{id=proposalID,type=proposalType})
        LekmodScenarioRecord("congress-propose","PASS","path=normal-network-command proposal="..proposalID)
        phase="wait-session"
    elseif phase=="wait-session" then
        if not league:IsInSession() then return "turn" end
        assert(league:CanVote(player:GetID()), "human has no session votes")
        panelDone=nil;LuaEvents.LekmodScenarioLeaguePanel(league:GetID(),"votes");phase="vote-panel"
    elseif phase=="vote-panel" then
        if not panelDone then return false end
        votesBefore=league:GetRemainingVotesForMember(player:GetID())
        assert(votesBefore>0, "no votes to cast")
        Network.SendLeagueVoteEnact(league:GetID(),proposalID,player:GetID(),votesBefore,1)
        voteSent=true;phase="voted"
    elseif phase=="voted" then
        if not LekmodScenarioAwait("congress-vote",league:GetRemainingVotesForMember(player:GetID())==0) then return false end
        LekmodScenarioRecord("congress-vote","PASS","path=normal-network-command votes="..votesBefore.." choice=yes")
        phase="resolved"
    elseif phase=="resolved" then
        if league:IsInSession() then return "turn" end
        assert(voteSent, "session ended without the human vote")
        LekmodScenarioEvent("congress-resolved",{id=proposalID,active=isActive(league,proposalID)})
        LekmodScenarioRecord("congress-resolve","PASS","scope=session-ended engine-result-crosscheck=required")
        phase="finish-production"
    elseif phase=="finish-production" then
        if not (wonderDone and processDone) then return "turn" end
        return true
    end
    return false
end
