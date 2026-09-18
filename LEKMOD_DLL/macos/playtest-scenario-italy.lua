-- Supplied prerequisite policies/free choices and Artists; the final policies
-- are legally adopted, and both rewards come from real engine events.
LekmodScenario={name="italy",items={"italy-human-points","italy-AI-points","italy-human-extension","italy-AI-extension"}}
local phase,pending,aiDone,commandError,before,artist="init"
local tradition,honor=GameInfoTypes.POLICY_BRANCH_TRADITION,GameInfoTypes.POLICY_BRANCH_HONOR
local points=math.floor(312.5*GameInfo.GameSpeeds[Game.GetGameSpeedType()].GoldenAgePercent/100)
local extension=math.floor(5*GameInfo.GameSpeeds[Game.GetGameSpeedType()].GoldenAgePercent/100)
local function check(name,condition,detail)
    LekmodScenarioRecord(name,condition and "PASS" or "FAIL",detail)
end
local function prepare(p,branch,last)
    assert(not p:IsPolicyBranchFinished(branch) and not p:HasPolicy(last),"branch already finished")
    p:SetPolicyBranchUnlocked(branch,true,false)
    p:SetHasPolicy(branch==tradition and GameInfoTypes.POLICY_TRADITION or GameInfoTypes.POLICY_HONOR,true)
    local policies={}
    for info in GameInfo.Policies() do
        if info.PolicyBranchType==GameInfo.PolicyBranchTypes[branch].Type and info.ID~=last then
            p:SetHasPolicy(info.ID,true);policies[#policies+1]=info.ID
        end
    end
    p:SetNumFreePolicies(p:GetNumFreePolicies()+1)
    LekmodScenarioEvent("fixture-setup",{operation="provided-branch-prerequisites-and-one-free-policy",owner=p:GetID(),branch=branch,policies=policies,last=last})
    assert(p:CanAdoptPolicy(last),"prepared final policy is not legally adoptable")
end
local function provideArtist(p)
    local c=assert(p:GetCapitalCity());local u=assert(p:InitUnit(GameInfoTypes.UNIT_ARTIST,c:GetX(),c:GetY()))
    LekmodScenarioEvent("fixture-setup",{operation="provided-artist",owner=p:GetID(),unit=u:GetID()})
    return u
end
GameEvents.PlayerDoTurn.Add(function(owner)
    if owner~=1 or not pending then return end
    local kind=pending;pending=nil
    local ok,err=pcall(function()
        local p=Players[owner];assert(p:IsTurnActive(),"AI reward command outside owner turn")
        local last,baseline,expected
        if kind=="points" then
            assert(not p:IsGoldenAge(),"AI already golden before point award")
            last=GameInfoTypes.POLICY_MONARCHY;prepare(p,tradition,last)
            baseline=p:GetGoldenAgeProgressMeter();expected=points
        else
            assert(not p:IsGoldenAge(),"AI already golden before supplied Artist")
            local u=provideArtist(p)
            assert(u:CanStartMission(GameInfoTypes.MISSION_GOLDEN_AGE,-1,-1,u:GetPlot(),0),"AI Artist cannot start golden age")
            u:PushMission(GameInfoTypes.MISSION_GOLDEN_AGE,-1,-1,0,0,1)
            assert(p:IsGoldenAge(),"normal AI Artist mission did not start golden age")
            last=GameInfoTypes.POLICY_PROFESSIONAL_ARMY;prepare(p,honor,last)
            baseline=p:GetGoldenAgeTurns();expected=extension
        end
        local free=p:GetNumFreePolicies();p:DoAdoptPolicy(last)
        assert(p:HasPolicy(last) and p:GetNumFreePolicies()==free-1,"normal AI policy command did not apply/spend one choice")
        local after=kind=="points" and p:GetGoldenAgeProgressMeter() or p:GetGoldenAgeTurns()
        LekmodScenarioEvent("italy-AI-reward",{kind=kind,before=baseline,after=after,expected=expected,owner_active=p:IsTurnActive(),active_human=Game.GetActivePlayer()})
        check("italy-AI-"..(kind=="points" and "points" or "extension"),after-baseline==expected,"path=legal-owner-turn-policy-adoption actual="..(after-baseline).." expected="..expected)
        aiDone=kind
    end)
    if not ok then commandError=tostring(err) end
end)
function LekmodScenario.snapshot(player)
    local result={}
    for id=0,1 do local p=Players[id]
        result[id]={civ=p:GetCivilizationType(),tradition=p:IsPolicyBranchFinished(tradition),honor=p:IsPolicyBranchFinished(honor),points=p:GetGoldenAgeProgressMeter(),golden=p:GetGoldenAgeTurns(),free=p:GetNumFreePolicies()}
    end
    return {turn=Game.GetGameTurn(),players=result}
end
function LekmodScenario.step(player)
    if commandError then LekmodScenarioRecord("italy-command","FAIL",commandError);return true end
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ITALY and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ITALY,"select human and AI Italy")
    if not player:GetCapitalCity() or not Players[1]:GetCapitalCity() then return "turn" end
    if phase=="init" then
        assert(not player:IsGoldenAge(),"human already golden before point award")
        prepare(player,tradition,GameInfoTypes.POLICY_MONARCHY);before=player:GetGoldenAgeProgressMeter()
        Network.SendUpdatePolicies(GameInfoTypes.POLICY_MONARCHY,true,true);phase="human-points"
    elseif phase=="human-points" then
        if not LekmodScenarioAwait("human-Tradition-finished",player:IsPolicyBranchFinished(tradition)) then return false end
        check("italy-human-points",player:GetGoldenAgeProgressMeter()-before==points,"path=normal-policy-command actual="..(player:GetGoldenAgeProgressMeter()-before).." expected="..points)
        pending="points";phase="AI-points";return "turn"
    elseif phase=="AI-points" then
        if aiDone~="points" then return "turn" end
        local u=provideArtist(player);artist=u:GetID();phase="artist"
    elseif phase=="artist" then
        UI.SelectUnit(assert(player:GetUnitByID(artist)))
        local action
        for id=0,#GameInfoActions do if GameInfoActions[id] and GameInfoActions[id].Type=="MISSION_GOLDEN_AGE" then action=id;break end end
        assert(action and Game.CanHandleAction(action),"normal human Artist action unavailable")
        Game.HandleAction(action);phase="golden"
    elseif phase=="golden" then
        if not LekmodScenarioAwait("human-Artist-golden-age",player:IsGoldenAge()) then return false end
        prepare(player,honor,GameInfoTypes.POLICY_PROFESSIONAL_ARMY);before=player:GetGoldenAgeTurns()
        Network.SendUpdatePolicies(GameInfoTypes.POLICY_PROFESSIONAL_ARMY,true,true);phase="human-extension"
    elseif phase=="human-extension" then
        if not LekmodScenarioAwait("human-Honor-finished",player:IsPolicyBranchFinished(honor)) then return false end
        check("italy-human-extension",player:GetGoldenAgeTurns()-before==extension,"path=normal-policy-command actual="..(player:GetGoldenAgeTurns()-before).." expected="..extension)
        pending="extension";phase="AI-extension";return "turn"
    elseif phase=="AI-extension" then
        if aiDone~="extension" then return "turn" end
        return true
    end
    return false
end
