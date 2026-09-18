-- Load an actual revolution. No anarchy or turn counter is assigned.
LekmodScenario={name="anarchy-expiry",items={"anarchy-yield-restrictions","anarchy-natural-expiry"}}
local initial,deadline,last
function LekmodScenario.snapshot(player)
    local cities={}
    for c in player:Cities() do cities[c:GetID()]={production=c:GetProductionTimes100(),rate=c:GetCurrentProductionDifferenceTimes100(false,false),unit=c:GetProductionUnit(),building=c:GetProductionBuilding()} end
    return {turn=Game.GetGameTurn(),anarchy=player:GetAnarchyNumTurns(),ideology=player:GetLateGamePolicyTree(),culture=player:GetJONSCulture(),gold=player:GetGold(),free_tenets=player:GetNumFreeTenets(),culture_rate=player:GetTotalJONSCulturePerTurn(),science=player:GetScienceTimes100(),gold_rate=player:CalculateGoldRateTimes100(),faith_rate=player:GetTotalFaithPerTurn(),cities=cities}
end
function LekmodScenario.step(player)
    local s=LekmodScenario.snapshot(player)
    if not initial then
        initial=s;assert(s.anarchy==GameDefines.SWITCH_POLICY_BRANCHES_ANARCHY_TURNS and s.anarchy>0,"load the immediate real revolution save")
        deadline=s.turn+s.anarchy
        LekmodScenarioEvent("anarchy-start",s)
    end
    assert(s.ideology==initial.ideology,"ideology changed during anarchy")
    assert(s.anarchy==math.max(0,deadline-s.turn),"anarchy did not decrement once per ordinary turn")
    if last~=s.turn then last=s.turn;LekmodScenarioEvent("anarchy-progress",s) end
    if s.anarchy>0 then
        assert(s.culture_rate==0 and s.science==0 and s.gold_rate==0 and s.faith_rate==0,"anarchy did not suppress player yields")
        for _,c in pairs(s.cities) do assert(c.rate==0,"anarchy did not suppress city production") end
        return "turn"
    end
    assert(s.turn==deadline and not player:IsAnarchy(),"anarchy did not end at its original deadline")
    assert(s.culture_rate>0 and s.science>0,"culture/science rates did not recover after anarchy")
    local production=false;for _,c in pairs(s.cities) do if c.rate>0 then production=true end end
    assert(production,"city production did not recover after anarchy")
    LekmodScenarioRecord("anarchy-yield-restrictions","PASS","player-and-city-rate-queries=zero-during-anarchy restored-after-expiry=true")
    LekmodScenarioRecord("anarchy-natural-expiry","PASS","path=ordinary-turns exact-end="..deadline)
    return true
end
