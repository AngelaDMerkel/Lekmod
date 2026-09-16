LekmodScenario={name="cuba-ideology",items={"ideology-cancel","ideology-selected","tenet-cancel","cuba-first-tenet-reward","cuba-later-tenet-no-repeat","tenet-restrictions"}}
local phase,started,chosen,reply,policy,first,unitsBefore,culture,free,cost="init"
local ideology=GameInfoTypes.POLICY_BRANCH_FREEDOM
local adopted={}
LuaEvents.LekmodIdeologyChosen.Add(function(id) chosen=id end)
LuaEvents.LekmodTenetChosen.Add(function(id) reply=id end)
GameEvents.PlayerAdoptPolicy.Add(function(owner,id) if owner==Game.GetActivePlayer() then adopted[id]=true end end)
local function units(player)
    local count=0;for u in player:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_GUERRILLERO then count=count+1 end end;return count
end
function LekmodScenario.snapshot(player)
    local policies,rewards={},{}
    for p in GameInfo.Policies() do if player:HasPolicy(p.ID) then policies[p.ID]=true end end
    for u in player:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_GUERRILLERO then rewards[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY()} end end
    return {turn=Game.GetGameTurn(),ideology=player:GetLateGamePolicyTree(),policies=policies,culture=player:GetJONSCulture(),free_policies=player:GetNumFreePolicies(),free_tenets=player:GetNumFreeTenets(),reward_units=rewards,reward_building=player:GetCapitalCity():GetNumRealBuilding(GameInfoTypes.BUILDING_CUBA_TRAIT_UB3),anarchy=player:GetAnarchyNumTurns(),opinion_unhappiness=player:GetPublicOpinionUnhappiness()}
end
local function choose(player,cancel)
    policy=nil
    for p in GameInfo.Policies() do if p.PolicyBranchType=="POLICY_BRANCH_FREEDOM" and p.Level==1 and not player:HasPolicy(p.ID) then
        if not player:CanAdoptPolicy(p.ID) and player:GetNumFreePolicies()+player:GetNumFreeTenets()==0 then
            local amount=math.max(0,player:GetNextPolicyCost()-player:GetJONSCulture());player:ChangeJONSCulture(amount)
            LekmodScenarioEvent("fixture-setup",{operation="provided-culture",added=amount})
        end
        if player:CanAdoptPolicy(p.ID) then policy=p.ID;break end
    end end
    assert(policy,"no eligible level-one tenet")
    culture=player:GetJONSCulture();free=player:GetNumFreePolicies()+player:GetNumFreeTenets();cost=player:GetNextPolicyCost();reply=nil
    LuaEvents.LekmodChooseTestTenet(policy,cancel)
end
local function verifySpend(player)
    if free>0 then assert(player:GetNumFreePolicies()+player:GetNumFreeTenets()==free-1 and player:GetJONSCulture()==culture,"free tenet spending mismatch")
    else assert(player:GetJONSCulture()==culture-cost,"paid tenet culture cost mismatch") end
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_CUBA,"choose Cuba")
    local city=player:GetCapitalCity();if not city then return "turn" end
    if phase=="init" then
        assert(player:GetLateGamePolicyTree()==-1,"start without an already selected ideology")
        assert(not player:HasPolicy(GameInfoTypes.POLICY_DUMMY_CUBA) and city:GetNumRealBuilding(GameInfoTypes.BUILDING_CUBA_TRAIT_UB3)==0,"Cuba reward already triggered")
        started=Game.GetGameTurn();unitsBefore=units(player);phase="waiting"
    elseif phase=="waiting" then
        assert(player:GetLateGamePolicyTree()==-1,"driver selected ideology outside the required popup")
        if player:GetEndTurnBlockingType()~=EndTurnBlockingTypes.ENDTURN_BLOCKING_CHOOSE_IDEOLOGY then
            assert(Game.GetGameTurn()-started<=3,"ideology prompt did not become available");return "turn"
        end
        LuaEvents.LekmodChooseTestIdeology(ideology);UI.ActivateNotification(player:GetEndTurnBlockingNotificationIndex());phase="selected"
    elseif phase=="selected" then
        if not chosen then return false end
        if not LekmodScenarioAwait("ideology-selected",player:GetLateGamePolicyTree()==ideology) then return false end
        assert(units(player)==unitsBefore,"selecting ideology prematurely awarded the first-tenet units")
        LekmodScenarioRecord("ideology-selected","PASS","path=actual-ideology-popup-confirmation")
        local rejected=false
        for p in GameInfo.Policies() do if p.PolicyBranchType=="POLICY_BRANCH_FREEDOM" and p.Level==2 then
            assert(not player:CanAdoptPolicy(p.ID),"level-two tenet allowed without prerequisites");rejected=true;break
        end end
        assert(rejected,"no level-two restriction case")
        choose(player,true);phase="first"
    elseif phase=="first" then
        if not reply then return false end
        assert(reply==policy and adopted[policy] and player:HasPolicy(policy),"real first policy adoption event missing")
        if not LekmodScenarioAwait("Cuba-two-units",units(player)==unitsBefore+2) then return false end
        verifySpend(player);first=policy
        assert(player:HasPolicy(GameInfoTypes.POLICY_DUMMY_CUBA) and city:GetNumRealBuilding(GameInfoTypes.BUILDING_CUBA_TRAIT_UB3)==1,"Cuba unlock/reward marker missing")
        assert(not player:CanAdoptPolicy(first),"duplicate tenet is still eligible")
        LekmodScenarioRecord("cuba-first-tenet-reward","PASS","path=real-adoption-event units-added=2")
        choose(player,false);phase="second"
    elseif phase=="second" then
        if not reply then return false end
        assert(reply==policy and policy~=first and adopted[policy] and player:HasPolicy(policy),"second tenet not applied")
        verifySpend(player)
        assert(units(player)==unitsBefore+2 and city:GetNumRealBuilding(GameInfoTypes.BUILDING_CUBA_TRAIT_UB3)==1,"later tenet repeated Cuba's reward")
        assert(player:GetPublicOpinionUnhappiness()==0,"content-revolution rejection case was not available")
        LekmodScenarioRecord("cuba-later-tenet-no-repeat","PASS","two-distinct-level-one-tenets total-reward=2")
        LekmodScenarioRecord("tenet-restrictions","PASS","level-two-without-prerequisites-and-duplicate=rejected content-revolution=disabled")
        return true
    end
    return false
end
