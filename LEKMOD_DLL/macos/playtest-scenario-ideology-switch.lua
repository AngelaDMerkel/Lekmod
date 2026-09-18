LekmodScenario={name="ideology-switch",items={"revolution-cancel","revolution-confirm","revolution-tenets-culture","revolution-content-rejection"}}
local phase,before,preferred,free,reply="init"
LuaEvents.LekmodRevolutionFinished.Add(function() reply=true end)
local function rewards(player)
    local count=0
    for u in player:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_GUERRILLERO then count=count+1 end end
    return count
end
function LekmodScenario.snapshot(player)
    local policies,branches={},{}
    for p in GameInfo.Policies() do if player:HasPolicy(p.ID) then policies[p.ID]=true end end
    for b in GameInfo.PolicyBranchTypes() do branches[b.ID]=player:IsPolicyBranchUnlocked(b.ID) end
    return {turn=Game.GetGameTurn(),ideology=player:GetLateGamePolicyTree(),culture=player:GetJONSCulture(),free_tenets=player:GetNumFreeTenets(),free_policies=player:GetNumFreePolicies(),policies=policies,branches=branches,anarchy=player:GetAnarchyNumTurns(),unhappiness=player:GetPublicOpinionUnhappiness(),preferred=player:GetPublicOpinionPreferredIdeology(),cuba_units=rewards(player),cuba_reward=player:GetCapitalCity():GetNumRealBuilding(GameInfoTypes.BUILDING_CUBA_TRAIT_UB3)}
end
function LekmodScenario.step(player)
    if phase=="init" then
        assert(player:GetPublicOpinionUnhappiness()>0 and not player:IsAnarchy(),"load the real foreign-pressure fixture")
        preferred=player:GetPublicOpinionPreferredIdeology()
        assert(preferred>=0 and preferred~=player:GetLateGamePolicyTree(),"no distinct preferred ideology")
        player:ChangeJONSCulture(37)
        LekmodScenarioEvent("fixture-setup",{operation="provided-culture-to-check-retention",added=37})
        before=LekmodScenario.snapshot(player)
        free=player:GetNumFreeTenets()+Game.GetNumFreePolicies(preferred)+math.max(0,player:GetNumPoliciesInBranch(before.ideology)-GameDefines.SWITCH_POLICY_BRANCHES_TENETS_LOST)
        LekmodScenarioEvent("revolution-before",{state=before,expected_free_tenets=free,tenets_lost=GameDefines.SWITCH_POLICY_BRANCHES_TENETS_LOST,expected_anarchy=GameDefines.SWITCH_POLICY_BRANCHES_ANARCHY_TURNS})
        LuaEvents.LekmodTestRevolution();phase="result"
    elseif phase=="result" then
        if not reply then return false end
        assert(player:GetLateGamePolicyTree()==preferred and not player:IsPolicyBranchUnlocked(before.ideology),"ideology branch did not switch")
        assert(player:GetAnarchyNumTurns()==GameDefines.SWITCH_POLICY_BRANCHES_ANARCHY_TURNS,"revolution anarchy differs")
        assert(player:GetJONSCulture()==before.culture and player:GetNumFreeTenets()==free and player:GetNumFreePolicies()==before.free_policies,"revolution culture/tenet accounting differs")
        for p in GameInfo.Policies() do if p.PolicyBranchType==GameInfo.PolicyBranchTypes[before.ideology].Type then assert(not player:HasPolicy(p.ID),"old ideology tenet retained") end end
        assert(player:GetPublicOpinionUnhappiness()==0,"matching ideology did not remove public pressure")
        assert(rewards(player)==before.cuba_units and player:GetCapitalCity():GetNumRealBuilding(GameInfoTypes.BUILDING_CUBA_TRAIT_UB3)==before.cuba_reward,"switch repeated Cuba first-tenet reward")
        LekmodScenarioRecord("revolution-confirm","PASS","path=actual-OnChangeIdeologyConfirmYes normal-network-command")
        LekmodScenarioRecord("revolution-tenets-culture","PASS","old-tenets-cleared culture-retained=true free-tenets="..free.." Cuba-reward-not-repeated=true")
        return true
    end
    return false
end
