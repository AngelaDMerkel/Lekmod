-- Healing deltas and units are supplied event stimuli. Only the native event's
-- faith award is under test; this is not ordinary-turn healing/build coverage.
LekmodScenario={name="aksum-heal-domain",items={"church-land-faith","church-sea-exclusion","church-air-exclusion","church-distance-exclusion"}}
local ran=false
local church=GameInfoTypes.IMPROVEMENT_AKSUM
function LekmodScenario.snapshot(player)
    local plots,units={},{}
    for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
        if p:GetImprovementType()==church then plots[i]={owner=p:GetOwner(),pillaged=p:IsImprovementPillaged()} end
    end
    for u in player:Units() do units[u:GetID()]={type=u:GetUnitType(),domain=u:GetDomainType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage()} end
    return {turn=Game.GetGameTurn(),faith=player:GetFaith(),plots=plots,units=units}
end
function LekmodScenario.step(player)
    assert(not Game.IsOption("GAMEOPTION_NO_RELIGION"),"faith award requires religion enabled")
    if not player:GetCapitalCity() then return "turn" end
    assert(not ran);ran=true
    local city,site,water,far
    for c in player:Cities() do if c:IsCoastal(10) then
        for d=0,5 do local p=Map.PlotDirection(c:GetX(),c:GetY(),d)
            if p and p:GetOwner()==player:GetID() and not p:IsCity() and not p:IsWater() and not p:IsMountain()
                and p:GetResourceType(-1)==-1 and p:GetImprovementType()==-1 and p:GetNumUnits()==0 then
                for e=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),e)
                    if q and q:IsWater() and not q:IsLake() and q:GetNumUnits()==0 and q:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then city,site,water=c,p,q;break end
                end
            end
            if site then break end
        end
    end;if site then break end end
    assert(site,"load a fixture with an eligible coastal church/air-base pair")
    site:SetImprovementType(church)
    LekmodScenarioEvent("fixture-setup",{operation="provided-church-for-heal-event-input",plot=site:GetPlotIndex(),city=city:GetID(),water=water:GetPlotIndex()})
    for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
        if (p:GetOwner()==player:GetID() or p:GetOwner()==-1) and not p:IsWater() and not p:IsMountain() and p:GetNumUnits()==0
            and Map.PlotDistance(p:GetX(),p:GetY(),site:GetX(),site:GetY())>=3 then far=p;break end
    end
    assert(far,"no land distance control")
    local cases={
        {name="church-land-faith",kind="UNIT_WARRIOR",plot=site,expected=2},
        {name="church-sea-exclusion",kind="UNIT_TRIREME",plot=water,expected=0},
        {name="church-air-exclusion",kind="UNIT_FIGHTER",plot=city:Plot(),expected=0},
        {name="church-distance-exclusion",kind="UNIT_WARRIOR",plot=far,expected=0}}
    for _,case in ipairs(cases) do
        local p=case.plot;local u=assert(player:InitUnit(GameInfoTypes[case.kind],p:GetX(),p:GetY()))
        u:SetDamage(40)
        assert(u:IsNearImprovementType(church,1,false)==(case.plot~=far),"nearby-improvement fixture does not match")
        local before=player:GetFaith()
        LekmodScenarioEvent("fixture-setup",{operation="provided-unit-and-native-heal-stimulus",unit=u:GetID(),kind=case.kind,domain=u:GetDomainType(),damage_before=40,healing_delta=-10,ordinary_turn_healing=false})
        u:ChangeDamage(-10)
        assert(u:GetDamage()==30,"provided native healing delta did not apply")
        local delta=player:GetFaith()-before
        LekmodScenarioEvent("church-heal-outcome",{case=case.name,faith_delta=delta,expected=case.expected})
        LekmodScenarioRecord(case.name,delta==case.expected and "PASS" or "FAIL","native-UnitHealed-event faith-delta="..delta.." expected="..case.expected)
    end
    return true
end
